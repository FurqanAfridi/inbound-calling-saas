# Inbound House DNAI - Production Deployment Guide

## 🚀 Quick Start

This is a production-ready React application for managing AI voice agents, inbound calls, billing, and subscriptions.

## 📋 Prerequisites

- Node.js 18.x or higher
- npm or yarn
- Supabase account
- Stripe account (for payments)
- Backend/webhook service (n8n, Express.js, etc.)

## 🔧 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dnai-auth-app
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   - Copy `env.production.template` to `.env.production`
   - Fill in all required values (see Environment Variables section)

4. **Build for production**
   ```bash
   npm run build
   ```

5. **Deploy**
   - Deploy the `build` folder to your hosting provider
   - Configure environment variables in your hosting platform

## 🔐 Environment Variables

### Required

```env
REACT_APP_SUPABASE_URL=your_supabase_project_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Recommended

```env
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_live_your_stripe_key
REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL=https://your-backend.com/api/stripe/create-checkout-session
REACT_APP_STRIPE_PAYMENT_WEBHOOK_URL=https://your-backend.com/api/stripe/verify-payment
REACT_APP_BOT_CREATION_WEBHOOK_URL=https://your-backend.com/webhook/bot-creation
REACT_APP_PHONE_NUMBER_WEBHOOK_URL=https://your-backend.com/webhook/phone-number
REACT_APP_APP_URL=https://your-production-domain.com
REACT_APP_APP_NAME=Inbound House DNAI
```

See `env.production.template` for all available options.

## 🗄️ Database Setup

Run these SQL files in your Supabase SQL Editor (in order):

1. `billing-schema.sql` - Billing, credits, subscriptions
2. `call-scheduling-schema.sql` - Call schedules and availability
3. `call-history-schema.sql` - Call history and analytics
4. `inbound-numbers-schema.sql` - Inbound phone numbers
5. `voice-agents-schema.sql` - Voice agents

**Note:** If you've already run these, use the migration script provided in the conversation history to update functions and packages.

## 💳 Credit System

### Rates
- **Purchase**: $1.00 = 5 credits
- **Call Usage**: 1 minute = 3 credits
- **Agent Creation**: 1 agent = 5 credits

### Subscription Plans
- **Genie**: $10/month, 50 credits, 1 agent, 1 number
- **Starter**: $29.99/month, 150 credits, 1 agent, 1 number
- **Professional**: $99.99/month, 500 credits, 5 agents, 5 numbers
- **Enterprise**: $299.99/month, 1500 credits, unlimited

Credits roll over monthly.

## 🔌 Webhook Setup

### Required Webhooks

1. **Stripe Checkout Session Creation**
   - Endpoint: `POST /api/stripe/create-checkout-session`
   - Creates Stripe checkout sessions for credit purchases

2. **Stripe Payment Verification**
   - Endpoint: `POST /api/stripe/verify-payment`
   - Verifies payment after checkout completion

3. **Stripe Webhook Handler** (Recommended)
   - Endpoint: `POST /api/stripe/webhook`
   - Handles Stripe webhook events
   - See `STRIPE_PAYMENT_SETUP.md` for details

4. **Bot Creation Webhook**
   - Endpoint: Your n8n/webhook URL
   - Called when agent is created
   - Must succeed before agent is saved to database

5. **Phone Number Import Webhook**
   - Endpoint: Your n8n/webhook URL
   - Called when inbound number is imported
   - Must succeed before number is saved to database

6. **Call Completion Webhook** (For Credit Deduction)
   - Should call `deduct_call_credits()` RPC function
   - See `CALL_CREDIT_DEDUCTION_WEBHOOK.md` for details

## 📱 Features

### Authentication
- ✅ User signup with email verification
- ✅ Secure login
- ✅ Password reset
- ✅ Email verification
- ✅ Session management

### Voice Agents
- ✅ Create AI voice agents
- ✅ Manage multiple agents
- ✅ Agent configuration
- ✅ Credit deduction on creation (5 credits)

### Inbound Numbers
- ✅ Import phone numbers from multiple providers
- ✅ Provider configuration (Twilio, Vonage, CallHippo, Telnyx)
- ✅ Number status tracking
- ✅ Health monitoring

### Call Management
- ✅ Call history tracking
- ✅ Call analytics
- ✅ Call recordings
- ✅ Transcripts
- ✅ Credit deduction (3 credits/minute)

### Scheduling
- ✅ Weekly availability templates
- ✅ Holiday configuration
- ✅ After-hours messages
- ✅ Schedule overrides
- ✅ Calendar preview

### Billing & Credits
- ✅ Credit purchase via Stripe
- ✅ Subscription management
- ✅ Invoice generation
- ✅ Transaction history
- ✅ Auto-topup configuration

### Profile Management
- ✅ User profile viewing/editing
- ✅ Password change
- ✅ Account settings

## 🏗️ Project Structure

```
src/
├── components/          # React components
│   ├── layout/        # Layout components (Header, Sidebar, MainLayout)
│   ├── scheduling/    # Call scheduling components
│   └── ...
├── contexts/          # React contexts (AuthContext)
├── services/          # Service utilities
│   ├── creditService.ts
│   └── paymentService.ts
├── lib/              # Library configurations
│   └── supabase.ts
├── theme/            # Material-UI theme
└── utils/            # Utility functions
    └── envValidation.ts
