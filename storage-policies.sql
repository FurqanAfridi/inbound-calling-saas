-- ============================================
-- Storage Bucket RLS Policies
-- ============================================
-- Run this in your Supabase SQL Editor AFTER creating the storage buckets
-- Make sure RLS is enabled on storage.objects

-- Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ============================================
-- AVATAR STORAGE POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Avatars are publicly readable" ON storage.objects;

-- Users can upload their own avatars
-- Path format: {user_id}/avatar-{timestamp}.{ext}
CREATE POLICY "Users can upload their own avatars"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );

-- Users can update their own avatars
CREATE POLICY "Users can update their own avatars"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    )
    WITH CHECK (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );

-- Users can delete their own avatars
CREATE POLICY "Users can delete their own avatars"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );

-- Avatars are publicly readable
CREATE POLICY "Avatars are publicly readable"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- ============================================
-- KYC DOCUMENTS STORAGE POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own KYC documents" ON storage.objects;

-- Users can upload their own KYC documents
-- Path format: {user_id}/{folder}/{timestamp}.{ext}
CREATE POLICY "Users can upload their own KYC documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'kyc-documents' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );

-- Users can view their own KYC documents
CREATE POLICY "Users can view their own KYC documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'kyc-documents' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );

-- Users can update their own KYC documents
CREATE POLICY "Users can update their own KYC documents"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'kyc-documents' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    )
    WITH CHECK (
        bucket_id = 'kyc-documents' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );

-- Users can delete their own KYC documents
CREATE POLICY "Users can delete their own KYC documents"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'kyc-documents' 
        AND auth.uid()::text = (string_to_array(name, '/'))[1]
    );
