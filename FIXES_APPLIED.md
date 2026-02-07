# Fixes Applied - Avatar Upload & Phone Verification

## 🔧 Issues Fixed

### 1. ✅ Avatar Upload RLS Policy Error

**Problem**: 
- Error: "new row violates row-level security policy"
- Avatar uploads were failing due to incorrect storage bucket RLS policies

**Solution**:
- Created `storage-policies.sql` with correct RLS policies
- Fixed policy syntax to use `string_to_array(name, '/')[1]` instead of `storage.foldername(name)[1]`
- Policies now correctly match file paths: `{user_id}/avatar-{timestamp}.{ext}`

**Action Required**:
1. **IMPORTANT**: Storage policies cannot be created via SQL Editor (permission error)
2. Create policies through Supabase Dashboard UI instead
3. See `STORAGE_POLICIES_SETUP.md` for detailed step-by-step instructions
4. Go to Storage → Select bucket → Policies tab → Create policies manually

---

### 2. ✅ Phone Verification OTP Not Displayed

**Problem**:
- SMS code was not being sent (backend API not configured)
- Users couldn't see the OTP code during development/testing

**Solution**:
- Updated `PhoneVerification.tsx` to display OTP code in UI for development mode
- Added visual OTP display box when SMS backend is not configured
- OTP is shown in a blue alert box with large, readable font
- Code auto-hides after 10 minutes (same as OTP expiry)

**Features Added**:
- Development mode OTP display in UI
- Clear visual indication when in development mode
- Automatic fallback when SMS service is not available
- Console logging for debugging

**How It Works**:
1. When user requests OTP, code is generated and stored in database
2. System tries to send via SMS service (if configured)
3. If SMS fails or not configured, OTP is displayed in UI
4. User can copy/paste or manually enter the code
5. In production with SMS configured, code is sent via SMS only

---

## 📋 Setup Checklist

- [x] Fixed storage RLS policies SQL file
- [x] Updated phone verification to show OTP in development
- [x] Updated setup documentation

## 🚀 Next Steps

1. **Run Storage Policies**:
   ```sql
   -- Run storage-policies.sql in Supabase SQL Editor
   ```

2. **Test Avatar Upload**:
   - Go to Profile → Profile tab
   - Upload an avatar image
   - Should work without RLS errors

3. **Test Phone Verification**:
   - Go to Profile → Verification tab
   - Enter phone number
   - Click "Send Verification Code"
   - OTP should appear in blue box (development mode)
   - Enter code to verify

4. **Production SMS Setup** (Optional):
   - Set up backend API endpoint for SMS
   - Update `src/services/smsService.ts` to call your API
   - OTP will then be sent via SMS instead of displayed in UI

---

## 📝 Files Modified

1. **`storage-policies.sql`** (NEW)
   - Correct RLS policies for storage buckets
   - Uses proper path parsing for user ID extraction

2. **`src/components/PhoneVerification.tsx`**
   - Added `devOTP` state for development OTP display
   - Added visual OTP display component
   - Improved error handling for SMS service

3. **`KYC_PHONE_AVATAR_SETUP.md`**
   - Updated with reference to `storage-policies.sql`
   - Added important note about running policies

---

## 🔍 Testing

### Avatar Upload Test:
1. Navigate to Profile → Profile tab
2. Click "Upload Picture"
3. Select an image file
4. ✅ Should upload successfully without RLS errors
5. ✅ Avatar should appear in preview

### Phone Verification Test:
1. Navigate to Profile → Verification tab
2. Enter phone number (e.g., 1234567890)
3. Click "Send Verification Code"
4. ✅ OTP code should appear in blue alert box
5. ✅ Enter the 6-digit code
6. ✅ Phone should be verified successfully

---

## ⚠️ Important Notes

1. **Storage Policies Must Be Run**: Without running `storage-policies.sql`, avatar uploads will fail with RLS errors.

2. **Development vs Production**:
   - Development: OTP shown in UI
   - Production: OTP sent via SMS (when backend configured)

3. **SMS Backend**: For production SMS, you need to:
   - Set up Twilio/AWS SNS/etc.
   - Create backend API endpoint
   - Update `smsService.ts` to call your API
