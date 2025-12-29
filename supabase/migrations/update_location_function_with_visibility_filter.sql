-- Update get_current_alumni_locations function to filter by visibility and age
-- Only show users who have visible_on_globe = true and locations updated within last month

CREATE OR REPLACE FUNCTION get_current_alumni_locations()
RETURNS TABLE (
  alumnus_id uuid,
  alumnus_name text,
  cohort_year int,
  cohort_region text,
  latitude double precision,
  longitude double precision,
  city text,
  country text,
  location_notes text,
  updated_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id as alumnus_id,
    a.name as alumnus_name,
    a.cohort_year,
    a.cohort_region,
    -- Use manual location if set and not expired, otherwise use actual location
    CASE
      WHEN up.manual_location_latitude IS NOT NULL
        AND up.manual_location_longitude IS NOT NULL
        AND (up.manual_location_expires_at IS NULL OR up.manual_location_expires_at > now())
      THEN up.manual_location_latitude
      ELSE l.latitude
    END as latitude,
    CASE
      WHEN up.manual_location_latitude IS NOT NULL
        AND up.manual_location_longitude IS NOT NULL
        AND (up.manual_location_expires_at IS NULL OR up.manual_location_expires_at > now())
      THEN up.manual_location_longitude
      ELSE l.longitude
    END as longitude,
    CASE
      WHEN up.manual_location_latitude IS NOT NULL
        AND up.manual_location_longitude IS NOT NULL
        AND (up.manual_location_expires_at IS NULL OR up.manual_location_expires_at > now())
      THEN up.manual_location_city
      ELSE l.city
    END as city,
    CASE
      WHEN up.manual_location_latitude IS NOT NULL
        AND up.manual_location_longitude IS NOT NULL
        AND (up.manual_location_expires_at IS NULL OR up.manual_location_expires_at > now())
      THEN up.manual_location_country
      ELSE l.country
    END as country,
    CASE
      WHEN up.manual_location_latitude IS NOT NULL
        AND up.manual_location_longitude IS NOT NULL
        AND (up.manual_location_expires_at IS NULL OR up.manual_location_expires_at > now())
      THEN 'Manual location override'
      ELSE l.notes
    END as location_notes,
    COALESCE(l.created_at, a.updated_at) as updated_at
  FROM alumni a
  LEFT JOIN locations l ON a.id = l.alumnus_id AND l.is_current = true
  LEFT JOIN user_preferences up ON a.id = up.alumnus_id
  WHERE l.latitude IS NOT NULL
    AND l.longitude IS NOT NULL
    AND l.created_at > NOW() - INTERVAL '1 month'  -- Only show locations updated within last month
    AND (up.visible_on_globe IS NULL OR up.visible_on_globe = true)  -- Filter by visibility
  ORDER BY a.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION get_current_alumni_locations() IS 'Returns current locations for visible alumni updated within last month, using manual overrides when set and not expired';
