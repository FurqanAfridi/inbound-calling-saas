# Deployment Checklist

## Pre-Deployment

### 1. Environment Variables
- [ ] Copy `.env.local.template` to `.env.production`
- [ ] Set `REACT_APP_SUPABASE_URL` (production Supabase project)
- [ ] Set `REACT_APP_SUPABASE_ANON_KEY` (production anon key)
- [ ] Set `REACT_APP_SUPABASE_SERVICE_ROLE_KEY` (for backend operations)
- [ ] Set `REACT_APP_STRIPE_PUBLISHABLE_KEY` (live key: `pk_live_...`)
- [ ] Set `REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL` (production backend URL)
- [ ] Set `REACT_APP_STRIPE_PAYMENT_WEBHOOK_URL` (production backend URL)
- [ ] Set `REACT_APP_BOT_CREATION_WEBHOOK_URL` (production n8n/webhook URL)
- [ ] Set `REACT_APP_PHONE_NUMBER_WEBHOOK_URL` (production n8n/webhook URL)
- [ ] Set `REACT_APP_APP_URL` (production domain)
- [ ] Set `REACT_APP_APP_NAME` (if different from default)

### 2. Database Setup
- [ ] Run `billing-schema.sql` in Supabase SQL Editor
- [ ] Run `call-scheduling-schema.sql` in Supabase SQL Editor
- [ ] Run `call-history-schema.sql` in Supabase SQL Editor
- [ ] Run `inbound-numbers-schema.sql` in Supabase SQL Editor
- [ ] Run `voice-agents-schema.sql` in Supabase SQL Editor
- [ ] Verify all RLS policies are active
- [ ] Test database functions (add_credits, deduct_call_credits, etc.)
- [ ] Verify subscription packages are inserted (Genie, Starter, etc.)

### 3. Supabase Configuration
- [ ] Enable Row Level Security (RLS) on all tables
- [ ] Verify RLS policies allow authenticated users to access their data
- [ ] Set up Supabase Auth email templates
- [ ] Configure email provider (SendGrid) in Supabase
- [ ] Test user signup flow
- [ ] Test password reset flow
- [ ] Test email verification flow

### 4. Stripe Configuration
- [ ] Create Stripe account (if not exists)
- [ ] Get live API keys from Stripe Dashboard
- [ ] Set up webhook endpoints in Stripe Dashboard:
  - [ ] `checkout.session.completed`
  - [ ] `payment_intent.succeeded`
  - [ ] `payment_intent.payment_failed`
- [ ] Configure webhook signing secret
- [ ] Test payment flow with test cards
- [ ] Verify webhook signature validation in backend

### 5. Backend/Webhook Setup
- [ ] Deploy backend API (or configure n8n workflows)
- [ ] Set up Stripe checkout session creation endpoint
- [ ] Set up Stripe payment verification endpoint
- [ ] Set up Stripe webhook handler
- [ ] Set up bot creation webhook
- [ ] Set up phone number import webhook
- [ ] Set up call completion webhook (for credit deduction)
- [ ] Test all webhook endpoints
- [ ] Configure CORS for frontend domain
- [ ] Set up error logging and monitoring

### 6. Build & Test
- [ ] Run `npm install` to install all dependencies
- [ ] Run `npm run build` to create production build
- [ ] Test production build locally
- [ ] Check for console errors
- [ ] Verify all routes work correctly
- [ ] Test authentication flows
- [ ] Test credit purchase flow
- [ ] Test agent creation (with credit deduction)
- [ ] Test subscription management

## Deployment

### 7. Hosting Setup
- [ ] Choose hosting provider (Vercel, Netlify, AWS, etc.)
- [ ] Connect repository to hosting platform
- [ ] Configure build settings:
  - Build command: `npm run build`
  - Output directory: `build`
  - Node version: 18.x or higher
- [ ] Set environment variables in hosting platform
- [ ] Configure custom domain (if applicable)
- [ ] Set up SSL certificate
- [ ] Configure redirects (SPA routing)

