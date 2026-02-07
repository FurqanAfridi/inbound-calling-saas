-- ============================================
-- Call Scheduling & Availability Schema
-- ============================================
-- This schema supports configurable call schedules, availability templates,
-- holidays, and after-hours messaging

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. CALL SCHEDULES TABLE
-- ============================================
-- Main schedule configuration per agent/user
CREATE TABLE IF NOT EXISTS public.call_schedules (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  agent_id UUID NULL, -- If null, applies to all user's agents
  schedule_name VARCHAR(255) NOT NULL,
  timezone VARCHAR(100) NOT NULL DEFAULT 'America/New_York',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL,
  
  CONSTRAINT call_schedules_pkey PRIMARY KEY (id),
  CONSTRAINT call_schedules_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT call_schedules_agent_id_fkey FOREIGN KEY (agent_id) 
    REFERENCES public.voice_agents(id) ON DELETE CASCADE
);

-- ============================================
-- 2. WEEKLY AVAILABILITY TABLE
-- ============================================
-- Weekly availability templates (Monday-Sunday)
CREATE TABLE IF NOT EXISTS public.weekly_availability (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  schedule_id UUID NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 1=Monday, ..., 6=Saturday
  is_available BOOLEAN NOT NULL DEFAULT false,
  start_time TIME NOT NULL, -- e.g., '09:00:00'
  end_time TIME NOT NULL, -- e.g., '17:00:00'
  break_start_time TIME NULL, -- Optional break period
  break_end_time TIME NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT weekly_availability_pkey PRIMARY KEY (id),
  CONSTRAINT weekly_availability_schedule_id_fkey FOREIGN KEY (schedule_id) 
    REFERENCES public.call_schedules(id) ON DELETE CASCADE,
  CONSTRAINT weekly_availability_day_check CHECK (end_time > start_time),
  CONSTRAINT weekly_availability_break_check CHECK (
    (break_start_time IS NULL AND break_end_time IS NULL) OR
    (break_start_time IS NOT NULL AND break_end_time IS NOT NULL AND break_end_time > break_start_time)
  ),
  CONSTRAINT weekly_availability_unique_day UNIQUE (schedule_id, day_of_week)
);

