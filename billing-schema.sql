-- ============================================
-- BILLING, CREDITS & SUBSCRIPTION MANAGEMENT
-- ============================================
-- This file contains all the database tables needed for billing and subscription management
-- Run this in your Supabase SQL Editor

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. SUBSCRIPTION PACKAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.subscription_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_name VARCHAR(255) NOT NULL,
    package_code VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'starter', 'professional', 'enterprise'
    description TEXT,
    
    -- Pricing
    monthly_price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Package Limits
    max_agents INTEGER DEFAULT 1,
    max_inbound_numbers INTEGER DEFAULT 1,
    monthly_call_minutes INTEGER DEFAULT 0, -- 0 = unlimited
    monthly_credits INTEGER DEFAULT 0, -- Credits included in package
    
    -- Features
    features JSONB DEFAULT '{}'::jsonb, -- Additional features as JSON
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_subscription_packages_is_active ON public.subscription_packages(is_active);
CREATE INDEX IF NOT EXISTS idx_subscription_packages_package_code ON public.subscription_packages(package_code);

-- ============================================
-- 2. USER SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    package_id UUID NOT NULL REFERENCES public.subscription_packages(id),
    
    -- Subscription Status
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'suspended', 'pending')),
    
    -- Billing Cycle
    billing_cycle VARCHAR(20) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    
    -- Auto-renewal
    auto_renew BOOLEAN DEFAULT true,
    cancel_at_period_end BOOLEAN DEFAULT false,
    
    -- Payment
    payment_method_id VARCHAR(255), -- Stripe payment method ID or similar
    last_payment_date TIMESTAMPTZ,
    next_billing_date TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    canceled_at TIMESTAMPTZ,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_package_id ON public.user_subscriptions(package_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_current_period_end ON public.user_subscriptions(current_period_end);

-- ============================================
-- 3. USER CREDITS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Credit Balance
    balance DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_purchased DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_used DECIMAL(10, 2) NOT NULL DEFAULT 0,
    
    -- Low Credit Threshold
    low_credit_threshold DECIMAL(10, 2) DEFAULT 10.00,
    low_credit_notified BOOLEAN DEFAULT false,
    
    -- Auto-topup
    auto_topup_enabled BOOLEAN DEFAULT false,
    auto_topup_amount DECIMAL(10, 2),
    auto_topup_threshold DECIMAL(10, 2),
    
    -- Service Status
    services_paused BOOLEAN DEFAULT false, -- Auto-paused when credits exhausted
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_topup_at TIMESTAMPTZ,
    
    UNIQUE(user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_credits_user_id ON public.user_credits(user_id);
CREATE INDEX IF NOT EXISTS idx_user_credits_balance ON public.user_credits(balance);

-- ============================================
-- 4. PURCHASES TABLE (Credit Purchases) - MUST BE BEFORE credit_transactions
-- ============================================
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Purchase Details
    purchase_type VARCHAR(20) NOT NULL CHECK (purchase_type IN ('credits', 'subscription', 'topup')),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Credits Purchased
    credits_amount DECIMAL(10, 2) NOT NULL,
    credits_rate DECIMAL(10, 4), -- Price per credit
    
    -- Payment
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    payment_method VARCHAR(50), -- 'stripe', 'paypal', 'bank_transfer', etc.
    payment_provider_id VARCHAR(255), -- Stripe payment intent ID or similar
    payment_provider_response JSONB, -- Full response from payment provider
    
    -- Tax/VAT
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_rate DECIMAL(5, 4) DEFAULT 0, -- e.g., 0.20 for 20%
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON public.purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_payment_status ON public.purchases(payment_status);
CREATE INDEX IF NOT EXISTS idx_purchases_created_at ON public.purchases(created_at DESC);

-- ============================================
-- 5. CREDIT TRANSACTIONS TABLE (Now can reference purchases)
-- ============================================
CREATE TABLE IF NOT EXISTS public.credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Transaction Details
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('purchase', 'usage', 'refund', 'adjustment', 'bonus', 'subscription_credit')),
    amount DECIMAL(10, 2) NOT NULL, -- Positive for credits added, negative for usage
    
    -- Usage Details (for usage transactions)
    agent_id UUID REFERENCES public.voice_agents(id) ON DELETE SET NULL,
    call_id UUID REFERENCES public.call_history(id) ON DELETE SET NULL,
    call_duration_seconds INTEGER,
    credits_per_minute DECIMAL(10, 4) DEFAULT 0.10, -- Cost per minute
    
    -- Purchase Details (for purchase transactions)
    purchase_id UUID REFERENCES public.purchases(id) ON DELETE SET NULL,
    
    -- Balance Tracking
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    
    -- Description
    description TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_id ON public.credit_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_transaction_type ON public.credit_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created_at ON public.credit_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_agent_id ON public.credit_transactions(agent_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_call_id ON public.credit_transactions(call_id);

-- ============================================
-- 6. INVOICES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Invoice Details
    invoice_number VARCHAR(50) UNIQUE NOT NULL, -- e.g., INV-2024-001
    invoice_date DATE NOT NULL,
    due_date DATE,
    
    -- Related Records
    purchase_id UUID REFERENCES public.purchases(id),
    subscription_id UUID REFERENCES public.user_subscriptions(id),
    
    -- Amounts
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_rate DECIMAL(5, 4) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    paid_at TIMESTAMPTZ,
    
    -- Billing Address
    billing_address JSONB, -- {street, city, state, zip, country}
    
    -- Invoice Items
    items JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of invoice line items
    
    -- PDF Generation
    pdf_url TEXT, -- URL to generated PDF
    pdf_generated_at TIMESTAMPTZ,
    
    -- Email
    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON public.invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_date ON public.invoices(invoice_date DESC);

-- ============================================
-- 7. TAX CONFIGURATION TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.tax_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Tax Details
    country_code VARCHAR(2) NOT NULL, -- ISO country code
    state_code VARCHAR(10), -- State/province code (optional)
    tax_name VARCHAR(100) NOT NULL, -- e.g., 'VAT', 'GST', 'Sales Tax'
    tax_rate DECIMAL(5, 4) NOT NULL, -- e.g., 0.20 for 20%
    
    -- Applicability
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(country_code, state_code)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tax_configuration_country_code ON public.tax_configuration(country_code);
CREATE INDEX IF NOT EXISTS idx_tax_configuration_is_default ON public.tax_configuration(is_default);

-- ============================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.subscription_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_configuration ENABLE ROW LEVEL SECURITY;

-- Subscription Packages - Public read for active packages
CREATE POLICY "Anyone can view active subscription packages"
    ON public.subscription_packages FOR SELECT
    USING (is_active = true AND deleted_at IS NULL);

-- User Subscriptions
CREATE POLICY "Users can view their own subscriptions"
    ON public.user_subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions"
    ON public.user_subscriptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscriptions"
    ON public.user_subscriptions FOR UPDATE
    USING (auth.uid() = user_id);

-- User Credits
CREATE POLICY "Users can view their own credits"
    ON public.user_credits FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own credits"
    ON public.user_credits FOR UPDATE
    USING (auth.uid() = user_id);

-- Credit Transactions
CREATE POLICY "Users can view their own credit transactions"
    ON public.credit_transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own credit transactions"
    ON public.credit_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Purchases
CREATE POLICY "Users can view their own purchases"
    ON public.purchases FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own purchases"
    ON public.purchases FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own purchases"
    ON public.purchases FOR UPDATE
    USING (auth.uid() = user_id);

-- Invoices
CREATE POLICY "Users can view their own invoices"
    ON public.invoices FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own invoices"
    ON public.invoices FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Tax Configuration - Public read
CREATE POLICY "Anyone can view tax configuration"
    ON public.tax_configuration FOR SELECT
    USING (is_active = true);

-- ============================================
-- 9. TRIGGERS
-- ============================================

-- Trigger for updated_at on all tables
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_subscription_packages_updated_at BEFORE UPDATE ON public.subscription_packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_credits_updated_at BEFORE UPDATE ON public.user_credits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tax_configuration_updated_at BEFORE UPDATE ON public.tax_configuration
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 10. HELPER FUNCTIONS
-- ============================================

-- Function to deduct credits for a call
-- 1 minute AI call = 3 credits
CREATE OR REPLACE FUNCTION deduct_call_credits(
    p_user_id UUID,
    p_call_id UUID,
    p_agent_id UUID,
    p_duration_seconds INTEGER,
    p_credits_per_minute DECIMAL DEFAULT 3.0
)
RETURNS DECIMAL AS $$
DECLARE
    v_credits_to_deduct DECIMAL(10, 2);
    v_current_balance DECIMAL(10, 2);
    v_new_balance DECIMAL(10, 2);
BEGIN
    -- Calculate credits to deduct: 3 credits per minute
    v_credits_to_deduct := (p_duration_seconds::DECIMAL / 60.0) * p_credits_per_minute;
    
    -- Get current balance
    SELECT balance INTO v_current_balance
    FROM public.user_credits
    WHERE user_id = p_user_id;
    
    -- If no credits record exists, create one
    IF v_current_balance IS NULL THEN
        INSERT INTO public.user_credits (user_id, balance, total_used)
        VALUES (p_user_id, 0, 0)
        ON CONFLICT (user_id) DO NOTHING;
        v_current_balance := 0;
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_current_balance - v_credits_to_deduct;
    
    -- Update credits
    UPDATE public.user_credits
    SET 
        balance = v_new_balance,
        total_used = total_used + v_credits_to_deduct,
        services_paused = CASE WHEN v_new_balance <= 0 THEN true ELSE services_paused END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Record transaction
    INSERT INTO public.credit_transactions (
        user_id,
        transaction_type,
        amount,
        agent_id,
        call_id,
        call_duration_seconds,
        credits_per_minute,
        balance_before,
        balance_after,
        description
    ) VALUES (
        p_user_id,
        'usage',
        -v_credits_to_deduct,
        p_agent_id,
        p_call_id,
        p_duration_seconds,
        p_credits_per_minute,
        v_current_balance,
        v_new_balance,
        'Call usage: ' || p_duration_seconds || ' seconds (' || ROUND(p_duration_seconds::DECIMAL / 60.0, 2) || ' minutes)'
    );
    
    RETURN v_credits_to_deduct;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to deduct credits for agent creation
-- Create 1 agent = 5 credits
CREATE OR REPLACE FUNCTION deduct_agent_creation_credits(
    p_user_id UUID,
    p_agent_id UUID,
    p_agent_name VARCHAR
)
RETURNS DECIMAL AS $$
DECLARE
    v_credits_to_deduct DECIMAL(10, 2) := 5.0; -- 5 credits per agent
    v_current_balance DECIMAL(10, 2);
    v_new_balance DECIMAL(10, 2);
BEGIN
    -- Get current balance
    SELECT balance INTO v_current_balance
    FROM public.user_credits
    WHERE user_id = p_user_id;
    
    -- If no credits record exists, create one
    IF v_current_balance IS NULL THEN
        INSERT INTO public.user_credits (user_id, balance, total_used)
        VALUES (p_user_id, 0, 0)
        ON CONFLICT (user_id) DO NOTHING;
        v_current_balance := 0;
    END IF;
    
    -- Check if user has enough credits
    IF v_current_balance < v_credits_to_deduct THEN
        RAISE EXCEPTION 'Insufficient credits. Creating an agent requires 5 credits. Current balance: %', v_current_balance;
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_current_balance - v_credits_to_deduct;
    
    -- Update credits
    UPDATE public.user_credits
    SET 
        balance = v_new_balance,
        total_used = total_used + v_credits_to_deduct,
        services_paused = CASE WHEN v_new_balance <= 0 THEN true ELSE services_paused END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Record transaction
    INSERT INTO public.credit_transactions (
        user_id,
        transaction_type,
        amount,
        agent_id,
        balance_before,
        balance_after,
        description
    ) VALUES (
        p_user_id,
        'usage',
        -v_credits_to_deduct,
        p_agent_id,
        v_current_balance,
        v_new_balance,
        'Agent creation: ' || p_agent_name || ' (5 credits)'
    );
    
    RETURN v_credits_to_deduct;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add credits
CREATE OR REPLACE FUNCTION add_credits(
    p_user_id UUID,
    p_amount DECIMAL,
    p_transaction_type VARCHAR DEFAULT 'purchase',
    p_purchase_id UUID DEFAULT NULL
)
RETURNS DECIMAL AS $$
DECLARE
    v_current_balance DECIMAL(10, 2);
    v_new_balance DECIMAL(10, 2);
    v_description TEXT;
BEGIN
    -- Get or create credits record
    INSERT INTO public.user_credits (user_id, balance, total_purchased)
    VALUES (p_user_id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Get current balance
    SELECT balance INTO v_current_balance
    FROM public.user_credits
    WHERE user_id = p_user_id;
    
    -- Calculate new balance
    v_new_balance := v_current_balance + p_amount;
    
    -- Set description based on transaction type
    IF p_transaction_type = 'subscription_credit' THEN
        v_description := 'Monthly subscription credits: ' || p_amount || ' credits';
    ELSE
        v_description := 'Credit purchase: ' || p_amount || ' credits';
    END IF;
    
    -- Update credits (only update total_purchased for purchases, not subscription credits)
    IF p_transaction_type = 'purchase' THEN
        UPDATE public.user_credits
        SET 
            balance = v_new_balance,
            total_purchased = total_purchased + p_amount,
            services_paused = false, -- Unpause services
            last_topup_at = NOW(),
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSE
        UPDATE public.user_credits
        SET 
            balance = v_new_balance,
            services_paused = false, -- Unpause services
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;
    
    -- Record transaction
    INSERT INTO public.credit_transactions (
        user_id,
        transaction_type,
        amount,
        purchase_id,
        balance_before,
        balance_after,
        description
    ) VALUES (
        p_user_id,
        p_transaction_type,
        p_amount,
        p_purchase_id,
        v_current_balance,
        v_new_balance,
        v_description
    );
    
    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add monthly subscription credits
-- Credits roll over, so we add to existing balance
CREATE OR REPLACE FUNCTION add_monthly_subscription_credits(
    p_user_id UUID,
    p_subscription_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
    v_monthly_credits DECIMAL(10, 2);
    v_package_id UUID;
BEGIN
    -- Get package_id from subscription
    SELECT package_id INTO v_package_id
    FROM public.user_subscriptions
    WHERE id = p_subscription_id AND user_id = p_user_id;
    
    IF v_package_id IS NULL THEN
        RAISE EXCEPTION 'Subscription not found';
    END IF;
    
    -- Get monthly credits from package
    SELECT monthly_credits INTO v_monthly_credits
    FROM public.subscription_packages
    WHERE id = v_package_id;
    
    IF v_monthly_credits IS NULL OR v_monthly_credits <= 0 THEN
        RETURN 0; -- No credits to add
    END IF;
    
    -- Add credits using the add_credits function
    PERFORM add_credits(
        p_user_id,
        v_monthly_credits,
        'subscription_credit',
        NULL
    );
    
    RETURN v_monthly_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can make calls (has credits and active subscription)
CREATE OR REPLACE FUNCTION can_user_make_calls(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_credit_balance DECIMAL(10, 2);
    v_subscription_status VARCHAR(20);
BEGIN
    -- Check credit balance
    SELECT balance INTO v_credit_balance
    FROM public.user_credits
    WHERE user_id = p_user_id;
    
    -- Check subscription status
    SELECT status INTO v_subscription_status
    FROM public.user_subscriptions
    WHERE user_id = p_user_id
        AND status = 'active'
        AND current_period_end > NOW()
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- User can make calls if they have credits and active subscription
    RETURN (v_credit_balance > 0 OR v_credit_balance IS NULL) 
        AND (v_subscription_status = 'active' OR v_subscription_status IS NULL);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS VARCHAR(50) AS $$
DECLARE
    v_year VARCHAR(4);
    v_sequence INTEGER;
    v_invoice_number VARCHAR(50);
BEGIN
    v_year := TO_CHAR(NOW(), 'YYYY');
    
    -- Get next sequence number for this year
    SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM public.invoices
    WHERE invoice_number LIKE 'INV-' || v_year || '-%';
    
    v_invoice_number := 'INV-' || v_year || '-' || LPAD(v_sequence::TEXT, 6, '0');
    
    RETURN v_invoice_number;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 11. INITIAL DATA
-- ============================================

-- Insert default subscription packages
INSERT INTO public.subscription_packages (package_name, package_code, description, monthly_price, max_agents, max_inbound_numbers, monthly_call_minutes, monthly_credits, is_featured) VALUES
('Genie', 'genie', 'Perfect for getting started with AI voice agents', 10.00, 1, 1, 0, 50.00, true),
('Starter', 'starter', 'Perfect for small businesses getting started', 29.99, 1, 1, 500, 150.00, false),
('Professional', 'professional', 'For growing businesses with multiple agents', 99.99, 5, 5, 2000, 500.00, false),
('Enterprise', 'enterprise', 'Unlimited everything for large organizations', 299.99, 999, 999, 0, 1500.00, false)
ON CONFLICT (package_code) DO NOTHING;

-- Insert default tax configuration (example: 20% VAT for EU)
INSERT INTO public.tax_configuration (country_code, tax_name, tax_rate, is_default) VALUES
('US', 'Sales Tax', 0.00, true), -- Default no tax
('GB', 'VAT', 0.20, false),
('DE', 'VAT', 0.19, false),
('FR', 'VAT', 0.20, false)
ON CONFLICT (country_code, state_code) DO NOTHING;

-- ============================================
-- 12. COMMENTS
-- ============================================

COMMENT ON TABLE public.subscription_packages IS 'Available subscription packages with limits and pricing';
COMMENT ON TABLE public.user_subscriptions IS 'User subscription records and billing cycles';
COMMENT ON TABLE public.user_credits IS 'User credit balance and auto-topup settings';
COMMENT ON TABLE public.credit_transactions IS 'All credit transactions (purchases, usage, refunds)';
COMMENT ON TABLE public.purchases IS 'Credit purchase records and payment tracking';
COMMENT ON TABLE public.invoices IS 'Generated invoices for purchases and subscriptions';
COMMENT ON TABLE public.tax_configuration IS 'Tax/VAT rates by country and state';
COMMENT ON FUNCTION deduct_call_credits IS 'Deducts credits for call usage (3 credits per minute)';
COMMENT ON FUNCTION deduct_agent_creation_credits IS 'Deducts credits for agent creation (5 credits per agent)';
COMMENT ON FUNCTION add_credits IS 'Adds credits to user account (supports purchase and subscription_credit types)';
COMMENT ON FUNCTION add_monthly_subscription_credits IS 'Adds monthly subscription credits to user account (credits roll over)';