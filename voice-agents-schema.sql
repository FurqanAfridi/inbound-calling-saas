-- ============================================
-- Voice Agents Database Schema
-- ============================================
-- This file contains the database tables for storing AI voice agent configurations
-- Run this in your Supabase SQL Editor

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. VOICE AGENTS TABLE
-- ============================================
-- Main table for storing voice agent configurations
CREATE TABLE IF NOT EXISTS public.voice_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic Information
    name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    website_url TEXT,
    
    -- Agent Configuration
    goal TEXT NOT NULL,
    background TEXT NOT NULL,
    welcome_message TEXT NOT NULL,
    instruction_voice TEXT NOT NULL,
    script TEXT NOT NULL,
    
    -- Voice Settings
    voice VARCHAR(100) DEFAULT 'aura-helena-en',
    tone VARCHAR(50) DEFAULT 'professional',
    model VARCHAR(50) DEFAULT 'gpt-4o',
    background_noise VARCHAR(50) DEFAULT 'office',
    language VARCHAR(10) DEFAULT 'en-US',
    
    -- Agent Type & Tools
    agent_type VARCHAR(50) CHECK (agent_type IN ('sales', 'support', 'booking', 'general')),
    tool VARCHAR(50) CHECK (tool IN ('calendar', 'crm', 'email', 'sms')),
    timezone VARCHAR(100),
    
    -- Phone Provider Configuration
    phone_provider VARCHAR(50) CHECK (phone_provider IN ('twilio', 'vonage', 'telnyx')),
    phone_number VARCHAR(20) NOT NULL,
    phone_label VARCHAR(255),
    
    -- Twilio Credentials (encrypted in production)
    twilio_sid VARCHAR(255),
    twilio_auth_token TEXT,
    sms_enabled BOOLEAN DEFAULT false,
    
    -- Vonage Credentials (encrypted in production)
    vonage_api_key VARCHAR(255),
    vonage_api_secret TEXT,
    
    -- Telnyx Credentials (encrypted in production)
    telnyx_api_key TEXT,
    
    -- Status & Metadata
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived', 'testing')),
    vapi_id VARCHAR(255),
    vapi_account_assigned INTEGER,
    account_in_use BOOLEAN DEFAULT false,
    voice_provider VARCHAR(50) DEFAULT 'deepgram',
    execution_mode VARCHAR(20) DEFAULT 'production',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for voice_agents
