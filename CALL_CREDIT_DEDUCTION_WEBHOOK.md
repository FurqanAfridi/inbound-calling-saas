# Call Credit Deduction Webhook Documentation

## Overview

When a call is completed, credits must be deducted from the user's account. This document explains how to set up the webhook to handle automatic credit deduction.

## Credit Rate

- **1 minute of AI call = 3 credits**
- Credits are deducted based on actual call duration in seconds

## Database Function

The database provides a function `deduct_call_credits()` that handles credit deduction:

```sql
deduct_call_credits(
    p_user_id UUID,
    p_call_id UUID,
    p_agent_id UUID,
    p_duration_seconds INTEGER,
    p_credits_per_minute DECIMAL DEFAULT 3.0
)
```

## Webhook Implementation

### Option 1: Backend Webhook (Recommended)

When a call completes, your backend should:

1. Receive call completion event from your telephony provider (Twilio, Vonage, etc.)
2. Update the call record in `call_history` table
3. Call the database function to deduct credits

#### Example Implementation (Node.js/Express)

```javascript
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function handleCallCompletion(callData) {
  try {
    const {
      callId,
      userId,
      agentId,
      durationSeconds,
      status,
    } = callData;

    // Update call record
    const { error: updateError } = await supabase
      .from('call_history')
      .update({
        call_status: status,
        call_duration: durationSeconds,
        call_end_time: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', callId);

    if (updateError) {
      console.error('Error updating call record:', updateError);
      throw updateError;
    }

    // Only deduct credits for completed/answered calls
    if (status === 'answered' || status === 'completed') {
      const { data, error: creditsError } = await supabase.rpc('deduct_call_credits', {
        p_user_id: userId,
        p_call_id: callId,
        p_agent_id: agentId,
        p_duration_seconds: durationSeconds,
        p_credits_per_minute: 3.0,
      });

      if (creditsError) {
        console.error('Error deducting call credits:', creditsError);
        // Log error but don't fail the call update
        // You might want to implement retry logic here
      } else {
        console.log(`Deducted ${data} credits for call ${callId}`);
      }
    }

    return { success: true };
  } catch (error) {
    console.error('Error handling call completion:', error);
    throw error;
  }
}
```

### Option 2: Database Trigger (Alternative)

You can create a database trigger that automatically deducts credits when a call is marked as completed:

```sql
-- Function to automatically deduct credits on call completion
CREATE OR REPLACE FUNCTION auto_deduct_call_credits()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when call status changes to 'answered' or 'completed'
    IF (NEW.call_status IN ('answered', 'completed') 
        AND OLD.call_status NOT IN ('answered', 'completed')
        AND NEW.call_duration > 0) THEN
        
        -- Deduct credits
        PERFORM deduct_call_credits(
            NEW.user_id,
            NEW.id,
            NEW.agent_id,
            NEW.call_duration,
            3.0 -- 3 credits per minute
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER trigger_auto_deduct_call_credits
    AFTER UPDATE ON public.call_history
    FOR EACH ROW
    WHEN (NEW.call_status IN ('answered', 'completed') 
          AND OLD.call_status NOT IN ('answered', 'completed'))
    EXECUTE FUNCTION auto_deduct_call_credits();
```

**Note:** This approach automatically deducts credits whenever a call status changes to completed. Make sure your call update logic properly sets the duration.

### Option 3: n8n Workflow

If you're using n8n, create a workflow that:

1. Listens for call completion events
2. Updates the call record
3. Calls the Supabase RPC function to deduct credits

#### n8n Workflow Steps:

1. **Webhook Node** - Receive call completion event
2. **Supabase Node** - Update call record
3. **Supabase Node** - Call `deduct_call_credits` RPC function
4. **IF Node** - Check if deduction was successful
5. **Send Email Node** (optional) - Notify user if credits are low

## Call Status Handling

Credits should only be deducted for:
- ✅ `answered` - Call was answered
- ✅ `completed` - Call completed successfully

Credits should NOT be deducted for:
- ❌ `missed` - Call was missed
- ❌ `busy` - Line was busy
- ❌ `failed` - Call failed
- ❌ `no-answer` - No answer
- ❌ `canceled` - Call was canceled

## Error Handling

### Insufficient Credits

If a user doesn't have enough credits:
- The `deduct_call_credits()` function will still deduct what it can
- Services will be automatically paused when balance reaches 0
- The function returns the amount deducted (may be less than calculated)

### Retry Logic

If credit deduction fails:
1. Log the error
2. Store the call record for later processing
3. Implement a retry mechanism (e.g., queue for processing)
4. Notify administrators if retries fail

## Testing

### Test Credit Deduction

```sql
-- Test credit deduction manually
SELECT deduct_call_credits(
    'user-uuid-here',
    'call-uuid-here',
    'agent-uuid-here',
    120, -- 2 minutes = 6 credits
    3.0
);
```

### Verify Credits

```sql
-- Check user's credit balance
SELECT balance, total_used 
FROM user_credits 
WHERE user_id = 'user-uuid-here';

-- Check credit transactions
SELECT * 
FROM credit_transactions 
WHERE user_id = 'user-uuid-here' 
ORDER BY created_at DESC 
LIMIT 10;
```

## Monitoring

### Key Metrics to Monitor

1. **Credit Deduction Success Rate** - Track failed deductions
2. **Average Credits per Call** - Should be ~3 credits per minute
3. **Low Credit Warnings** - Users approaching threshold
4. **Service Pauses** - Users with paused services due to credits

### Alerts

Set up alerts for:
- High rate of failed credit deductions
- Users with negative credit balances (shouldn't happen)
- Calls not deducting credits (data integrity issue)

## Integration Checklist

- [ ] Set up webhook endpoint for call completion events
- [ ] Implement credit deduction logic
- [ ] Add error handling and retry logic
- [ ] Test with various call durations
- [ ] Test with insufficient credits scenario
- [ ] Set up monitoring and alerts
- [ ] Document webhook URL for your telephony provider
- [ ] Test in production with small volume first

## Example Webhook Payload

```json
{
  "callId": "call-uuid-123",
  "userId": "user-uuid-456",
  "agentId": "agent-uuid-789",
  "durationSeconds": 180,
  "status": "completed",
  "callerNumber": "+1234567890",
  "calledNumber": "+0987654321",
  "startTime": "2024-01-15T10:00:00Z",
  "endTime": "2024-01-15T10:03:00Z"
}
```

## Support

If you encounter issues:
1. Check Supabase logs for RPC function errors
2. Verify user has sufficient credits
3. Check call record exists and has correct duration
4. Ensure RLS policies allow credit deduction
5. Verify service role key has proper permissions
