# Webhook CORS Issue - Solution Guide

## 🔴 Problem: "Failed to fetch" Error

When calling webhooks from the browser, you're encountering CORS (Cross-Origin Resource Sharing) errors. This happens because:

1. **Browser Security**: Browsers block cross-origin requests for security
2. **Different Domain**: Your React app (localhost:3000) is calling `auto.nsolbpo.com:5678`
3. **No CORS Headers**: The webhook server doesn't allow requests from your origin

## ✅ Solutions

### Option 1: Configure CORS on Webhook Server (Recommended for Production)

The webhook server at `auto.nsolbpo.com:5678` needs to allow requests from your React app's origin.

**Required CORS Headers:**
```
Access-Control-Allow-Origin: http://localhost:3000  (for development)
Access-Control-Allow-Origin: https://your-production-domain.com  (for production)
Access-Control-Allow-Methods: POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept
Access-Control-Allow-Credentials: true (if needed)
```

**For Development:**
```
Access-Control-Allow-Origin: *
```

### Option 2: Backend Proxy Endpoint (Most Secure)

Create a backend API endpoint that proxies webhook calls. This is the most secure approach.

#### Step 1: Create Backend Endpoint

Create a file `api/proxy-webhook.js` (for serverless) or add to your Express server:

```javascript
// For serverless function (Vercel, Netlify, etc.)
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { webhookUrl, payload } = req.body;

  if (!webhookUrl || !payload) {
    return res.status(400).json({ error: 'Missing webhookUrl or payload' });
  }

  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json().catch(() => ({ success: response.ok }));

    return res.status(response.status).json(data);
  } catch (error) {
    console.error('Webhook proxy error:', error);
    return res.status(500).json({ error: error.message });
  }
}
```

#### Step 2: Update React Component

Update `CreateVoiceAgent.tsx` to use the proxy:

```typescript
// Instead of calling webhook directly:
const webhookResponse = await fetch('/api/proxy-webhook', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    webhookUrl: botWebhookUrl,
    payload: webhookPayload,
  }),
});
```

### Option 3: Temporary Development Workaround

For development/testing only, you can temporarily bypass CORS (NOT recommended for production):

**⚠️ WARNING: This only works if the server doesn't check CORS, and you won't be able to read the response properly.**

```typescript
const webhookResponse = await fetch(botWebhookUrl, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(webhookPayload),
  mode: 'no-cors', // This bypasses CORS but you can't read the response
});
```

**Problems with this approach:**
- You can't verify if the webhook succeeded
- You can't read error messages
- Not secure for production

## 🔍 Debugging Steps

1. **Check Browser Console**: Look for detailed CORS error messages
2. **Check Network Tab**: See the actual request/response
3. **Test Webhook Directly**: Use Postman/curl to verify the webhook works
4. **Check Server Logs**: See if requests are reaching the server

## 📋 Current Implementation

The current code:
- ✅ Calls webhook before saving to database
- ✅ Has proper error handling
- ✅ Logs detailed error information
- ❌ Fails due to CORS restrictions

## 🚀 Recommended Action

**Contact your backend team** to:
1. Add CORS headers to the webhook server
2. OR set up a backend proxy endpoint
3. OR provide a different webhook URL that allows CORS

The webhook server at `auto.nsolbpo.com:5678` needs to be configured to accept requests from your React application's origin.
