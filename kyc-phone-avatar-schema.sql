-- ============================================
-- KYC Verification, Phone Verification, and Avatar Storage Schema
-- ============================================
-- Run this in your Supabase SQL Editor after the main schema

-- ============================================
-- 1. KYC VERIFICATION TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.kyc_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) CHECK (document_type IN ('passport', 'drivers_license', 'national_id', 'other')),
    document_front_url TEXT, -- URL to front of document
    document_back_url TEXT, -- URL to back of document (if applicable)
    selfie_url TEXT, -- Selfie photo for verification
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    rejection_reason TEXT, -- Reason if rejected
    verified_by UUID REFERENCES auth.users(id), -- Admin who verified
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Indexes for kyc_verifications
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_user_id ON public.kyc_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_verifications_status ON public.kyc_verifications(status);

-- ============================================
-- 2. PHONE VERIFICATION TOKENS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.phone_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    country_code VARCHAR(5) NOT NULL,
    token VARCHAR(10) NOT NULL, -- 6-digit OTP
    token_hash TEXT NOT NULL, -- Hashed token for security
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for phone_verification_tokens
CREATE INDEX IF NOT EXISTS idx_phone_verification_user_id ON public.phone_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_phone_verification_token_hash ON public.phone_verification_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_phone_verification_expires_at ON public.phone_verification_tokens(expires_at);

-- ============================================
-- 3. ROW LEVEL SECURITY POLICIES
-- ============================================

-- KYC Verifications Policies
ALTER TABLE public.kyc_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own KYC verification"
    ON public.kyc_verifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own KYC verification"
    ON public.kyc_verifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own KYC verification"
    ON public.kyc_verifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Phone Verification Tokens Policies
ALTER TABLE public.phone_verification_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own phone verification tokens"
    ON public.phone_verification_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own phone verification tokens"
    ON public.phone_verification_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own phone verification tokens"
    ON public.phone_verification_tokens FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 4. FUNCTIONS
-- ============================================

-- Function to update KYC status in user_profiles
CREATE OR REPLACE FUNCTION public.update_kyc_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.user_profiles
    SET metadata = jsonb_set(
        COALESCE(metadata, '{}'::jsonb),
        '{kyc_status}',
        to_jsonb(NEW.status)
    )
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update KYC status
DROP TRIGGER IF EXISTS update_kyc_status_trigger ON public.kyc_verifications;
CREATE TRIGGER update_kyc_status_trigger
    AFTER INSERT OR UPDATE OF status ON public.kyc_verifications
    FOR EACH ROW
    EXECUTE FUNCTION public.update_kyc_status();

-- Function to update phone_verified status
CREATE OR REPLACE FUNCTION public.update_phone_verified_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.used_at IS NOT NULL AND OLD.used_at IS NULL THEN
        UPDATE public.user_profiles
        SET phone_verified = true
        WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update phone_verified
DROP TRIGGER IF EXISTS update_phone_verified_trigger ON public.phone_verification_tokens;
CREATE TRIGGER update_phone_verified_trigger
    AFTER UPDATE OF used_at ON public.phone_verification_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.update_phone_verified_status();

-- ============================================
-- 5. STORAGE BUCKET SETUP (Run in Supabase Dashboard)
-- ============================================
-- Note: Storage buckets must be created via Supabase Dashboard or API
-- Go to Storage → Create Bucket
-- Bucket name: 'avatars'
-- Public: true (for public avatar access)
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp, image/gif

-- Storage policies (run after creating bucket)
-- CREATE POLICY "Users can upload their own avatars"
--     ON storage.objects FOR INSERT
--     WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
--
-- CREATE POLICY "Users can update their own avatars"
--     ON storage.objects FOR UPDATE
--     USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
--
-- CREATE POLICY "Users can delete their own avatars"
--     ON storage.objects FOR DELETE
--     USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
--
-- CREATE POLICY "Avatars are publicly readable"
--     ON storage.objects FOR SELECT
--     USING (bucket_id = 'avatars');