CREATE INDEX IF NOT EXISTS idx_voice_agents_user_id ON public.voice_agents(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_agents_status ON public.voice_agents(status);
CREATE INDEX IF NOT EXISTS idx_voice_agents_phone_number ON public.voice_agents(phone_number);
CREATE INDEX IF NOT EXISTS idx_voice_agents_created_at ON public.voice_agents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_voice_agents_deleted_at ON public.voice_agents(deleted_at) WHERE deleted_at IS NOT NULL;

-- ============================================
-- 2. AGENT CALLS TABLE
-- ============================================
-- Tracks all calls made to/from voice agents
CREATE TABLE IF NOT EXISTS public.agent_calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES public.voice_agents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Call Information
    caller_number VARCHAR(20),
    called_number VARCHAR(20),
    direction VARCHAR(10) CHECK (direction IN ('inbound', 'outbound')),
    status VARCHAR(20) CHECK (status IN ('initiated', 'ringing', 'answered', 'completed', 'failed', 'busy', 'no-answer')),
    
    -- Call Metrics
    duration INTEGER DEFAULT 0, -- in seconds
    recording_url TEXT,
    transcript TEXT,
    
    -- Provider Information
    provider VARCHAR(50),
    provider_call_id VARCHAR(255),
    
    -- Timestamps
    started_at TIMESTAMPTZ,
    answered_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Additional data
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for agent_calls
CREATE INDEX IF NOT EXISTS idx_agent_calls_agent_id ON public.agent_calls(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_calls_user_id ON public.agent_calls(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_calls_status ON public.agent_calls(status);
CREATE INDEX IF NOT EXISTS idx_agent_calls_started_at ON public.agent_calls(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_agent_calls_caller_number ON public.agent_calls(caller_number);

-- ============================================
-- 3. AGENT ANALYTICS TABLE
-- ============================================
-- Stores aggregated analytics for agents
CREATE TABLE IF NOT EXISTS public.agent_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES public.voice_agents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Date range
    date DATE NOT NULL,
    period VARCHAR(20) CHECK (period IN ('hour', 'day', 'week', 'month')),
    
    -- Metrics
    total_calls INTEGER DEFAULT 0,
    answered_calls INTEGER DEFAULT 0,
    missed_calls INTEGER DEFAULT 0,
    total_duration INTEGER DEFAULT 0, -- in seconds
    average_duration DECIMAL(10, 2) DEFAULT 0,
    
    -- Conversion metrics
    conversions INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5, 2) DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(agent_id, date, period)
);

-- Indexes for agent_analytics
CREATE INDEX IF NOT EXISTS idx_agent_analytics_agent_id ON public.agent_analytics(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_analytics_user_id ON public.agent_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_analytics_date ON public.agent_analytics(date DESC);

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.voice_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_analytics ENABLE ROW LEVEL SECURITY;

-- Voice Agents Policies
CREATE POLICY "Users can view their own agents"
    ON public.voice_agents FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own agents"
    ON public.voice_agents FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own agents"
    ON public.voice_agents FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own agents"
    ON public.voice_agents FOR DELETE
    USING (auth.uid() = user_id);

-- Agent Calls Policies
CREATE POLICY "Users can view their own agent calls"
    ON public.agent_calls FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create calls for their agents"
    ON public.agent_calls FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Agent Analytics Policies
CREATE POLICY "Users can view their own agent analytics"
    ON public.agent_analytics FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================
-- 5. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_voice_agent_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER update_voice_agents_updated_at
    BEFORE UPDATE ON public.voice_agents
    FOR EACH ROW EXECUTE FUNCTION public.update_voice_agent_updated_at();

-- Function to update analytics when call is completed
CREATE OR REPLACE FUNCTION public.update_agent_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_agent_id UUID;
    v_user_id UUID;
    v_date DATE;
    v_duration INTEGER;
BEGIN
    -- Only process completed calls
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        v_agent_id := NEW.agent_id;
        v_user_id := NEW.user_id;
        v_date := DATE(NEW.ended_at);
        v_duration := NEW.duration;
        
        -- Update or insert analytics
        INSERT INTO public.agent_analytics (
            agent_id, user_id, date, period,
            total_calls, answered_calls, total_duration
        ) VALUES (
            v_agent_id, v_user_id, v_date, 'day',
            1, 1, v_duration
        )
        ON CONFLICT (agent_id, date, period)
        DO UPDATE SET
            total_calls = agent_analytics.total_calls + 1,
            answered_calls = agent_analytics.answered_calls + 1,
            total_duration = agent_analytics.total_duration + v_duration,
            average_duration = (agent_analytics.total_duration + v_duration)::DECIMAL / (agent_analytics.answered_calls + 1),
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for analytics update
CREATE TRIGGER update_analytics_on_call_complete
    AFTER UPDATE ON public.agent_calls
    FOR EACH ROW EXECUTE FUNCTION public.update_agent_analytics();

-- ============================================
-- 6. VIEWS FOR COMMON QUERIES
-- ============================================

-- View for agent summary with call statistics
CREATE OR REPLACE VIEW public.agent_summary AS
SELECT 
    va.id,
    va.name,
    va.company_name,
    va.phone_number,
    va.phone_provider,
    va.status,
    va.created_at,
    va.user_id,
    COUNT(ac.id) as total_calls,
    COUNT(CASE WHEN ac.status = 'completed' THEN 1 END) as completed_calls,
    COUNT(CASE WHEN ac.status = 'answered' THEN 1 END) as answered_calls,
    COUNT(CASE WHEN ac.status = 'failed' THEN 1 END) as failed_calls,
    COALESCE(SUM(ac.duration), 0) as total_duration,
    COALESCE(AVG(ac.duration), 0) as average_duration
FROM public.voice_agents va
LEFT JOIN public.agent_calls ac ON va.id = ac.agent_id
WHERE va.deleted_at IS NULL
GROUP BY va.id, va.name, va.company_name, va.phone_number, va.phone_provider, va.status, va.created_at, va.user_id;

-- Grant access to authenticated users
GRANT SELECT ON public.agent_summary TO authenticated;

-- ============================================
-- END OF SCHEMA
-- ============================================
