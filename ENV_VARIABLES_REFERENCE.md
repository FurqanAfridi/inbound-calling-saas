# Environment Variables Reference

## Required Variables for Supabase

Copy these to your `.env.production` file (or `.env.local` for development):

```env
# Supabase Configuration (REQUIRED)
REACT_APP_SUPABASE_URL=your_supabase_project_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
REACT_APP_SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

### Where to Find These Values:

1. **REACT_APP_SUPABASE_URL**
   - Location: Supabase Dashboard → Settings → API → Project URL
   - Format: `https://xxxxxxxxxxxxx.supabase.co`

2. **REACT_APP_SUPABASE_ANON_KEY**
   - Location: Supabase Dashboard → Settings → API → Project API keys → `anon` `public`
   - Format: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - ⚠️ Safe to use in client-side code

3. **REACT_APP_SUPABASE_SERVICE_ROLE_KEY**
   - Location: Supabase Dashboard → Settings → API → Project API keys → `service_role` `secret`
   - Format: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - ⚠️ **NEVER expose in client-side code** - Use only in server-side/backend

## Optional Configuration Variables

```env
# Application Settings
REACT_APP_APP_NAME=DNAi
REACT_APP_APP_URL=https://your-production-domain.com

# Email Settings (if using custom SMTP)
REACT_APP_SMTP_HOST=smtp.gmail.com
REACT_APP_SMTP_PORT=587
REACT_APP_SMTP_USER=your_email@gmail.com
REACT_APP_SMTP_PASSWORD=your_app_password

# Security Settings
REACT_APP_SESSION_TIMEOUT=3600000  # 1 hour in milliseconds
REACT_APP_2FA_ISSUER=DNAi          # Name shown in 2FA apps

# Feature Flags
REACT_APP_ENABLE_2FA=true
REACT_APP_ENABLE_SOCIAL_LOGIN=true
REACT_APP_ENABLE_EMAIL_NOTIFICATIONS=true
```

## Quick Setup Steps

1. Copy `env.production.template` to `.env.production`
2. Copy `env.local.template` to `.env.local` (for development)
3. Replace placeholder values with your actual Supabase credentials
4. Run the SQL schema from `supabase-schema.sql` in Supabase SQL Editor

## Security Best Practices

- ✅ Add `.env.production` and `.env.local` to `.gitignore` (already done)
- ✅ Never commit environment files with real credentials
- ✅ Use `.env.example` or `.template` files for version control
- ✅ Rotate keys if accidentally exposed
- ✅ Use different keys for development and production
