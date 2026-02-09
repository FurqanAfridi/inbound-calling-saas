# Supabase Email Configuration Guide

## Problem
Your application is sending **TWO emails** during signup:
1. Supabase's automatic confirmation email (magic link)
2. Your custom OTP email via SendGrid

This causes:
- Email rate limiting errors
- User confusion (receiving confirmation link instead of OTP)
- Duplicate email sends

## Solution
Disable Supabase's automatic email confirmation and use only your custom OTP flow.

---

## ✅ Your End Job: Supabase Dashboard Configuration

### Step 1: Disable Email Confirmations in Supabase

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to Authentication Settings**
   - Click on **"Authentication"** in the left sidebar
   - Click on **"Settings"** (or go to Authentication → Settings)

3. **Disable Email Confirmations**
   - Find the section **"Email Auth"** or **"Email Settings"**
   - Look for **"Enable email confirmations"** toggle
   - **Turn it OFF** (disable it)
   - This will prevent Supabase from automatically sending confirmation emails

4. **Alternative: Configure Email Template (if you can't disable)**
   - Go to **Authentication** → **Email Templates**
   - Find **"Confirm signup"** template
   - You can customize it, but it's better to disable confirmations entirely

### Step 2: Verify Email OTP Settings (Optional)

If you want to use Supabase's built-in OTP instead of custom OTP:

1. Go to **Authentication** → **Settings**
2. Look for **"Email OTP"** or **"OTP Settings"**
3. Enable **"Email OTP"** if you want to use Supabase's OTP system
4. **Note:** We're using custom OTP via SendGrid, so you can leave this disabled

### Step 3: Configure SMTP (Optional - if using custom SMTP)

If you want Supabase to use your SendGrid SMTP:

1. Go to **Settings** → **Auth** → **SMTP Settings**
2. Configure your SendGrid SMTP:
   - **SMTP Host:** `smtp.sendgrid.net`
   - **SMTP Port:** `587` (or `465` for SSL)
   - **SMTP User:** `apikey`
   - **SMTP Password:** Your SendGrid API Key
   - **Sender Email:** Your verified sender email
   - **Sender Name:** DNAi

**Note:** This is optional since we're handling emails via SendGrid API directly.

---

## ✅ What We've Fixed in Code

### 1. SignUp.tsx
- Added `emailRedirectTo: null` to disable Supabase's automatic email confirmation
- Now only your custom OTP email will be sent via SendGrid

### 2. AuthContext.tsx
- Added `emailRedirectTo: null` to the signUp function
- Ensures consistency across the app

### 3. VerifyEmail.tsx
- Updated to refresh session after OTP verification
- Email will be auto-confirmed in Supabase when user signs in

---

## 📋 Summary

### What You Need to Do:
1. ✅ **Disable "Enable email confirmations"** in Supabase Dashboard
   - Location: Authentication → Settings → Email Auth
   - Action: Turn OFF the toggle

### What's Already Done:
- ✅ Code updated to disable automatic email confirmation
- ✅ Custom OTP flow via SendGrid is working
- ✅ Only one email will be sent per signup (your OTP email)

---

## 🧪 Testing

After making the Supabase dashboard changes:

1. **Test Signup:**
   - Sign up a new user
   - You should receive **ONLY ONE email** (OTP from SendGrid)
   - You should **NOT** receive Supabase's confirmation link email

2. **Test Email Rate Limit:**
   - Try signing up multiple times
   - Should not hit rate limits anymore (only one email per signup)

3. **Test OTP Verification:**
   - Enter the OTP code
   - Should successfully verify and navigate to dashboard

---

## ⚠️ Important Notes

1. **Email Confirmation in Supabase:**
   - After disabling email confirmations, Supabase will auto-confirm emails on first login
   - Or you can create a backend endpoint using `service_role` key to manually confirm emails
   - For now, the email is marked as verified in `user_profiles` table

2. **If You Still See Confirmation Emails:**
   - Double-check that "Enable email confirmations" is disabled in Supabase
   - Clear browser cache and test again
   - Check Supabase logs to see if emails are still being sent

3. **Backend Endpoint (Optional):**
   - If you want to manually confirm emails in Supabase after OTP verification
   - Create a backend endpoint that uses Supabase Admin API (`service_role` key)
   - Call `supabase.auth.admin.updateUserById(userId, { email_confirm: true })`

---

## 🔗 Useful Links

- Supabase Auth Settings: https://supabase.com/dashboard/project/_/auth/settings
- Supabase Email Templates: https://supabase.com/dashboard/project/_/auth/templates
- SendGrid API Docs: https://docs.sendgrid.com/api-reference

---

## ✅ Checklist

- [ ] Disabled "Enable email confirmations" in Supabase Dashboard
- [ ] Tested signup - only one email received (OTP)
- [ ] Tested OTP verification - works correctly
- [ ] No more email rate limit errors
- [ ] Users receive OTP instead of confirmation link
