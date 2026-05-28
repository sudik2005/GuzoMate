-- ==============================================
-- GUZOMATE REALTIME CHAT FIX
-- ==============================================
-- Run this in your Supabase SQL Editor.

-- 1. Set Replica Identity so Realtime can broadcast full row changes
ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.matches REPLICA IDENTITY FULL;

-- 2. Add tables to the supabase_realtime publication
DO $$
BEGIN
  -- Add messages
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;

  -- Add matches
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'matches'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
  END IF;
END $$;
