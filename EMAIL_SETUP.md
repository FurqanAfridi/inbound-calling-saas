# SendGrid Email Integration Setup

This guide explains how to set up SendGrid email functionality for the DNAi authentication app.

## 📧 Environment Variables

Add these to your `.env.local` (development) or `.env.production` (production):

```env
REACT_APP_SENDGRID_ID=your_sendgrid_id
REACT_APP_SENDGRID_API_KEY=your_sendgrid_api_key_here
REACT_APP_ADMIN_EMAIL=no-reply@yourdomain.com
REACT_APP_SUPPORT_SENDER_EMAIL=support@yourdomain.com
REACT_APP_MAIL_API_KEY=your_mail_api_key_here
```

## ⚠️ Security Warning

**IMPORTANT:** Never expose your SendGrid API key in client-side code!

The current implementation in `src/services/emailService.ts` is a placeholder. You **MUST** implement a backend API endpoint to send emails securely.

## 🔧 Backend Implementation Options

### Option 1: Serverless Function (Recommended)

#### For Vercel:
1. Create `api/send-email.js` in your project root
2. Install SendGrid package: `npm install @sendgrid/mail`
3. Deploy to Vercel - it will automatically create the API route

#### For Netlify:
1. Create `netlify/functions/send-email.js`
2. Install SendGrid package: `npm install @sendgrid/mail`
3. Deploy to Netlify

### Option 2: Express.js Backend

1. Create a separate backend server
2. Install dependencies:
   ```bash
   npm install express @sendgrid/mail cors dotenv
   ```
3. Create an endpoint at `/api/send-email`
4. Use the code from `api/send-email.js` as a reference

### Option 3: Supabase Edge Function

1. Create a Supabase Edge Function
2. Use SendGrid API directly in the function
3. Call the function from your React app

## 📝 Update Email Service

Once you have a backend endpoint, update `src/services/emailService.ts`:

```typescript
async sendEmail(options: EmailOptions): Promise<SendGridResponse> {
  try {
    const response = await fetch('/api/send-email', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        to: options.to,
        subject: options.subject,
        html: options.html,
        text: options.text,
        from: options.from || this.fromEmail,
      }),
    });

    const data = await response.json();
    return data;
  } catch (error: any) {
    return {
      success: false,
      error: error.message || 'Failed to send email',
    };
  }
}
```

## 🚀 Usage in Components

The email service is already integrated in:

1. **SignUp Component** - Sends OTP for email verification
2. **ResetPassword Component** - Sends password reset OTP
3. **SetNewPassword Component** - Sends password changed notification

### Example Usage:

```typescript
import { emailService } from '../services/emailService';

// Send OTP email
await emailService.sendOTPEmail(
  'user@example.com',
  '123456',
  'email_verification'
);

// Send welcome email
await emailService.sendWelcomeEmail('user@example.com', 'John');

// Send password changed notification
await emailService.sendPasswordChangedEmail('user@example.com');
```

## 📋 Email Templates

The service includes pre-built HTML email templates for:

- ✅ OTP Verification (email verification & password reset)
- ✅ Password Changed Notification
- ✅ Welcome Email

All templates are responsive and include:
- DNAi branding
- Professional styling
- Support contact information
- Security tips where applicable

## 🔐 Security Best Practices

1. **Never commit API keys** - Use environment variables
2. **Use backend endpoints** - Never call SendGrid API directly from client
3. **Validate email addresses** - Check format before sending
4. **Rate limiting** - Implement rate limiting on your backend
5. **Error handling** - Log errors but don't expose sensitive info

## 🧪 Testing

### Test Email Sending:

1. Set up your backend endpoint
2. Update the email service to use your endpoint
3. Test with a real email address
4. Check SendGrid dashboard for delivery status

### Test Locally:

```bash
# Set environment variables
export REACT_APP_SENDGRID_API_KEY=your_key
export REACT_APP_ADMIN_EMAIL=no-reply@duhanashrah.ai

# Start your backend server
npm run dev

# Test email sending
```

## 📊 SendGrid Dashboard

Monitor your emails in the SendGrid dashboard:
- Email activity
- Delivery rates
- Bounce rates
- Spam reports
- API usage

## 🆘 Troubleshooting

### Emails not sending:
1. Check API key is correct
2. Verify sender email is verified in SendGrid
3. Check backend endpoint is working
4. Review SendGrid activity logs

### CORS errors:
- Ensure your backend allows requests from your frontend domain
- Add proper CORS headers

### Rate limits:
- SendGrid free tier: 100 emails/day
- Upgrade plan if needed
- Implement queuing for high volume

## 📚 Resources

- [SendGrid Documentation](https://docs.sendgrid.com/)
- [SendGrid Node.js Library](https://github.com/sendgrid/sendgrid-nodejs)
- [Email Best Practices](https://docs.sendgrid.com/for-developers/sending-email/best-practices)
