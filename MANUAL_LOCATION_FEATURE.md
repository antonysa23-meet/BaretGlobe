# Manual Location Override Feature

## Overview
This feature allows users to manually set their location for a specified duration instead of using automatic GPS tracking. During this period, the manually set location will be displayed on the globe instead of their actual GPS position.

## What Has Been Implemented

### 1. Database Changes

#### New Columns in `user_preferences` Table
- `manual_location_city` (TEXT) - Manually set city name
- `manual_location_country` (TEXT) - Manually set country name
- `manual_location_latitude` (DOUBLE PRECISION) - Manually set latitude
- `manual_location_longitude` (DOUBLE PRECISION) - Manually set longitude
- `manual_location_expires_at` (TIMESTAMPTZ) - When the override expires (NULL = forever)

**Migration File**: `supabase/migrations/add_manual_location_fields.sql`

#### Updated Database Function
The `get_current_alumni_locations()` function now checks for manual location overrides:
- If a user has set a manual location that hasn't expired, it returns that location
- Otherwise, it returns their actual GPS-tracked location
- Automatically handles expiration checking

**Migration File**: `supabase/migrations/update_location_function_with_manual_override.sql`

### 2. Backend Logic

#### SettingsRepository (`lib/features/settings/data/repositories/settings_repository.dart`)

**New Methods**:
- `setManualLocation()` - Set a manual location with optional duration
- `clearManualLocation()` - Clear the manual override and resume GPS tracking
- `checkAndClearExpiredManualLocation()` - Automatically clear expired overrides

**Duration Options**:
- 1 hour
- 1 day
- 1 week
- 1 month
- Forever (null expiration)

#### ForegroundLocationService (`lib/core/services/foreground_location_service.dart`)

**Updated Behavior**:
- Before updating location from GPS, checks if manual override is active
- If manual location is set and not expired, skips GPS update
- Logs the manual location status and time remaining
- Automatically resumes GPS tracking when manual location expires

### 3. User Interface

#### ManualLocationDialog (`lib/features/settings/presentation/widgets/manual_location_dialog.dart`)

A dialog for setting manual location with:
- **Latitude/Longitude Input**: Text fields with validation (-90 to 90 for lat, -180 to 180 for lng)
- **Geocode Button**: "Find city from coordinates" - automatically looks up city/country
- **City Input**: Manual entry or auto-filled from geocoding
- **Country Input**: Manual entry or auto-filled from geocoding
- **Duration Selection**: Radio buttons for 1 hour, 1 day, 1 week, 1 month, or forever
- **Save/Cancel**: Actions to confirm or cancel

#### Settings Screen Update (`lib/features/settings/presentation/screens/settings_screen.dart`)

**New Section**: "Manual Location Override"

**When No Manual Location Is Set**:
- Shows info text explaining the feature
- "Set Location" button to open the dialog

**When Manual Location Is Active**:
- **Status Display**: Shows the current manual location with colored indicator
  - Green for "Forever"
  - Blue for temporary with time remaining (e.g., "Set to Jerusalem, to be determined (2 days left)")
  - Red for expired
- **Change Location Button**: Opens dialog to modify the manual location
- **Clear Button**: Removes the override and resumes GPS tracking (with confirmation dialog)
- **Info Text**: Explains that GPS tracking is paused while manual location is active

### 4. Data Model Updates

#### UserPreferences Model (`lib/features/settings/domain/models/user_preferences.dart`)

Added optional fields:
```dart
String? manualLocationCity,
String? manualLocationCountry,
double? manualLocationLatitude,
double? manualLocationLongitude,
DateTime? manualLocationExpiresAt,
```

Updated `fromSupabaseJson` and `toSupabaseJson` to handle new fields.

## How It Works

### Setting a Manual Location

1. User goes to Settings screen
2. Clicks "Set Location" in the Manual Location Override section
3. Dialog opens with form:
   - Enter latitude and longitude (or use geocoding to find coordinates)
   - Click "Find city from coordinates" to auto-fill city/country
   - Select duration (1 hour, 1 day, 1 week, 1 month, or forever)
   - Click "Set Location"
4. Manual location is saved to database
5. GPS tracking is paused
6. Globe displays the manual location instead of actual GPS position

### Automatic Expiration Handling

- **Foreground Service**: Checks expiration before each GPS update attempt
- **Database Function**: Only returns manual location if not expired
- **When Expired**: Automatically clears the override and resumes GPS tracking

### Clearing Manual Location

1. User clicks "Clear" button in Settings
2. Confirmation dialog appears
3. If confirmed:
   - Manual location fields are set to NULL in database
   - GPS tracking resumes immediately
   - Next GPS update will use actual location

## User Flow Examples

### Example 1: Temporary Override (Vacation)
User is traveling but wants to show their home location for 1 week:
1. Open Settings → Manual Location Override → Set Location
2. Enter home coordinates (or geocode from city name)
3. Select "1 Week"
4. Save
5. For 1 week, globe shows home location
6. After 7 days, automatically resumes showing actual GPS location

### Example 2: Permanent Override (Privacy)
User wants to show city-level location instead of exact GPS:
1. Open Settings → Manual Location Override → Set Location
2. Enter city center coordinates
3. Select "Forever"
4. Save
5. Globe always shows city center, never actual GPS position
6. User can clear manually anytime to resume GPS tracking

## Testing Steps

1. **Apply Database Migrations**:
   ```bash
   # Run these SQL files in your Supabase SQL editor:
   # 1. supabase/migrations/add_manual_location_fields.sql
   # 2. supabase/migrations/update_location_function_with_manual_override.sql
   ```

2. **Test Setting Manual Location**:
   - Open app and go to Settings
   - Click "Set Location"
   - Enter coordinates (e.g., Jerusalem: 31.7683, 35.2137)
   - Click "Find city from coordinates"
   - Select "1 Day" duration
   - Click "Set Location"
   - Verify status shows in Settings

3. **Test Globe Display**:
   - Navigate to Globe screen
   - Verify your location shows as the manual location
   - Check logs for "Manual location override active"

4. **Test Expiration**:
   - Set a manual location with "1 Hour" duration
   - Wait 1 hour
   - Check logs - should see "Manual location expired - resuming GPS tracking"
   - Verify GPS location is used again

5. **Test Clearing**:
   - Set a manual location
   - Click "Clear" button
   - Confirm in dialog
   - Verify GPS tracking resumes
   - Check globe shows actual GPS location

## Files Created/Modified

### New Files:
- `supabase/migrations/add_manual_location_fields.sql`
- `supabase/migrations/update_location_function_with_manual_override.sql`
- `lib/features/settings/presentation/widgets/manual_location_dialog.dart`
- `MANUAL_LOCATION_FEATURE.md` (this file)

### Modified Files:
- `lib/features/settings/domain/models/user_preferences.dart`
- `lib/features/settings/data/repositories/settings_repository.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/core/services/foreground_location_service.dart`

## Next Steps

1. **Run Database Migrations**: Execute both SQL migration files in Supabase
2. **Test the Feature**: Follow the testing steps above
3. **Optional Enhancements**:
   - Add manual location support to background service (currently only foreground checks)
   - Add a map picker in the dialog for visual coordinate selection
   - Show manual location with different icon/color on globe
   - Add analytics to track manual location usage
