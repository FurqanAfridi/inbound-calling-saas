-- ============================================
-- CALL HISTORY, MONITORING & ANALYTICS SCHEMA
-- ============================================
-- This file contains all the database tables needed for call history and analytics
-- Run this in your Supabase SQL Editor

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. CALL HISTORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.call_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES public.voice_agents(id) ON DELETE SET NULL,
    inbound_number_id UUID REFERENCES public.inbound_numbers(id) ON DELETE SET NULL,
    
    -- Call identification
    call_sid VARCHAR(255), -- Provider-specific call ID (Twilio SID, Vonage UUID, etc.)
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('twilio', 'vonage', 'callhippo', 'telnyx', 'other')),
    
    -- Call details
    caller_number VARCHAR(20) NOT NULL,
    caller_country_code VARCHAR(5),
    called_number VARCHAR(20) NOT NULL,
    called_country_code VARCHAR(5),
    
    -- Call status and timing
    call_status VARCHAR(20) NOT NULL CHECK (call_status IN ('answered', 'missed', 'forwarded', 'busy', 'failed', 'no-answer', 'canceled')),
    call_direction VARCHAR(10) NOT NULL CHECK (call_direction IN ('inbound', 'outbound')),
    call_duration INTEGER DEFAULT 0, -- Duration in seconds
    call_start_time TIMESTAMPTZ NOT NULL,
    call_end_time TIMESTAMPTZ,
    call_answered_time TIMESTAMPTZ,
    
    -- Call recordings and transcripts
    recording_url TEXT,
    recording_duration INTEGER, -- Recording duration in seconds
    transcript TEXT, -- Full call transcript
    transcript_url TEXT, -- URL to transcript file if stored separately
    speaker_separated_transcript JSONB, -- Speaker-separated transcript with timestamps
    
    -- Call metadata
    call_forwarded_to VARCHAR(20), -- If call was forwarded
    call_cost DECIMAL(10, 4), -- Call cost if available
    call_quality_score DECIMAL(3, 2), -- Quality score 0.00 to 1.00
    notes TEXT, -- User notes about the call
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for call_history
CREATE INDEX IF NOT EXISTS idx_call_history_user_id ON public.call_history(user_id);
CREATE INDEX IF NOT EXISTS idx_call_history_agent_id ON public.call_history(agent_id);
CREATE INDEX IF NOT EXISTS idx_call_history_inbound_number_id ON public.call_history(inbound_number_id);
CREATE INDEX IF NOT EXISTS idx_call_history_call_status ON public.call_history(call_status);
CREATE INDEX IF NOT EXISTS idx_call_history_call_start_time ON public.call_history(call_start_time DESC);
CREATE INDEX IF NOT EXISTS idx_call_history_call_sid ON public.call_history(call_sid);
CREATE INDEX IF NOT EXISTS idx_call_history_provider ON public.call_history(provider);
CREATE INDEX IF NOT EXISTS idx_call_history_caller_number ON public.call_history(caller_number);
CREATE INDEX IF NOT EXISTS idx_call_history_deleted_at ON public.call_history(deleted_at) WHERE deleted_at IS NULL;

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_call_history_user_time ON public.call_history(user_id, call_start_time DESC);

