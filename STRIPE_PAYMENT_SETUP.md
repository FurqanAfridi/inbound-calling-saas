# Stripe Payment Integration Setup Guide

This guide explains how to set up Stripe payment processing for credit purchases in the application.

## 📋 Prerequisites

1. Stripe account (sign up at https://stripe.com)
2. Backend API/server to handle Stripe webhooks securely
3. Environment variables configured

## 🔧 Step 1: Get Your Stripe Keys

1. Go to your Stripe Dashboard: https://dashboard.stripe.com
2. Navigate to **Developers** → **API keys**
3. Copy the following:
   - **Publishable key** → `REACT_APP_STRIPE_PUBLISHABLE_KEY`
   - **Secret key** → Keep this for your backend (never expose in frontend)

## 🔐 Step 2: Configure Environment Variables

### For Development (`.env.local`):
```env
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_your_test_publishable_key
REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL=http://localhost:3001/api/stripe/create-checkout-session
REACT_APP_STRIPE_PAYMENT_WEBHOOK_URL=http://localhost:3001/api/stripe/verify-payment
```

### For Production (`.env.production`):
```env
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_live_your_live_publishable_key
REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL=https://your-backend.com/api/stripe/create-checkout-session
REACT_APP_STRIPE_PAYMENT_WEBHOOK_URL=https://your-backend.com/api/stripe/verify-payment
```

## 🚀 Step 3: Install Dependencies

The Stripe dependency is already added to `package.json`. Install it:

```bash
npm install
```

## 🔌 Step 4: Backend Webhook Endpoints

You need to create two backend endpoints to handle Stripe operations securely:

### Endpoint 1: Create Checkout Session

**URL**: `POST /api/stripe/create-checkout-session`

**Request Body**:
```json
{
  "user_id": "uuid",
  "amount": 10.00,
  "credits_amount": 10.00,
  "purchase_id": "uuid",
  "success_url": "https://yourapp.com/billing?session_id={CHECKOUT_SESSION_ID}&purchase_id=uuid",
  "cancel_url": "https://yourapp.com/billing?canceled=true",
  "currency": "usd",
  "metadata": {
    "purchase_id": "uuid",
    "user_id": "uuid",
    "type": "credit_purchase"
  }
}
```

**Backend Implementation (Node.js/Express example)**:
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/api/stripe/create-checkout-session', async (req, res) => {
  try {
    const { user_id, amount, credits_amount, purchase_id, success_url, cancel_url, currency, metadata } = req.body;

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: currency || 'usd',
            product_data: {
              name: `Credit Purchase - ${credits_amount} credits`,
              description: `Purchase ${credits_amount} credits for your account`,
            },
            unit_amount: Math.round(amount * 100), // Convert to cents
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: success_url,
      cancel_url: cancel_url,
      client_reference_id: purchase_id,
      metadata: metadata,
      customer_email: req.user.email, // If you have user email
    });

    res.json({
      sessionId: session.id,
      url: session.url,
    });
  } catch (error) {
    console.error('Error creating checkout session:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### Endpoint 2: Verify Payment

**URL**: `POST /api/stripe/verify-payment`

**Request Body**:
```json
{
  "session_id": "cs_test_...",
  "purchase_id": "uuid",
  "action": "verify_payment"
}
```

**Backend Implementation**:
```javascript
app.post('/api/stripe/verify-payment', async (req, res) => {
  try {
    const { session_id, purchase_id } = req.body;

    // Retrieve the checkout session
    const session = await stripe.checkout.sessions.retrieve(session_id);

    if (session.payment_status === 'paid') {
      // Payment successful
      res.json({
        success: true,
        session_id: session.id,
        payment_intent: session.payment_intent,
        amount_total: session.amount_total / 100, // Convert from cents
        currency: session.currency,
      });
    } else {
      res.json({
        success: false,
        error: 'Payment not completed',
        payment_status: session.payment_status,
      });
    }
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({ error: error.message });
  }
});
```

## 🔔 Step 5: Stripe Webhook for Payment Confirmation

Set up a Stripe webhook to handle payment events securely. This is the recommended approach for production.

### Webhook Endpoint

**URL**: `POST /api/stripe/webhook`

**Stripe Events to Listen For**:
- `checkout.session.completed` - When payment is successful
- `payment_intent.succeeded` - When payment intent succeeds
- `payment_intent.payment_failed` - When payment fails

### Webhook Implementation

```javascript
const express = require('express');
const app = express();

// Stripe webhook endpoint (must be before body parser)
app.post('/api/stripe/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object;
      
      // Get purchase_id from metadata
      const purchaseId = session.metadata?.purchase_id;
      const userId = session.metadata?.user_id;
      
      if (purchaseId && userId) {
        // Update purchase status in database
        await updatePurchaseStatus(purchaseId, 'completed');
        
        // Add credits to user account
        await addCreditsToUser(userId, session.metadata.credits_amount, purchaseId);
        
        // Generate invoice
        await generateInvoice(purchaseId, userId);
      }
      break;

    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log('PaymentIntent succeeded:', paymentIntent.id);
      break;

    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.log('Payment failed:', failedPayment.id);
      // Update purchase status to failed
      break;

    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});
```

### Configure Webhook in Stripe Dashboard

1. Go to **Developers** → **Webhooks** in Stripe Dashboard
2. Click **Add endpoint**
3. Enter your webhook URL: `https://your-backend.com/api/stripe/webhook`
4. Select events to listen for:
   - `checkout.session.completed`
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
5. Copy the **Webhook signing secret** → Add to your backend as `STRIPE_WEBHOOK_SECRET`

## 📝 Step 6: Update Database After Payment

After successful payment, your backend should:

1. **Update Purchase Record**:
```sql
UPDATE purchases
SET 
  payment_status = 'completed',
  completed_at = NOW(),
  payment_provider_id = :session_id,
  payment_provider_response = :stripe_response
WHERE id = :purchase_id;
```

2. **Add Credits** (using Supabase function):
```javascript
const { data, error } = await supabase.rpc('add_credits', {
  p_user_id: userId,
  p_amount: creditsAmount,
  p_transaction_type: 'purchase',
  p_purchase_id: purchaseId,
});
```

3. **Generate Invoice**:
```javascript
// Use the generate_invoice_number() function from billing-schema.sql
const { data: invoiceNumber } = await supabase.rpc('generate_invoice_number');

await supabase.from('invoices').insert({
  user_id: userId,
  invoice_number: invoiceNumber,
  invoice_date: new Date().toISOString().split('T')[0],
  purchase_id: purchaseId,
  subtotal: amount,
  tax_rate: 0,
  tax_amount: 0,
  total_amount: amount,
  currency: 'usd',
  status: 'paid',
  paid_at: new Date().toISOString(),
  items: [{
    description: `Credit Purchase - ${creditsAmount} credits`,
    quantity: 1,
    unit_price: amount,
    total: amount,
  }],
});
```

## 🧪 Step 7: Test the Integration

### Test Mode

1. Use test API keys (start with `pk_test_`)
2. Use Stripe test cards:
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`
   - 3D Secure: `4000 0025 0000 3155`
3. Use any future expiry date and any 3-digit CVC

### Test Flow

1. User clicks "Buy Credits"
2. Enters amount (e.g., $10)
3. Redirects to Stripe Checkout
4. Completes payment with test card
5. Returns to billing page
6. Credits are added to account
7. Invoice is generated

## 🔒 Security Best Practices

1. **Never expose secret keys** in frontend code
2. **Always verify webhook signatures** using Stripe's signing secret
3. **Use HTTPS** for all webhook endpoints
4. **Validate amounts** on the backend before processing
5. **Idempotency**: Handle duplicate webhook events gracefully
6. **Log all payment events** for audit trail

## 📊 Payment Flow Diagram

```
User → Frontend → Backend API → Stripe Checkout
                                    ↓
                              User Pays
                                    ↓
                              Stripe Webhook → Backend
                                    ↓
                              Update Database
                                    ↓
                              Add Credits
                                    ↓
                              Generate Invoice
                                    ↓
                              Frontend Updates
```

## 🐛 Troubleshooting

### Payment Not Processing
- Check Stripe dashboard for payment status
- Verify webhook endpoint is accessible
- Check webhook signature verification
- Review backend logs for errors

### Credits Not Added
- Verify `add_credits` function exists in database
- Check RLS policies allow credit updates
- Verify purchase_id matches in transaction

### Invoice Not Generated
- Check `generate_invoice_number` function exists
- Verify invoice table RLS policies
- Check for errors in invoice generation

## 📚 Additional Resources

- [Stripe Checkout Documentation](https://stripe.com/docs/payments/checkout)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