-- ============================================
-- 3. HOLIDAYS TABLE
-- ============================================
-- Holiday definitions (global or user-specific)
CREATE TABLE IF NOT EXISTS public.holidays (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  user_id UUID NULL, -- NULL = global holiday, otherwise user-specific
  holiday_name VARCHAR(255) NOT NULL,
  holiday_date DATE NOT NULL,
  is_recurring BOOLEAN NOT NULL DEFAULT false, -- Recurring annually
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL,
  
  CONSTRAINT holidays_pkey PRIMARY KEY (id),
  CONSTRAINT holidays_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ============================================
-- 4. HOLIDAY MESSAGES TABLE
-- ============================================
-- Holiday-specific messages
CREATE TABLE IF NOT EXISTS public.holiday_messages (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  holiday_id UUID NOT NULL,
  message_text TEXT NOT NULL,
  message_type VARCHAR(50) NOT NULL DEFAULT 'greeting' CHECK (
    message_type IN ('greeting', 'voicemail', 'redirect')
  ),
  redirect_phone_number VARCHAR(20) NULL, -- If message_type is 'redirect'
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT holiday_messages_pkey PRIMARY KEY (id),
  CONSTRAINT holiday_messages_holiday_id_fkey FOREIGN KEY (holiday_id) 
    REFERENCES public.holidays(id) ON DELETE CASCADE
);

-- ============================================
-- 5. AFTER HOURS MESSAGES TABLE
-- ============================================
-- After-hours message configuration
CREATE TABLE IF NOT EXISTS public.after_hours_messages (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  schedule_id UUID NOT NULL,
  message_text TEXT NOT NULL,
  message_type VARCHAR(50) NOT NULL DEFAULT 'voicemail' CHECK (
    message_type IN ('voicemail', 'redirect', 'callback_request')
  ),
  redirect_phone_number VARCHAR(20) NULL,
  callback_enabled BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT after_hours_messages_pkey PRIMARY KEY (id),
  CONSTRAINT after_hours_messages_schedule_id_fkey FOREIGN KEY (schedule_id) 
    REFERENCES public.call_schedules(id) ON DELETE CASCADE,
  CONSTRAINT after_hours_messages_schedule_unique UNIQUE (schedule_id)
);

-- ============================================
-- 6. SCHEDULE OVERRIDES TABLE
-- ============================================
-- Date-specific schedule overrides
CREATE TABLE IF NOT EXISTS public.schedule_overrides (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  schedule_id UUID NOT NULL,
  override_date DATE NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT false,
  start_time TIME NULL, -- NULL means use default schedule
  end_time TIME NULL,
  override_reason VARCHAR(255) NULL,
  message_text TEXT NULL, -- Custom message for this override
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT schedule_overrides_pkey PRIMARY KEY (id),
  CONSTRAINT schedule_overrides_schedule_id_fkey FOREIGN KEY (schedule_id) 
    REFERENCES public.call_schedules(id) ON DELETE CASCADE,
  CONSTRAINT schedule_overrides_date_check CHECK (
    (start_time IS NULL AND end_time IS NULL) OR
    (start_time IS NOT NULL AND end_time IS NOT NULL AND end_time > start_time)
  ),
  CONSTRAINT schedule_overrides_unique_date UNIQUE (schedule_id, override_date)
);

-- ============================================
-- INDEXES
-- ============================================

-- Call Schedules Indexes
CREATE INDEX IF NOT EXISTS idx_call_schedules_user_id 
  ON public.call_schedules(user_id) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_call_schedules_agent_id 
  ON public.call_schedules(agent_id) 
  WHERE deleted_at IS NULL AND agent_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_call_schedules_active 
  ON public.call_schedules(is_active) 
  WHERE deleted_at IS NULL;

-- Weekly Availability Indexes
CREATE INDEX IF NOT EXISTS idx_weekly_availability_schedule_id 
  ON public.weekly_availability(schedule_id);

CREATE INDEX IF NOT EXISTS idx_weekly_availability_day 
  ON public.weekly_availability(day_of_week);

-- Holidays Indexes
CREATE INDEX IF NOT EXISTS idx_holidays_user_id 
  ON public.holidays(user_id) 
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_holidays_date 
  ON public.holidays(holiday_date) 
  WHERE deleted_at IS NULL AND is_active = true;

CREATE INDEX IF NOT EXISTS idx_holidays_recurring 
  ON public.holidays(is_recurring) 
  WHERE deleted_at IS NULL AND is_active = true;

-- Holiday Messages Indexes
CREATE INDEX IF NOT EXISTS idx_holiday_messages_holiday_id 
  ON public.holiday_messages(holiday_id) 
  WHERE is_active = true;

-- After Hours Messages Indexes
CREATE INDEX IF NOT EXISTS idx_after_hours_messages_schedule_id 
  ON public.after_hours_messages(schedule_id) 
  WHERE is_active = true;

-- Schedule Overrides Indexes
CREATE INDEX IF NOT EXISTS idx_schedule_overrides_schedule_id 
  ON public.schedule_overrides(schedule_id);

CREATE INDEX IF NOT EXISTS idx_schedule_overrides_date 
  ON public.schedule_overrides(override_date);

-- ============================================
-- TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_schedule_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_call_schedules_updated_at
  BEFORE UPDATE ON public.call_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_schedule_updated_at();

CREATE TRIGGER update_weekly_availability_updated_at
  BEFORE UPDATE ON public.weekly_availability
  FOR EACH ROW
  EXECUTE FUNCTION update_schedule_updated_at();

CREATE TRIGGER update_holidays_updated_at
  BEFORE UPDATE ON public.holidays
  FOR EACH ROW
  EXECUTE FUNCTION update_schedule_updated_at();

CREATE TRIGGER update_holiday_messages_updated_at
  BEFORE UPDATE ON public.holiday_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_schedule_updated_at();

CREATE TRIGGER update_after_hours_messages_updated_at
  BEFORE UPDATE ON public.after_hours_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_schedule_updated_at();

CREATE TRIGGER update_schedule_overrides_updated_at
  BEFORE UPDATE ON public.schedule_overrides
  FOR EACH ROW
  EXECUTE FUNCTION update_schedule_updated_at();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.call_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.holidays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.holiday_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.after_hours_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_overrides ENABLE ROW LEVEL SECURITY;

-- Call Schedules Policies
CREATE POLICY "Users can view own call schedules"
  ON public.call_schedules FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert own call schedules"
  ON public.call_schedules FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own call schedules"
  ON public.call_schedules FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own call schedules"
  ON public.call_schedules FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id AND deleted_at IS NOT NULL);