-- ============================================
-- 2. CALL ANALYTICS TABLE (Aggregated data for faster queries)
-- ============================================
CREATE TABLE IF NOT EXISTS public.call_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES public.voice_agents(id) ON DELETE SET NULL,
    
    -- Time period
    date DATE NOT NULL,
    hour INTEGER CHECK (hour >= 0 AND hour <= 23), -- NULL for daily aggregates, 0-23 for hourly
    
    -- Call statistics
    total_calls INTEGER DEFAULT 0,
    answered_calls INTEGER DEFAULT 0,
    missed_calls INTEGER DEFAULT 0,
    forwarded_calls INTEGER DEFAULT 0,
    failed_calls INTEGER DEFAULT 0,
    
    -- Duration statistics
    total_duration_seconds INTEGER DEFAULT 0,
    average_duration_seconds DECIMAL(10, 2) DEFAULT 0,
    min_duration_seconds INTEGER DEFAULT 0,
    max_duration_seconds INTEGER DEFAULT 0,
    
    -- Cost statistics
    total_cost DECIMAL(10, 4) DEFAULT 0,
    average_cost DECIMAL(10, 4) DEFAULT 0,
    
    -- Quality statistics
    average_quality_score DECIMAL(3, 2) DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicates
    UNIQUE(user_id, agent_id, date, hour)
);

-- Indexes for call_analytics
CREATE INDEX IF NOT EXISTS idx_call_analytics_user_id ON public.call_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_call_analytics_agent_id ON public.call_analytics(agent_id);
CREATE INDEX IF NOT EXISTS idx_call_analytics_date ON public.call_analytics(date DESC);
CREATE INDEX IF NOT EXISTS idx_call_analytics_user_date ON public.call_analytics(user_id, date DESC);

