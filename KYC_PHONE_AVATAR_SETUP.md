# KYC Verification, Phone Verification & Avatar Upload Setup Guide

This guide will help you set up the three new features: KYC Verification, Phone Number Verification, and Avatar Upload.

## 📋 Prerequisites

1. Supabase project with the main schema already set up
2. Supabase Storage buckets created (see below)
3. Backend API endpoint for SMS sending (for phone verification)

## 🗄️ Step 1: Run Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy and paste the entire contents of `kyc-phone-avatar-schema.sql`
4. Click **Run** (or press Ctrl+Enter)
5. Verify tables were created:
   - ✅ `kyc_verifications`
   - ✅ `phone_verification_tokens`

## 📦 Step 2: Create Storage Buckets

### Avatar Storage Bucket

1. Go to **Storage** in your Supabase dashboard
2. Click **New Bucket**
3. Configure:
   - **Name**: `avatars`
   - **Public**: ✅ Yes (for public avatar access)
   - **File size limit**: 5MB
   - **Allowed MIME types**: `image/jpeg,image/jpg,image/png,image/webp,image/gif`
4. Click **Create Bucket**

### KYC Documents Storage Bucket

1. Click **New Bucket** again
2. Configure:
   - **Name**: `kyc-documents`
   - **Public**: ❌ No (private, for security)
   - **File size limit**: 5MB
   - **Allowed MIME types**: `image/jpeg,image/jpg,image/png,image/webp,application/pdf`
3. Click **Create Bucket**

### Storage Policies

**IMPORTANT**: Storage policies cannot be created via SQL Editor due to permission restrictions. You must create them through the Supabase Dashboard UI.

**⚠️ See `STORAGE_POLICIES_SETUP.md` for detailed step-by-step instructions.**

**Quick Steps**:
1. Go to **Storage** → Select bucket (`avatars` or `kyc-documents`)
2. Click **Policies** tab
3. Click **New Policy** for each operation (INSERT, SELECT, UPDATE, DELETE)
4. Use the policy definitions from `STORAGE_POLICIES_SETUP.md`

**Why**: The `storage.objects` table is a system table and requires owner privileges to modify via SQL. The Dashboard UI handles this automatically.

**Policy Format**: `(bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])`

## 📱 Step 3: Set Up SMS Service (Phone Verification)

Phone verification requires a backend API endpoint to send SMS messages. You'll need to integrate with a service like:

- **Twilio** (Recommended)
- **AWS SNS**
- **Vonage (Nexmo)**
- **MessageBird**

### Backend API Endpoint Example

Create a backend endpoint (e.g., `/api/send-sms-otp`) that:

1. Receives phone number and OTP code
2. Sends SMS via your chosen provider
3. Returns success/error response

**Example using Twilio (Node.js/Express):**

```javascript
// Backend: /api/send-sms-otp
const twilio = require('twilio');
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

app.post('/api/send-sms-otp', async (req, res) => {
  const { phoneNumber, otp } = req.body;
  
  try {
    await client.messages.create({
      body: `Your DNAi verification code is: ${otp}. This code will expire in 10 minutes.`,
      to: phoneNumber,
      from: process.env.TWILIO_PHONE_NUMBER
    });
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

### Update Frontend SMS Service

Update `src/services/smsService.ts` to call your backend API:

```typescript
async sendSMS(options: SMSOptions): Promise<SMSResponse> {
  const response = await fetch('/api/send-sms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      to: options.to,
      message: options.message
    })
  });
  return await response.json();
}
```

## ✅ Step 4: Verify Implementation

### Avatar Upload
1. Go to **Profile** → **Profile** tab
2. Click **Upload Picture**
3. Select an image (JPG, PNG, WebP, or GIF, max 5MB)
4. Verify the avatar appears and is saved

### Phone Verification
1. Go to **Profile** → **Verification** tab
2. Enter your phone number
3. Click **Send Verification Code**
4. Enter the 6-digit code (check console for development OTP)
5. Verify phone status updates to "Verified"

### KYC Verification
1. Go to **Profile** → **Verification** tab
2. Select document type
3. Upload document front, back (if required), and selfie
4. Click **Submit for Verification**
5. Verify status shows "Pending" or "Under Review"

## 🔒 Security Notes

1. **KYC Documents**: Stored privately in `kyc-documents` bucket. Only the user and admins can access.
2. **Phone OTP**: Tokens are hashed in production (currently stored as plain text for development).
3. **Avatar**: Publicly accessible for profile display.
4. **File Validation**: All uploads are validated for type and size on both client and server.

## 🐛 Troubleshooting

### Storage Bucket Errors
- **Error**: "Bucket not found"
  - **Solution**: Create the storage buckets as described in Step 2

### SMS Not Sending
- **Error**: SMS not received
  - **Solution**: 
    1. Check backend API endpoint is configured
    2. Verify SMS service credentials (Twilio, etc.)
    3. Check phone number format (include country code)
    4. For development, check browser console for OTP code

### KYC Upload Fails
- **Error**: "Upload failed"
  - **Solution**:
    1. Verify `kyc-documents` bucket exists
    2. Check file size (must be < 5MB)
    3. Verify file type is allowed
    4. Check storage policies are set correctly

## 📝 Next Steps

1. **Admin Panel**: Create admin interface to review and approve/reject KYC submissions
2. **SMS Integration**: Complete backend SMS service integration
3. **Email Notifications**: Add email notifications for KYC status changes
4. **Image Optimization**: Add image compression/resizing before upload
5. **Document OCR**: Consider adding OCR for automatic document verification