-- Weekly Availability Policies
CREATE POLICY "Users can manage weekly availability for own schedules"
  ON public.weekly_availability FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.call_schedules 
      WHERE call_schedules.id = weekly_availability.schedule_id 
      AND call_schedules.user_id = auth.uid()
      AND call_schedules.deleted_at IS NULL
    )
  );

-- Holidays Policies
CREATE POLICY "Users can view own and global holidays"
  ON public.holidays FOR SELECT
  USING (
    (user_id IS NULL) OR 
    (user_id = auth.uid() AND deleted_at IS NULL)
  );

CREATE POLICY "Users can insert own holidays"
  ON public.holidays FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can update own holidays"
  ON public.holidays FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own holidays"
  ON public.holidays FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND deleted_at IS NOT NULL);

-- Holiday Messages Policies
CREATE POLICY "Users can manage holiday messages for own holidays"
  ON public.holiday_messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.holidays 
      WHERE holidays.id = holiday_messages.holiday_id 
      AND (holidays.user_id = auth.uid() OR holidays.user_id IS NULL)
      AND holidays.deleted_at IS NULL
    )
  );

-- After Hours Messages Policies
CREATE POLICY "Users can manage after hours messages for own schedules"
  ON public.after_hours_messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.call_schedules 
      WHERE call_schedules.id = after_hours_messages.schedule_id 
      AND call_schedules.user_id = auth.uid()
      AND call_schedules.deleted_at IS NULL
    )
  );