-- ============================================
-- 3. CALL RECORDINGS TABLE (Separate table for better organization)
-- ============================================
CREATE TABLE IF NOT EXISTS public.call_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_history_id UUID NOT NULL REFERENCES public.call_history(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Recording details
    recording_url TEXT NOT NULL,
    recording_duration INTEGER, -- Duration in seconds
    file_size_bytes BIGINT, -- File size in bytes
    file_format VARCHAR(10) DEFAULT 'mp3', -- mp3, wav, etc.
    storage_provider VARCHAR(50), -- s3, supabase, etc.
    storage_path TEXT, -- Path in storage provider
    
    -- Transcript details
    transcript_available BOOLEAN DEFAULT false,
    transcript_url TEXT,
    speaker_separated BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for call_recordings
CREATE INDEX IF NOT EXISTS idx_call_recordings_call_history_id ON public.call_recordings(call_history_id);
CREATE INDEX IF NOT EXISTS idx_call_recordings_user_id ON public.call_recordings(user_id);
CREATE INDEX IF NOT EXISTS idx_call_recordings_deleted_at ON public.call_recordings(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.call_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_recordings ENABLE ROW LEVEL SECURITY;

-- Call History Policies
CREATE POLICY "Users can view their own call history"
    ON public.call_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own call history"
    ON public.call_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own call history"
    ON public.call_history FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own call history (soft delete)"
    ON public.call_history FOR UPDATE
    USING (auth.uid() = user_id AND deleted_at IS NULL);

-- Call Analytics Policies
CREATE POLICY "Users can view their own call analytics"
    ON public.call_analytics FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own call analytics"
    ON public.call_analytics FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own call analytics"
    ON public.call_analytics FOR UPDATE
    USING (auth.uid() = user_id);

-- Call Recordings Policies
CREATE POLICY "Users can view their own call recordings"
    ON public.call_recordings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own call recordings"
    ON public.call_recordings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own call recordings"
    ON public.call_recordings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own call recordings (soft delete)"
    ON public.call_recordings FOR UPDATE
    USING (auth.uid() = user_id AND deleted_at IS NULL);

-- ============================================
-- 5. TRIGGERS
-- ============================================

-- Trigger for updated_at on call_history
CREATE OR REPLACE FUNCTION update_call_history_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_call_history_updated_at BEFORE UPDATE ON public.call_history
    FOR EACH ROW EXECUTE FUNCTION update_call_history_updated_at();

-- Trigger for updated_at on call_analytics
CREATE OR REPLACE FUNCTION update_call_analytics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_call_analytics_updated_at BEFORE UPDATE ON public.call_analytics
    FOR EACH ROW EXECUTE FUNCTION update_call_analytics_updated_at();

-- Trigger for updated_at on call_recordings
CREATE OR REPLACE FUNCTION update_call_recordings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_call_recordings_updated_at BEFORE UPDATE ON public.call_recordings
    FOR EACH ROW EXECUTE FUNCTION update_call_recordings_updated_at();

-- ============================================
-- 6. HELPER FUNCTIONS
-- ============================================

-- Function to get call statistics for a date range
CREATE OR REPLACE FUNCTION get_call_statistics(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_agent_id UUID DEFAULT NULL
)
RETURNS TABLE (
    total_calls BIGINT,
    answered_calls BIGINT,
    missed_calls BIGINT,
    forwarded_calls BIGINT,
    failed_calls BIGINT,
    total_duration_seconds BIGINT,
    average_duration_seconds NUMERIC,
    total_cost NUMERIC,
    average_cost NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT as total_calls,
        COUNT(*) FILTER (WHERE call_status = 'answered')::BIGINT as answered_calls,
        COUNT(*) FILTER (WHERE call_status = 'missed')::BIGINT as missed_calls,
        COUNT(*) FILTER (WHERE call_status = 'forwarded')::BIGINT as forwarded_calls,
        COUNT(*) FILTER (WHERE call_status = 'failed')::BIGINT as failed_calls,
        COALESCE(SUM(call_duration), 0)::BIGINT as total_duration_seconds,
        COALESCE(AVG(call_duration), 0)::NUMERIC as average_duration_seconds,
        COALESCE(SUM(call_cost), 0)::NUMERIC as total_cost,
        COALESCE(AVG(call_cost), 0)::NUMERIC as average_cost
    FROM public.call_history
    WHERE user_id = p_user_id
        AND DATE(call_start_time) BETWEEN p_start_date AND p_end_date
        AND deleted_at IS NULL
        AND (p_agent_id IS NULL OR agent_id = p_agent_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get calls per day for analytics
CREATE OR REPLACE FUNCTION get_calls_per_day(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_agent_id UUID DEFAULT NULL
)
RETURNS TABLE (
    date DATE,
    total_calls BIGINT,
    answered_calls BIGINT,
    missed_calls BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(call_start_time) as date,
        COUNT(*)::BIGINT as total_calls,
        COUNT(*) FILTER (WHERE call_status = 'answered')::BIGINT as answered_calls,
        COUNT(*) FILTER (WHERE call_status = 'missed')::BIGINT as missed_calls
    FROM public.call_history
    WHERE user_id = p_user_id
        AND DATE(call_start_time) BETWEEN p_start_date AND p_end_date
        AND deleted_at IS NULL
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
    GROUP BY DATE(call_start_time)
    ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get peak call hours
CREATE OR REPLACE FUNCTION get_peak_call_hours(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_agent_id UUID DEFAULT NULL
)
RETURNS TABLE (
    hour INTEGER,
    call_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(HOUR FROM call_start_time)::INTEGER as hour,
        COUNT(*)::BIGINT as call_count
    FROM public.call_history
    WHERE user_id = p_user_id
        AND DATE(call_start_time) BETWEEN p_start_date AND p_end_date
        AND deleted_at IS NULL
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
    GROUP BY EXTRACT(HOUR FROM call_start_time)
    ORDER BY call_count DESC, hour;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. COMMENTS
-- ============================================

COMMENT ON TABLE public.call_history IS 'Stores detailed inbound and outbound call history with recordings and transcripts';
COMMENT ON TABLE public.call_analytics IS 'Aggregated call analytics data for faster dashboard queries';
COMMENT ON TABLE public.call_recordings IS 'Stores call recording metadata and URLs';
COMMENT ON FUNCTION get_call_statistics IS 'Returns call statistics for a given date range';
COMMENT ON FUNCTION get_calls_per_day IS 'Returns calls per day for analytics dashboard';
COMMENT ON FUNCTION get_peak_call_hours IS 'Returns peak call hours for analytics dashboard';
