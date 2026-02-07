# Credit System Documentation

## 💰 Credit Conversion Rates

### Purchase Rate
- **$1.00 = 5 Credits**
- When users purchase credits, they receive 5 credits for every dollar spent
- Example: $10 purchase = 50 credits

### Credit Usage Rates

#### Calling
- **1 minute AI call = 3 credits**
- Credits are deducted based on actual call duration
- Example: 5-minute call = 15 credits

#### Agent Creation
- **Create 1 agent = 5 credits**
- One-time deduction when agent is created
- Credits are checked before agent creation
- If insufficient credits, agent creation is blocked

## 📦 Subscription Plans

### Genie Plan (Base Plan)
- **Monthly Price**: $10.00
- **Included Credits**: 50 credits per month
- **Max Agents**: 1
- **Max Inbound Numbers**: 1
- **Monthly Call Minutes**: Unlimited (limited by credits)
- **Credits Roll Over**: Yes, unused credits accumulate

### Other Plans
- **Starter**: $29.99/month, 150 credits, 1 agent, 1 number
- **Professional**: $99.99/month, 500 credits, 5 agents, 5 numbers
- **Enterprise**: $299.99/month, 1500 credits, unlimited agents/numbers

## 🔄 Credit Rollover

- **Credits DO roll over** from month to month
- Unused subscription credits accumulate in your balance
- Purchased credits also accumulate
- No expiration date on credits

## 📊 Credit Balance Management

### Low Credit Threshold
- Default threshold: 10 credits
- Users receive warning when balance falls below threshold
- Services are automatically paused when balance reaches 0

### Auto-Topup
- Optional feature to automatically purchase credits
- User can set:
  - Top-up amount (e.g., $20 = 100 credits)
  - Threshold (e.g., when balance falls below 10 credits)
- Auto-topup triggers when threshold is reached

## 🔧 Database Functions

### `add_credits(p_user_id, p_amount, p_transaction_type, p_purchase_id)`
- Adds credits to user account
- Supports 'purchase' and 'subscription_credit' types
- Updates total_purchased only for purchases

### `deduct_call_credits(p_user_id, p_call_id, p_agent_id, p_duration_seconds, p_credits_per_minute)`
- Deducts credits for call usage
- Default: 3 credits per minute
- Automatically pauses services if balance reaches 0

### `deduct_agent_creation_credits(p_user_id, p_agent_id, p_agent_name)`
- Deducts 5 credits when creating an agent
- Checks balance before deduction
- Throws error if insufficient credits

### `add_monthly_subscription_credits(p_user_id, p_subscription_id)`
- Adds monthly subscription credits
- Credits roll over (added to existing balance)
- Should be called monthly via cron job or scheduled task

## 💳 Payment Processing

### Credit Purchase Flow
1. User enters dollar amount (e.g., $10)
2. System calculates credits: $10 × 5 = 50 credits
3. Creates purchase record with:
   - `amount`: $10.00
   - `credits_amount`: 50.00
   - `credits_rate`: 0.20 (cost per credit)
4. Processes payment via Stripe
5. Adds credits to account after successful payment
6. Generates invoice automatically

## 🚫 Service Pause Logic

Services are automatically paused when:
- Credit balance reaches 0 or below
- User attempts to create agent without sufficient credits (5 credits required)
- User attempts to make calls without sufficient credits

Services are automatically resumed when:
- Credits are purchased and added to account
- Monthly subscription credits are added

## 📝 Usage Examples

### Example 1: User purchases $20 worth of credits
- Amount: $20.00
- Credits received: 100 credits (20 × 5)
- Balance updated: +100 credits

### Example 2: User makes a 10-minute call
- Call duration: 10 minutes
- Credits deducted: 30 credits (10 × 3)
- Balance updated: -30 credits

### Example 3: User creates 2 agents
- Agents created: 2
- Credits deducted: 10 credits (2 × 5)
- Balance updated: -10 credits

### Example 4: Genie subscription monthly credits
- Subscription: Genie ($10/month)
- Monthly credits: 50 credits
- If user has 20 credits remaining from previous month:
  - New balance: 70 credits (20 + 50)
  - Credits roll over as specified

## 🔔 Notifications

### Low Credit Warning
- Triggered when balance ≤ low_credit_threshold (default: 10 credits)
- Shown in billing dashboard
- User can purchase credits directly from warning

### Service Paused Alert
- Shown when services_paused = true
- Prevents agent creation and calls
- User must purchase credits to resume

## 🎯 Integration Points

### Agent Creation
- Check credits before creation (5 credits required)
- Deduct credits after successful creation
- Show error if insufficient credits

### Call Completion
- Deduct credits after call ends
- Calculate based on actual duration
- 3 credits per minute

### Monthly Subscription
- Add monthly credits on subscription renewal
- Use `add_monthly_subscription_credits()` function
- Credits roll over to existing balance
