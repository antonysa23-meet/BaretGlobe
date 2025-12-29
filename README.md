# Baret Scholars Globe 🌍

A Flutter mobile application that connects Baret Scholars worldwide by visualizing their real-time locations on an interactive globe. Stay connected with fellow alumni, track your cohort, and see where scholars are around the world.

## Features

### 🗺️ Interactive Globe
- Real-time visualization of all alumni locations on a world map
- Tap markers to view scholar details (name, cohort year, region)
- "Last updated" indicators (today, yesterday, a week ago, etc.)
- Auto-filter: Only shows locations updated within the last month
- Smooth zoom and pan controls with momentum

### 🔐 Authentication
- Google Sign-In integration
- Cohort selection dialog for new users (year + region)
- Automatic profile creation and management

### 📍 Location Tracking
- **Automatic Location Updates**: Captures your location instantly when you open the app
- **Foreground Tracking**: Real-time updates while app is active
- **Background Tracking**: Periodic updates even when app is in background
- **Smart Updates**: Only updates when you move 1km+ or after 5 minutes
- **Manual Location Override**: Set a custom location for a specific duration
  - Duration options: 1 hour, 1 day, 1 week, 1 month, or forever
  - Perfect for privacy or when traveling
- **Privacy Controls**: Toggle visibility on/off with confirmation dialog

### ⚙️ Settings & Preferences
- **Location Tracking Toggle**: Enable/disable automatic location updates
- **Tracking Frequency**: Choose update intervals (hourly, daily, weekly)
- **Globe Visibility**: Hide yourself from the globe with one tap
- **Manual Location**: Override your GPS location temporarily
- **Notifications**: Manage app notifications

### 🎯 Key Highlights
- **Privacy First**: Full control over your visibility and location sharing
- **Battery Efficient**: Smart tracking that respects battery life
- **Real-time Updates**: See changes as they happen
- **Cohort Tracking**: Filter and connect with scholars from your region/year
- **Clean UI**: Modern, intuitive interface with smooth animations

## Tech Stack

### Frontend
- **Flutter 3.38.5** - Cross-platform mobile framework
- **Dart 3.10.4** - Programming language
- **Riverpod 2.x** - State management with code generation
- **Freezed** - Immutable models and unions
- **Flutter Map** - Interactive map visualization
- **Geolocator** - GPS location services
- **Google Sign-In** - Authentication

### Backend
- **Supabase** - Backend-as-a-Service
- **PostgreSQL** - Database with PostGIS for geospatial data
- **Row Level Security (RLS)** - Secure data access
- **Database Functions** - Server-side logic for location updates

### Architecture
- **Feature-First Structure**: Organized by features (auth, globe, settings, etc.)
- **Repository Pattern**: Clean separation of data and business logic
- **Provider Pattern**: Dependency injection with Riverpod
- **Code Generation**: Freezed, Riverpod, and JSON serialization

## Project Structure

```
lib/
├── core/                      # Core utilities and services
│   ├── constants/            # App constants (colors, text styles, API)
│   └── services/             # Location services (foreground/background)
├── features/
│   ├── auth/                 # Authentication & sign-in
│   │   ├── data/            # Auth repository
│   │   ├── domain/          # Auth models
│   │   └── presentation/    # Sign-in UI & providers
│   ├── globe/                # Interactive world map
│   │   ├── data/            # Location repository
│   │   ├── domain/          # Location & alumnus models
│   │   └── presentation/    # Globe screen & markers
│   ├── settings/             # User preferences
│   │   ├── data/            # Settings repository
│   │   ├── domain/          # UserPreferences model
│   │   └── presentation/    # Settings UI & toggles
│   ├── home/                 # Bottom navigation
│   ├── messaging/            # Chat (coming soon)
│   └── profile/              # User profile
└── main.dart                 # App entry point

supabase/
└── migrations/               # Database migrations
    ├── create_update_alumnus_location_function.sql
    ├── add_visible_on_globe_column.sql
    ├── add_location_cleanup_function.sql
    └── update_location_function_with_visibility_filter.sql
```

## Getting Started

### Prerequisites
- Flutter SDK 3.38.5 or higher
- Dart SDK 3.10.4 or higher
- Supabase account
- Google Cloud Console project (for Google Sign-In)

### Installation

1. **Clone the repository**
   ```bash
   cd baret_scholars_globe
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a Supabase project
   - Run all SQL migrations in order:
     1. `create_update_alumnus_location_function.sql`
     2. `add_visible_on_globe_column.sql`
     3. `add_location_cleanup_function.sql`
     4. `update_location_function_with_visibility_filter.sql`

4. **Configure environment**
   - Add your Supabase credentials to the app
   - Set up Google Sign-In credentials

5. **Run the app**
   ```bash
   flutter run
   ```

## Database Setup

### Required Tables
- `alumni` - Scholar profiles with cohort information
- `locations` - GPS location history
- `user_preferences` - Settings and preferences
- `auth.users` - Supabase authentication

### Key Functions
- `update_alumnus_location()` - Manages location updates (ensures only 1 current location)
- `get_current_alumni_locations()` - Fetches visible locations for the globe
- `cleanup_old_locations()` - Removes locations older than 1 month

## Configuration

### Location Tracking
- **Update Interval**: 5 minutes (configurable)
- **Minimum Distance**: 1 km before triggering update
- **Location Accuracy**: Medium (balances accuracy and battery)
- **Age Filter**: Only shows locations from the last month

### Privacy Settings
- **Visibility**: Users can hide from globe at any time
- **Manual Override**: Set custom location with expiration
- **RLS Policies**: Database-level security for all data

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Development

### Code Generation
When modifying Freezed models or Riverpod providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Debugging
- Enable verbose logging in location services
- Check Supabase logs for database issues
- Use Flutter DevTools for performance profiling

## Contributing

This is a private project for Baret Scholars. For questions or issues, contact the development team.

## License

Proprietary - Baret Scholars Network

## Roadmap

### Upcoming Features
- [ ] Messaging between scholars
- [ ] Event coordination and meetups
- [ ] Cohort-based filtering on globe
- [ ] Push notifications for nearby scholars
- [ ] Profile customization
- [ ] Photo sharing and albums
- [ ] Search and discover alumni

---

**Built with ❤️ for the Baret Scholars community**
