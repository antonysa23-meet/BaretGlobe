-- Create function to update alumnus location
-- This function ensures only ONE location is marked as is_current=true per alumnus
-- It sets all previous locations to is_current=false before inserting the new one

CREATE OR REPLACE FUNCTION update_alumnus_location(
  p_alumnus_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_city TEXT,
  p_country TEXT,
  p_location_type TEXT DEFAULT 'manual',
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  new_location_id UUID;
BEGIN
  -- First, set all existing locations for this alumnus to is_current = false
  UPDATE locations
  SET is_current = false
  WHERE alumnus_id = p_alumnus_id;

  -- Insert the new location as the current one
  INSERT INTO locations (
    alumnus_id,
    latitude,
    longitude,
    city,
    country,
    location_type,
    notes,
    is_current
  ) VALUES (
    p_alumnus_id,
    p_latitude,
    p_longitude,
    p_city,
    p_country,
    p_location_type,
    p_notes,
    true  -- This is the current location
  )
  RETURNING id INTO new_location_id;

  RETURN new_location_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION update_alumnus_location(UUID, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, TEXT, TEXT)
IS 'Updates alumnus location by setting all previous locations to is_current=false and inserting new location as current';
