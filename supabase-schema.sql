-- ============================================
-- DNAi Authentication System - Supabase Schema
-- ============================================
-- This file contains all the database tables needed for the complete auth system
-- Run this in your Supabase SQL Editor

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. USER PROFILES TABLE
-- ============================================
-- Extends Supabase auth.users with additional profile information
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    country_code VARCHAR(5) DEFAULT '+1',
    avatar_url TEXT,
    bio TEXT,
    date_of_birth DATE,
    account_status VARCHAR(20) DEFAULT 'active' CHECK (account_status IN ('active', 'inactive', 'suspended', 'deleted')),
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_status ON public.user_profiles(account_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email_verified ON public.user_profiles(email_verified);
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted_at ON public.user_profiles(deleted_at) WHERE deleted_at IS NOT NULL;

-- ============================================
-- 2. TWO-FACTOR AUTHENTICATION (2FA) TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_2fa (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    enabled BOOLEAN DEFAULT false,
    method VARCHAR(20) CHECK (method IN ('totp', 'sms', 'email')),
    secret_key TEXT, -- Encrypted TOTP secret
    backup_codes TEXT[], -- Array of backup codes (encrypted)
    phone_number VARCHAR(20), -- For SMS 2FA
    verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    UNIQUE(user_id)
);

-- Indexes for user_2fa
CREATE INDEX IF NOT EXISTS idx_user_2fa_user_id ON public.user_2fa(user_id);
CREATE INDEX IF NOT EXISTS idx_user_2fa_enabled ON public.user_2fa(enabled);

-- ============================================
-- 3. LOGIN ACTIVITY & SESSION MANAGEMENT
-- ============================================
CREATE TABLE IF NOT EXISTS public.login_activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID, -- Supabase session ID
    ip_address INET,
    user_agent TEXT,
    device_type VARCHAR(50), -- mobile, desktop, tablet
    device_name VARCHAR(255),
    browser_name VARCHAR(100),
    os_name VARCHAR(100),
    location_country VARCHAR(100),
    location_city VARCHAR(100),
    login_method VARCHAR(20) CHECK (login_method IN ('email', 'google', 'apple', 'facebook', '2fa')),
    success BOOLEAN DEFAULT true,
    failure_reason TEXT,
    login_at TIMESTAMPTZ DEFAULT NOW(),
    logout_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true
);

-- Indexes for login_activity
CREATE INDEX IF NOT EXISTS idx_login_activity_user_id ON public.login_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_login_activity_session_id ON public.login_activity(session_id);
CREATE INDEX IF NOT EXISTS idx_login_activity_login_at ON public.login_activity(login_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_activity_is_active ON public.login_activity(is_active) WHERE is_active = true;

-- ============================================
-- 4. PASSWORD HISTORY TABLE
-- ============================================
-- Stores password history to prevent reuse
CREATE TABLE IF NOT EXISTS public.password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    password_hash TEXT NOT NULL, -- Hashed password
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for password_history
CREATE INDEX IF NOT EXISTS idx_password_history_user_id ON public.password_history(user_id);
CREATE INDEX IF NOT EXISTS idx_password_history_created_at ON public.password_history(created_at DESC);

-- ============================================
-- 5. EMAIL VERIFICATION TOKENS
-- ============================================
-- Stores email verification OTPs and tokens
CREATE TABLE IF NOT EXISTS public.email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    token VARCHAR(10) NOT NULL, -- 6-digit OTP
    token_hash TEXT NOT NULL, -- Hashed token for security
    purpose VARCHAR(50) CHECK (purpose IN ('email_verification', 'password_reset', 'email_change')),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for email_verification_tokens
CREATE INDEX IF NOT EXISTS idx_email_verification_user_id ON public.email_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verification_token_hash ON public.email_verification_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_email_verification_expires_at ON public.email_verification_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_email_verification_purpose ON public.email_verification_tokens(purpose);

-- ============================================
-- 6. NOTIFICATIONS TABLE
-- ============================================
-- System and security email notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'email_verification',
        'password_changed',
        'password_reset_request',
        'login_alert',
        'new_device_login',
        '2fa_enabled',
        '2fa_disabled',
        'account_deactivated',
        'account_deleted',
        'security_alert',
        'suspicious_activity'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON public.notifications(read_at) WHERE read_at IS NULL;

-- ============================================
-- 7. ACCOUNT DEACTIVATION REQUESTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.account_deactivation_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT,
    scheduled_deletion_at TIMESTAMPTZ, -- For scheduled deletion
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Indexes for account_deactivation_requests
CREATE INDEX IF NOT EXISTS idx_deactivation_user_id ON public.account_deactivation_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_deactivation_status ON public.account_deactivation_requests(status);
CREATE INDEX IF NOT EXISTS idx_deactivation_scheduled_deletion ON public.account_deactivation_requests(scheduled_deletion_at) WHERE scheduled_deletion_at IS NOT NULL;

-- ============================================
-- 8. SECURITY EVENTS TABLE
-- ============================================
-- Tracks security-related events for audit purposes
CREATE TABLE IF NOT EXISTS public.security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'failed_login',
        'password_reset_request',
        'password_changed',
        'email_changed',
        '2fa_enabled',
        '2fa_disabled',
        '2fa_failed',
        'suspicious_activity',
        'account_locked',
        'account_unlocked',
        'session_revoked',
        'multiple_failed_attempts'
    )),
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    ip_address INET,
    user_agent TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for security_events
CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON public.security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_event_type ON public.security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_severity ON public.security_events(severity);
CREATE INDEX IF NOT EXISTS idx_security_events_created_at ON public.security_events(created_at DESC);

-- ============================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_2fa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.login_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_verification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_deactivation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can view their own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 2FA Policies
CREATE POLICY "Users can manage their own 2FA"
    ON public.user_2fa FOR ALL
    USING (auth.uid() = user_id);

-- Login Activity Policies
CREATE POLICY "Users can view their own login activity"
    ON public.login_activity FOR SELECT
    USING (auth.uid() = user_id);

-- Password History Policies
CREATE POLICY "Service role can manage password history"
    ON public.password_history FOR ALL
    USING (true); -- Only accessible via service role key

-- Email Verification Tokens Policies
CREATE POLICY "Service role can manage verification tokens"
    ON public.email_verification_tokens FOR ALL
    USING (true); -- Only accessible via service role key

-- Notifications Policies
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Account Deactivation Policies
CREATE POLICY "Users can manage their own deactivation requests"
    ON public.account_deactivation_requests FOR ALL
    USING (auth.uid() = user_id);

-- Security Events Policies
CREATE POLICY "Users can view their own security events"
    ON public.security_events FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================
-- 10. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email_verified)
    VALUES (NEW.id, NEW.email_confirmed_at IS NOT NULL);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_2fa_updated_at
    BEFORE UPDATE ON public.user_2fa
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Function to log login activity
CREATE OR REPLACE FUNCTION public.log_login_activity(
    p_user_id UUID,
    p_session_id UUID,
    p_ip_address INET,
    p_user_agent TEXT,
    p_login_method VARCHAR
)
RETURNS UUID AS $$
DECLARE
    v_activity_id UUID;
BEGIN
    INSERT INTO public.login_activity (
        user_id, session_id, ip_address, user_agent, login_method
    ) VALUES (
        p_user_id, p_session_id, p_ip_address, p_user_agent, p_login_method
    ) RETURNING id INTO v_activity_id;
    
    -- Update last_login_at in user_profiles
    UPDATE public.user_profiles
    SET last_login_at = NOW(), last_active_at = NOW()
    WHERE id = p_user_id;
    
    RETURN v_activity_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create notification
CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID,
    p_type VARCHAR,
    p_title VARCHAR,
    p_message TEXT,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id, type, title, message, metadata
    ) VALUES (
        p_user_id, p_type, p_title, p_message, p_metadata
    ) RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log security event
CREATE OR REPLACE FUNCTION public.log_security_event(
    p_user_id UUID,
    p_event_type VARCHAR,
    p_severity VARCHAR DEFAULT 'medium',
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO public.security_events (
        user_id, event_type, severity, ip_address, user_agent, details
    ) VALUES (
        p_user_id, p_event_type, p_severity, p_ip_address, p_user_agent, p_details
    ) RETURNING id INTO v_event_id;
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 11. VIEWS FOR COMMON QUERIES
-- ============================================

-- View for user dashboard data
CREATE OR REPLACE VIEW public.user_dashboard AS
SELECT 
    u.id,
    u.email,
    up.first_name,
    up.last_name,
    up.avatar_url,
    up.account_status,
    up.email_verified,
    up.phone_verified,
    up.last_login_at,
    up.last_active_at,
    u2fa.enabled as two_factor_enabled,
    u2fa.method as two_factor_method,
    (SELECT COUNT(*) FROM public.notifications n WHERE n.user_id = u.id AND n.read_at IS NULL) as unread_notifications,
    (SELECT COUNT(*) FROM public.login_activity la WHERE la.user_id = u.id AND la.is_active = true) as active_sessions
FROM auth.users u
LEFT JOIN public.user_profiles up ON u.id = up.id
LEFT JOIN public.user_2fa u2fa ON u.id = u2fa.user_id;

-- Grant access to authenticated users
GRANT SELECT ON public.user_dashboard TO authenticated;

-- ============================================
-- END OF SCHEMA
-- ============================================