```

## 🧪 Testing

### Manual Testing Checklist

- [ ] User signup and email verification
- [ ] User login
- [ ] Password reset
- [ ] Agent creation (with credit check)
- [ ] Credit purchase
- [ ] Payment processing
- [ ] Invoice generation
- [ ] Call history viewing
- [ ] Profile management
- [ ] Subscription management

### Test Cards (Stripe Test Mode)

- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- 3D Secure: `4000 0025 0000 3155`

## 🐛 Troubleshooting

### Common Issues

1. **"Failed to fetch" errors**
   - Check CORS configuration on backend
   - Verify webhook URLs are correct
   - Check network connectivity

2. **Credit deduction not working**
   - Verify `deduct_call_credits` function exists
   - Check RLS policies allow credit updates
   - Verify call duration is set correctly

3. **Payment not processing**
   - Check Stripe keys are correct (live vs test)
   - Verify webhook endpoints are accessible
   - Check Stripe dashboard for payment status

4. **Agent creation fails**
   - Check user has sufficient credits (5 credits required)
   - Verify webhook URL is accessible
   - Check database constraints

## 📚 Documentation

- `CREDIT_SYSTEM.md` - Credit system documentation
- `STRIPE_PAYMENT_SETUP.md` - Stripe payment integration guide
- `CALL_CREDIT_DEDUCTION_WEBHOOK.md` - Call credit deduction setup
- `DEPLOYMENT_CHECKLIST.md` - Complete deployment checklist

## 🔒 Security

- ✅ Row Level Security (RLS) on all tables
- ✅ Environment variables for sensitive data
- ✅ Webhook signature verification
- ✅ Secure password handling
- ✅ HTTPS required in production

## 📊 Monitoring

### Recommended Monitoring

- Error tracking (Sentry, LogRocket)
- Analytics (Google Analytics)
- Uptime monitoring
- Payment monitoring
- Credit balance alerts

## 🚀 Deployment

See `DEPLOYMENT_CHECKLIST.md` for complete deployment steps.

### Quick Deploy (Vercel)

1. Connect repository to Vercel
2. Set environment variables
3. Deploy

### Quick Deploy (Netlify)

1. Connect repository to Netlify
2. Set build command: `npm run build`
3. Set publish directory: `build`
4. Set environment variables
5. Deploy

## 📞 Support

For issues or questions:
- Check documentation files
- Review error logs
- Contact support team

## 📝 License

[Your License Here]

## 🙏 Acknowledgments

- Material-UI for UI components
- Supabase for backend services
- Stripe for payment processing

---

**Last Updated:** [Current Date]
**Version:** 1.0.0
