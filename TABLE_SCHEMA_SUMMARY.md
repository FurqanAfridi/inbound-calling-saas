# Database Table Schema Summary

This document provides a quick reference for all tables created in Supabase for the authentication system.

## 📊 Core Tables

### 1. `user_profiles`
**Purpose**: Extends Supabase `auth.users` with additional profile information

**Key Columns**:
- `id` (UUID) - References `auth.users(id)`
- `first_name`, `last_name` - User name
- `phone`, `country_code` - Phone number
- `avatar_url` - Profile picture
- `account_status` - 'active', 'inactive', 'suspended', 'deleted'
- `email_verified`, `phone_verified` - Verification status
- `last_login_at`, `last_active_at` - Activity tracking
- `created_at`, `updated_at`, `deleted_at` - Timestamps

**Used For**: User dashboard, profile management, account status

---

### 2. `user_2fa`
**Purpose**: Stores two-factor authentication settings and secrets

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)`
- `enabled` (BOOLEAN) - Whether 2FA is enabled
- `method` - 'totp', 'sms', or 'email'
- `secret_key` - Encrypted TOTP secret
- `backup_codes` - Array of backup codes
- `phone_number` - For SMS 2FA
- `verified` - Whether 2FA setup is verified

**Used For**: Two-factor authentication feature

---

### 3. `login_activity`
**Purpose**: Tracks all user login sessions and activity

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)`
- `session_id` (UUID) - Supabase session ID
- `ip_address` - Login IP
- `user_agent` - Browser/client info
- `device_type`, `device_name` - Device information
- `browser_name`, `os_name` - Browser/OS details
- `location_country`, `location_city` - Geographic location
- `login_method` - 'email', 'google', 'apple', 'facebook', '2fa'
- `success` - Whether login succeeded
- `login_at`, `logout_at`, `expires_at` - Session timestamps
- `is_active` - Whether session is currently active

**Used For**: Login activity tracking, session management, security monitoring

---

### 4. `password_history`
**Purpose**: Stores password history to prevent password reuse

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)`
- `password_hash` - Hashed previous password
- `created_at` - When password was set

**Used For**: Enforcing password change policies, preventing reuse

---

### 5. `email_verification_tokens`
**Purpose**: Manages OTP tokens for email verification and password reset

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)`
- `email` - Email address being verified
- `token` - 6-digit OTP
- `token_hash` - Hashed token for security
- `purpose` - 'email_verification', 'password_reset', 'email_change'
- `expires_at` - Token expiration
- `used_at` - When token was used
- `attempts`, `max_attempts` - Verification attempt tracking

**Used For**: Email verification, password reset, email change

---

### 6. `notifications`
**Purpose**: System and security email notifications for users

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)`
- `type` - Notification type (see list below)
- `title`, `message` - Notification content
- `email_sent`, `email_sent_at` - Email delivery tracking
- `read_at` - When user read the notification
- `metadata` - Additional JSON data
- `created_at` - When notification was created

**Notification Types**:
- `email_verification`
- `password_changed`
- `password_reset_request`
- `login_alert`
- `new_device_login`
- `2fa_enabled`, `2fa_disabled`
- `account_deactivated`, `account_deleted`
- `security_alert`
- `suspicious_activity`

**Used For**: User notifications, security alerts, system messages

---

### 7. `account_deactivation_requests`
**Purpose**: Tracks account deactivation and deletion requests

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)`
- `reason` - Why account is being deactivated
- `scheduled_deletion_at` - For scheduled deletion
- `status` - 'pending', 'completed', 'cancelled'
- `created_at`, `completed_at` - Timestamps

**Used For**: Account deactivation, self-delete functionality

---

### 8. `security_events`
**Purpose**: Security audit log for all security-related events

**Key Columns**:
- `user_id` (UUID) - References `auth.users(id)` (nullable)
- `event_type` - Type of security event (see list below)
- `severity` - 'low', 'medium', 'high', 'critical'
- `ip_address`, `user_agent` - Event context
- `details` - Additional JSON data
- `created_at` - When event occurred

**Event Types**:
- `failed_login`
- `password_reset_request`
- `password_changed`
- `email_changed`
- `2fa_enabled`, `2fa_disabled`, `2fa_failed`
- `suspicious_activity`
- `account_locked`, `account_unlocked`
- `session_revoked`
- `multiple_failed_attempts`

**Used For**: Security monitoring, audit trails, threat detection

---

## 🔍 Views

### `user_dashboard`
**Purpose**: Aggregated view for user dashboard data

**Includes**:
- User profile information
- 2FA status
- Unread notification count
- Active session count
- Last login information

**Used For**: Quick dashboard data retrieval

---

## 🔒 Security Features

### Row Level Security (RLS)
All tables have RLS enabled with policies that:
- Allow users to view/update only their own data
- Restrict sensitive operations to service role
- Protect password history and tokens from direct access

### Functions
- `handle_new_user()` - Auto-creates profile on signup
- `log_login_activity()` - Logs login events
- `create_notification()` - Creates user notifications
- `log_security_event()` - Logs security events
- `update_updated_at_column()` - Auto-updates timestamps

---

## 📋 Feature Mapping

| Feature | Tables Used |
|---------|------------|
| User Registration | `auth.users`, `user_profiles` |
| Email Verification | `email_verification_tokens`, `user_profiles` |
| Password Reset | `email_verification_tokens`, `password_history` |
| User Dashboard | `user_profiles`, `user_2fa`, `notifications`, `login_activity` |
| Profile Management | `user_profiles` |
| Change Password | `password_history` |
| Logout | `login_activity` |
| 2FA | `user_2fa` |
| Login Activity | `login_activity` |
| Session Management | `login_activity` |
| Account Deactivation | `account_deactivation_requests`, `user_profiles` |
| Email Notifications | `notifications` |
| Security Monitoring | `security_events` |

---

## 🚀 Next Steps

1. Run `supabase-schema.sql` in Supabase SQL Editor
2. Verify all tables are created
3. Check RLS policies are active
4. Test with sample data
5. Integrate with your React app

For detailed setup instructions, see `SUPABASE_SETUP.md`
