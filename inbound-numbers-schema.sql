-- Inbound Numbers Management Schema
-- This table stores inbound phone numbers imported from various providers

CREATE TABLE IF NOT EXISTS public.inbound_numbers (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL,
  
  -- Phone Number Details
  phone_number VARCHAR(20) NOT NULL,
  country_code VARCHAR(10) NOT NULL DEFAULT '+1',
  phone_label VARCHAR(255) NULL,
  call_forwarding_number VARCHAR(20) NULL, -- Number to forward calls to
  
  -- Provider Information
  provider VARCHAR(50) NOT NULL,
  provider_account_id VARCHAR(255) NULL, -- Provider's account/workspace ID if applicable
  
  -- Provider-Specific Configuration
  -- Twilio Configuration
  twilio_sid VARCHAR(255) NULL,
  twilio_auth_token TEXT NULL,
  twilio_account_sid VARCHAR(255) NULL,
  sms_enabled BOOLEAN NULL DEFAULT false,
  
  -- Vonage Configuration
  vonage_api_key VARCHAR(255) NULL,
  vonage_api_secret TEXT NULL,
  vonage_application_id VARCHAR(255) NULL,
  
  -- CallHippo Configuration
  callhippo_api_key TEXT NULL,
  callhippo_account_id VARCHAR(255) NULL,
  
  -- Generic Provider Configuration (for other providers)
  provider_api_key TEXT NULL,
  provider_api_secret TEXT NULL,
  provider_webhook_url TEXT NULL,
  provider_config JSONB NULL DEFAULT '{}'::jsonb, -- Flexible JSON for provider-specific settings
  
  -- Status and Health
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'suspended', 'error', 'pending', 'inactive')
  ),
  health_status VARCHAR(20) NULL DEFAULT 'unknown' CHECK (
    health_status IN ('healthy', 'unhealthy', 'unknown', 'testing')
  ),
  last_health_check TIMESTAMP WITH TIME ZONE NULL,
  health_check_error TEXT NULL,
  
  -- Webhook Configuration
  webhook_url TEXT NULL,
  webhook_status VARCHAR(20) NULL DEFAULT 'unknown' CHECK (
    webhook_status IN ('active', 'inactive', 'error', 'unknown')
  ),
  last_webhook_test TIMESTAMP WITH TIME ZONE NULL,
  webhook_test_result JSONB NULL,
  
  -- Assignment and Usage
  assigned_to_agent_id UUID NULL, -- Currently assigned agent (can be null if not assigned)
  is_in_use BOOLEAN NULL DEFAULT false,
  
  -- Metadata
  metadata JSONB NULL DEFAULT '{}'::jsonb,
  notes TEXT NULL,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE NULL,
  
  -- Constraints
  CONSTRAINT inbound_numbers_pkey PRIMARY KEY (id),
  CONSTRAINT inbound_numbers_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT inbound_numbers_assigned_to_agent_id_fkey FOREIGN KEY (assigned_to_agent_id) 
    REFERENCES public.voice_agents(id) ON DELETE SET NULL,
  CONSTRAINT inbound_numbers_provider_check CHECK (
    provider IN ('twilio', 'vonage', 'callhippo', 'telnyx', 'other')
  ),
  -- Ensure unique phone number per user (unless deleted)
  CONSTRAINT inbound_numbers_user_phone_unique UNIQUE NULLS NOT DISTINCT (user_id, phone_number, deleted_at)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_inbound_numbers_user_id 
  ON public.inbound_numbers(user_id) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inbound_numbers_status 
  ON public.inbound_numbers(status) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inbound_numbers_provider 
  ON public.inbound_numbers(provider) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inbound_numbers_assigned_to_agent 
  ON public.inbound_numbers(assigned_to_agent_id) 
  WHERE deleted_at IS NULL AND assigned_to_agent_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_inbound_numbers_phone_number 
  ON public.inbound_numbers(phone_number) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inbound_numbers_created_at 
  ON public.inbound_numbers(created_at DESC) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inbound_numbers_deleted_at 
  ON public.inbound_numbers(deleted_at) 
  WHERE deleted_at IS NOT NULL;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_inbound_number_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_inbound_numbers_updated_at
  BEFORE UPDATE ON public.inbound_numbers
  FOR EACH ROW
  EXECUTE FUNCTION update_inbound_number_updated_at();

-- RLS (Row Level Security) Policies
ALTER TABLE public.inbound_numbers ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own inbound numbers
CREATE POLICY "Users can view own inbound numbers"
  ON public.inbound_numbers
  FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);

-- Policy: Users can insert their own inbound numbers
CREATE POLICY "Users can insert own inbound numbers"
  ON public.inbound_numbers
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own inbound numbers
CREATE POLICY "Users can update own inbound numbers"
  ON public.inbound_numbers
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete (soft delete) their own inbound numbers
CREATE POLICY "Users can delete own inbound numbers"
  ON public.inbound_numbers
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id AND deleted_at IS NOT NULL);

-- View for active inbound numbers (for easier querying)
CREATE OR REPLACE VIEW public.active_inbound_numbers AS
SELECT 
  id,
  user_id,
  phone_number,
  country_code,
  phone_label,
  call_forwarding_number,
  provider,
  status,
  health_status,
  webhook_status,
  assigned_to_agent_id,
  is_in_use,
  created_at,
  updated_at
FROM public.inbound_numbers
WHERE deleted_at IS NULL
  AND status = 'active';

-- Comments for documentation
COMMENT ON TABLE public.inbound_numbers IS 'Stores inbound phone numbers imported from various providers';
COMMENT ON COLUMN public.inbound_numbers.call_forwarding_number IS 'Phone number to forward incoming calls to';
COMMENT ON COLUMN public.inbound_numbers.provider_config IS 'Flexible JSON field for provider-specific configuration';
COMMENT ON COLUMN public.inbound_numbers.health_status IS 'Current health status of the number (healthy, unhealthy, unknown, testing)';
COMMENT ON COLUMN public.inbound_numbers.webhook_status IS 'Status of webhook connectivity for this number';
COMMENT ON COLUMN public.inbound_numbers.assigned_to_agent_id IS 'Currently assigned voice agent (can be null if unassigned)';
