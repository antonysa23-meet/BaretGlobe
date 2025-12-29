-- Create function to delete locations older than a month
-- This keeps the database clean and ensures only recent location data is shown

CREATE OR REPLACE FUNCTION cleanup_old_locations()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete locations older than 1 month
  DELETE FROM locations
  WHERE created_at < NOW() - INTERVAL '1 month'
    AND is_current = false;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION cleanup_old_locations() IS 'Deletes location records older than 1 month (keeps only current locations)';

-- Create a scheduled job to run cleanup daily (if pg_cron extension is available)
-- Note: This requires the pg_cron extension to be enabled in Supabase
-- Uncomment the following lines if you want automatic cleanup:

-- SELECT cron.schedule(
--   'cleanup-old-locations',
--   '0 2 * * *', -- Run at 2 AM daily
--   $$SELECT cleanup_old_locations();$$
-- );