### 8. Post-Deployment Verification
- [ ] Test app loads correctly
- [ ] Test user signup
- [ ] Test user login
- [ ] Test password reset
- [ ] Test email verification
- [ ] Test dashboard loads
- [ ] Test agent creation
- [ ] Test credit purchase
- [ ] Test payment processing
- [ ] Test invoice generation
- [ ] Test call history
- [ ] Test billing page
- [ ] Test profile page
- [ ] Test all navigation links

### 9. Security Checklist
- [ ] Verify HTTPS is enabled
- [ ] Check CORS configuration
- [ ] Verify API keys are not exposed in frontend code
- [ ] Test RLS policies prevent unauthorized access
- [ ] Verify webhook signature validation
- [ ] Check for sensitive data in console logs
- [ ] Review error messages (don't expose internal details)
- [ ] Set up rate limiting (if applicable)
- [ ] Configure CSP headers (if applicable)

### 10. Monitoring & Analytics
- [ ] Set up error tracking (Sentry, LogRocket, etc.)
- [ ] Set up analytics (Google Analytics, etc.)
- [ ] Configure uptime monitoring
- [ ] Set up payment monitoring
- [ ] Set up credit balance alerts
- [ ] Configure email notifications for errors
- [ ] Set up database backup schedule

### 11. Documentation
- [ ] Update README with deployment instructions
- [ ] Document environment variables
- [ ] Document webhook endpoints
- [ ] Create user guide (if needed)
- [ ] Document API endpoints (if applicable)
- [ ] Create troubleshooting guide

## Production Optimizations

### 12. Performance
- [ ] Enable code splitting
- [ ] Optimize images
- [ ] Enable gzip compression
- [ ] Set up CDN (if applicable)
- [ ] Optimize bundle size
- [ ] Enable caching headers
- [ ] Test page load times

### 13. SEO (if applicable)
- [ ] Add meta tags
- [ ] Configure Open Graph tags
- [ ] Set up sitemap
- [ ] Configure robots.txt
- [ ] Test social media sharing

## Maintenance

### 14. Regular Tasks
- [ ] Monitor error logs daily
- [ ] Check credit balance alerts
- [ ] Review payment failures
- [ ] Monitor webhook success rates
- [ ] Review user feedback
- [ ] Update dependencies monthly
- [ ] Review security updates
- [ ] Backup database regularly

### 15. Updates
- [ ] Test updates in staging first
- [ ] Update environment variables if needed
- [ ] Run database migrations
- [ ] Update frontend code
- [ ] Verify all features still work
- [ ] Monitor for errors after update

## Rollback Plan

### 16. Emergency Procedures
- [ ] Document rollback procedure
- [ ] Keep previous build artifacts
- [ ] Document database rollback steps
- [ ] Have backup of environment variables
- [ ] Test rollback procedure in staging

## Support

### 17. Support Setup
- [ ] Set up support email
- [ ] Configure support ticket system (if applicable)
- [ ] Create FAQ document
- [ ] Set up user communication channels
- [ ] Document common issues and solutions

## Testing Checklist

### 18. User Flows
- [ ] New user signup → email verification → login
- [ ] Existing user login
- [ ] Password reset flow
- [ ] Profile update
- [ ] Credit purchase → payment → credit addition
- [ ] Agent creation → credit deduction
- [ ] Call completion → credit deduction (via webhook)
- [ ] Subscription management
- [ ] Invoice download
- [ ] Call history viewing
- [ ] Dashboard statistics

### 19. Edge Cases
- [ ] Insufficient credits for agent creation
- [ ] Payment failure handling
- [ ] Webhook timeout handling
- [ ] Network error handling
- [ ] Invalid input validation
- [ ] Session expiration handling
- [ ] Concurrent operations

## Final Steps

- [ ] Review all checkboxes
- [ ] Perform final smoke test
- [ ] Announce deployment to team
- [ ] Monitor closely for first 24 hours
- [ ] Collect user feedback
- [ ] Document any issues encountered

---

**Note:** This checklist should be customized based on your specific deployment environment and requirements.
