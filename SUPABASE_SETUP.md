# Supabase Setup Guide for DNAi Auth App

This guide will help you set up Supabase for your authentication system with all the required features.

## 📋 Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. A new Supabase project created

## 🔧 Step 1: Get Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy the following values:
   - **Project URL** → `REACT_APP_SUPABASE_URL`
   - **anon/public key** → `REACT_APP_SUPABASE_ANON_KEY`
   - **service_role key** → `REACT_APP_SUPABASE_SERVICE_ROLE_KEY` (⚠️ Keep this secret!)

## 🔐 Step 2: Configure Environment Variables

1. Open `.env.production` file
2. Replace the placeholder values with your actual Supabase credentials:

```env
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your_anon_key_here
REACT_APP_SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

3. For local development, create `.env.local` with the same variables

## 🗄️ Step 3: Create Database Tables

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy and paste the entire contents of `supabase-schema.sql`
4. Click **Run** (or press Ctrl+Enter)
5. Verify all tables were created successfully by checking **Table Editor**

## 📊 Step 4: Verify Tables Created

You should see these tables in your **Table Editor**:

- ✅ `user_profiles` - Extended user information
- ✅ `user_2fa` - Two-factor authentication settings
- ✅ `login_activity` - Login sessions and activity tracking
- ✅ `password_history` - Password change history
- ✅ `email_verification_tokens` - OTP tokens for email verification
- ✅ `notifications` - System and security notifications
- ✅ `account_deactivation_requests` - Account deletion requests
- ✅ `security_events` - Security audit log

## 🔒 Step 5: Configure Supabase Auth Settings

### Email Templates

1. Go to **Authentication** → **Email Templates**
2. Customize these templates:
   - **Confirm signup** - Email verification
   - **Magic Link** - Passwordless login
   - **Change Email Address** - Email change confirmation
   - **Reset Password** - Password reset

### Auth Providers

1. Go to **Authentication** → **Providers**
2. Enable and configure:
   - **Email** (enabled by default)
   - **Google** - Add OAuth credentials
   - **Apple** - Add OAuth credentials
   - **Facebook** - Add OAuth credentials

### Auth Settings

1. Go to **Authentication** → **Settings**
2. Configure:
   - **Enable email confirmations** - ✅ Enabled
   - **Enable email change confirmations** - ✅ Enabled
   - **Enable password reset** - ✅ Enabled
   - **Session timeout** - Set to your preference (default: 1 hour)

## 🔐 Step 6: Row Level Security (RLS)

RLS policies are automatically created by the schema. Verify they're active:

1. Go to **Table Editor**
2. Select any table
3. Check that **RLS** is enabled (should show a lock icon)

## 📧 Step 7: Configure Email (Optional)

If you want to use custom SMTP instead of Supabase's default:

1. Go to **Settings** → **Auth**
2. Scroll to **SMTP Settings**
3. Configure your SMTP provider:
   - Gmail, SendGrid, Mailgun, etc.
4. Update `.env.production` with SMTP credentials

## 🧪 Step 8: Test the Setup

### Test User Registration

1. Use Supabase Auth API to create a test user
2. Check `user_profiles` table - should auto-create profile
3. Check `notifications` table - should create welcome notification

### Test Email Verification

1. Request email verification
2. Check `email_verification_tokens` table for token
3. Verify email using the token

## 📝 Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `REACT_APP_SUPABASE_URL` | Your Supabase project URL | `https://xxx.supabase.co` |
| `REACT_APP_SUPABASE_ANON_KEY` | Public anon key | `eyJhbGc...` |
| `REACT_APP_SUPABASE_SERVICE_ROLE_KEY` | Service role key (server-side only) | `eyJhbGc...` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REACT_APP_APP_NAME` | Application name | `DNAi` |
| `REACT_APP_APP_URL` | Application URL | - |
| `REACT_APP_SESSION_TIMEOUT` | Session timeout in ms | `3600000` (1 hour) |
| `REACT_APP_2FA_ISSUER` | 2FA issuer name | `DNAi` |
| `REACT_APP_ENABLE_2FA` | Enable 2FA feature | `true` |
| `REACT_APP_ENABLE_SOCIAL_LOGIN` | Enable social login | `true` |
| `REACT_APP_ENABLE_EMAIL_NOTIFICATIONS` | Enable email notifications | `true` |

## 🔍 Table Schema Overview

### Core Tables

1. **user_profiles** - Extends auth.users with profile data
2. **user_2fa** - Stores 2FA settings and secrets
3. **login_activity** - Tracks all login sessions
4. **notifications** - System notifications for users

### Security Tables

5. **password_history** - Prevents password reuse
6. **email_verification_tokens** - OTP management
7. **security_events** - Security audit log
8. **account_deactivation_requests** - Account deletion tracking

## 🚀 Next Steps

1. Install Supabase client library:
   ```bash
   npm install @supabase/supabase-js
   ```

2. Create Supabase client utility:
   ```typescript
   // src/lib/supabase.ts
   import { createClient } from '@supabase/supabase-js'
   
   const supabaseUrl = process.env.REACT_APP_SUPABASE_URL!
   const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY!
   
   export const supabase = createClient(supabaseUrl, supabaseAnonKey)
   ```

3. Start implementing auth features using the Supabase client

## ⚠️ Security Notes

- **Never commit** `.env.production` or `.env.local` to version control
- **Never expose** `REACT_APP_SUPABASE_SERVICE_ROLE_KEY` in client-side code
- Use **service role key** only in server-side code or edge functions
- Enable **Row Level Security (RLS)** on all tables (already done in schema)
- Regularly review **security_events** table for suspicious activity

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)

## 🆘 Troubleshooting

### Tables not created
- Check SQL Editor for error messages
- Ensure you have proper permissions
- Verify UUID extension is enabled

### RLS policies not working
- Check that RLS is enabled on tables
- Verify policies are created correctly
- Test with authenticated user

### Email not sending
- Check Supabase Auth email settings
- Verify SMTP configuration (if using custom)
- Check spam folder

### Service role key issues
- Never use service role key in client-side code
- Use it only in server-side functions or edge functions
- Create separate API endpoints for admin operations
