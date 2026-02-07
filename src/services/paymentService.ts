import { loadStripe, Stripe } from '@stripe/stripe-js';

// Initialize Stripe
let stripePromise: Promise<Stripe | null> | null = null;

const getStripe = () => {
  if (!stripePromise) {
    const stripeKey = process.env.REACT_APP_STRIPE_PUBLISHABLE_KEY;
    if (!stripeKey) {
      console.error('Stripe publishable key is not configured');
      return Promise.resolve(null);
    }
    stripePromise = loadStripe(stripeKey);
  }
  return stripePromise;
};

interface CreateCheckoutSessionParams {
  userId: string;
  amount: number;
  creditsAmount: number;
  purchaseId: string;
  successUrl: string;
  cancelUrl: string;
}

/**
 * Creates a Stripe Checkout session for credit purchase
 * This requires a backend endpoint to create the session securely
 */
export const createCheckoutSession = async (params: CreateCheckoutSessionParams) => {
  try {
    const checkoutWebhookUrl = process.env.REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL;
    
    if (!checkoutWebhookUrl) {
      throw new Error('Stripe checkout webhook URL is not configured. Please set REACT_APP_STRIPE_CHECKOUT_WEBHOOK_URL');
    }

    // Call your backend webhook/API to create checkout session
    const response = await fetch(checkoutWebhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        user_id: params.userId,
        amount: params.amount,
        credits_amount: params.creditsAmount,
        purchase_id: params.purchaseId,
        success_url: params.successUrl,
        cancel_url: params.cancelUrl,
        currency: 'usd',
        metadata: {
          purchase_id: params.purchaseId,
          user_id: params.userId,
          type: 'credit_purchase',
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => 'Unknown error');
      throw new Error(`Failed to create checkout session: ${errorText}`);
    }

    const { sessionId, url } = await response.json();

    if (!sessionId || !url) {
      throw new Error('Invalid response from checkout session creation');
    }

    return { sessionId, url };
  } catch (error: any) {
    console.error('Error creating checkout session:', error);
    throw error;
  }
};

/**
 * Redirects to Stripe Checkout
 */
export const redirectToCheckout = async (checkoutUrl: string) => {
  window.location.href = checkoutUrl;
};

/**
 * Processes payment after successful checkout
 * This is called when user returns from Stripe Checkout
 */
export const processPaymentSuccess = async (sessionId: string, purchaseId: string) => {
  try {
    // Verify payment with backend
    const paymentWebhookUrl = process.env.REACT_APP_STRIPE_PAYMENT_WEBHOOK_URL;
    
    if (!paymentWebhookUrl) {
      throw new Error('Stripe payment webhook URL is not configured');
    }

    const response = await fetch(paymentWebhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        session_id: sessionId,
        purchase_id: purchaseId,
        action: 'verify_payment',
      }),
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => 'Unknown error');
      throw new Error(`Payment verification failed: ${errorText}`);
    }

    const result = await response.json();
    return result;
  } catch (error: any) {
    console.error('Error processing payment:', error);
    throw error;
  }
};

/**
 * Alternative: Direct payment using Stripe Elements (embedded form)
 * This requires a backend to create PaymentIntent
 */
export const createPaymentIntent = async (params: {
  userId: string;
  amount: number;
  creditsAmount: number;
  purchaseId: string;
}) => {
  try {
    const paymentIntentWebhookUrl = process.env.REACT_APP_STRIPE_PAYMENT_INTENT_WEBHOOK_URL;
    
    if (!paymentIntentWebhookUrl) {
      throw new Error('Stripe payment intent webhook URL is not configured');
    }

    const response = await fetch(paymentIntentWebhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        user_id: params.userId,
        amount: Math.round(params.amount * 100), // Convert to cents
        credits_amount: params.creditsAmount,
        purchase_id: params.purchaseId,
        currency: 'usd',
        metadata: {
          purchase_id: params.purchaseId,
          user_id: params.userId,
          type: 'credit_purchase',
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => 'Unknown error');
      throw new Error(`Failed to create payment intent: ${errorText}`);
    }

    const { clientSecret, paymentIntentId } = await response.json();

    if (!clientSecret) {
      throw new Error('Invalid response from payment intent creation');
    }

    return { clientSecret, paymentIntentId };
  } catch (error: any) {
    console.error('Error creating payment intent:', error);
    throw error;
  }
};

/**
 * Confirms payment with Stripe using client secret
 */
export const confirmPayment = async (clientSecret: string, paymentMethodId: string) => {
  try {
    const stripe = await getStripe();
    if (!stripe) {
      throw new Error('Stripe is not initialized');
    }

    const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
      payment_method: paymentMethodId,
    });

    if (error) {
      throw new Error(error.message || 'Payment failed');
    }

    return paymentIntent;
  } catch (error: any) {
    console.error('Error confirming payment:', error);
    throw error;
  }
};