-- Schedule Overrides Policies
CREATE POLICY "Users can manage overrides for own schedules"
  ON public.schedule_overrides FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.call_schedules 
      WHERE call_schedules.id = schedule_overrides.schedule_id 
      AND call_schedules.user_id = auth.uid()
      AND call_schedules.deleted_at IS NULL
    )
  );

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if a date/time is within schedule
CREATE OR REPLACE FUNCTION is_call_available(
  p_schedule_id UUID,
  p_check_datetime TIMESTAMPTZ,
  p_timezone VARCHAR DEFAULT 'America/New_York'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_schedule_timezone VARCHAR;
  v_local_datetime TIMESTAMPTZ;
  v_day_of_week INTEGER;
  v_holiday_exists BOOLEAN;
  v_override_exists BOOLEAN;
  v_weekly_available BOOLEAN;
  v_override_available BOOLEAN;
BEGIN
  -- Get schedule timezone
  SELECT timezone INTO v_schedule_timezone
  FROM public.call_schedules
  WHERE id = p_schedule_id AND deleted_at IS NULL;
  
  IF v_schedule_timezone IS NULL THEN
    RETURN false;
  END IF;
  
  -- Convert to schedule timezone
  v_local_datetime := p_check_datetime AT TIME ZONE p_timezone AT TIME ZONE v_schedule_timezone;
  v_day_of_week := EXTRACT(DOW FROM v_local_datetime);
  
  -- Check for holiday
  SELECT EXISTS (
    SELECT 1 FROM public.holidays h
    WHERE (
      (h.user_id IS NULL OR h.user_id = (SELECT user_id FROM public.call_schedules WHERE id = p_schedule_id))
      AND h.holiday_date = DATE(v_local_datetime)
      AND h.is_active = true
      AND h.deleted_at IS NULL
    )
    OR (
      h.is_recurring = true
      AND EXTRACT(MONTH FROM h.holiday_date) = EXTRACT(MONTH FROM v_local_datetime)
      AND EXTRACT(DAY FROM h.holiday_date) = EXTRACT(DAY FROM v_local_datetime)
      AND h.is_active = true
      AND h.deleted_at IS NULL
    )
  ) INTO v_holiday_exists;
  
  IF v_holiday_exists THEN
    RETURN false; -- Holidays are not available
  END IF;
  
  -- Check for date-specific override
  SELECT EXISTS (
    SELECT 1 FROM public.schedule_overrides
    WHERE schedule_id = p_schedule_id
    AND override_date = DATE(v_local_datetime)
  ) INTO v_override_exists;
  
  IF v_override_exists THEN
    SELECT is_available INTO v_override_available
    FROM public.schedule_overrides
    WHERE schedule_id = p_schedule_id
    AND override_date = DATE(v_local_datetime);
    
    IF NOT v_override_available THEN
      RETURN false;
    END IF;
    
    -- If override has specific times, check them
    IF EXISTS (
      SELECT 1 FROM public.schedule_overrides
      WHERE schedule_id = p_schedule_id
      AND override_date = DATE(v_local_datetime)
      AND start_time IS NOT NULL
      AND end_time IS NOT NULL
    ) THEN
      RETURN (
        TIME(v_local_datetime) >= (
          SELECT start_time FROM public.schedule_overrides
          WHERE schedule_id = p_schedule_id
          AND override_date = DATE(v_local_datetime)
        )
        AND TIME(v_local_datetime) <= (
          SELECT end_time FROM public.schedule_overrides
          WHERE schedule_id = p_schedule_id
          AND override_date = DATE(v_local_datetime)
        )
      );
    END IF;
    
    RETURN true; -- Override says available, use default times
  END IF;
  
  -- Check weekly availability
  SELECT is_available INTO v_weekly_available
  FROM public.weekly_availability
  WHERE schedule_id = p_schedule_id
  AND day_of_week = v_day_of_week;
  
  IF NOT v_weekly_available THEN
    RETURN false;
  END IF;
  
  -- Check time within availability window
  RETURN (
    TIME(v_local_datetime) >= (
      SELECT start_time FROM public.weekly_availability
      WHERE schedule_id = p_schedule_id
      AND day_of_week = v_day_of_week
    )
    AND TIME(v_local_datetime) <= (
      SELECT end_time FROM public.weekly_availability
      WHERE schedule_id = p_schedule_id
      AND day_of_week = v_day_of_week
    )
    AND NOT (
      TIME(v_local_datetime) >= (
        SELECT break_start_time FROM public.weekly_availability
        WHERE schedule_id = p_schedule_id
        AND day_of_week = v_day_of_week
      )
      AND TIME(v_local_datetime) <= (
        SELECT break_end_time FROM public.weekly_availability
        WHERE schedule_id = p_schedule_id
        AND day_of_week = v_day_of_week
      )
    )
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.call_schedules IS 'Main schedule configuration per agent/user';
COMMENT ON TABLE public.weekly_availability IS 'Weekly availability templates (Monday-Sunday)';
COMMENT ON TABLE public.holidays IS 'Holiday definitions (global or user-specific)';
COMMENT ON TABLE public.holiday_messages IS 'Holiday-specific messages';
COMMENT ON TABLE public.after_hours_messages IS 'After-hours message configuration';
COMMENT ON TABLE public.schedule_overrides IS 'Date-specific schedule overrides';
COMMENT ON FUNCTION is_call_available IS 'Checks if a date/time is within the configured schedule, considering holidays and overrides';
