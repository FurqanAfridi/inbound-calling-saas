-- Function to check if a user exists by email
-- This function is used by the SignIn component to provide specific error messages
-- Run this in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION check_user_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user exists in auth.users table
  -- Returns true if user exists, false otherwise
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE email = LOWER(TRIM(p_email))
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_user_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_exists(TEXT) TO anon;
