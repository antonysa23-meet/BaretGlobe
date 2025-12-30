import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for reverse geocoding coordinates to city names with caching
class GeocodingService {
  static const String _cachePrefix = 'geocode_cache_';
  static const int _cacheExpiryDays = 30;

  /// Approximate coordinates to nearest city using reverse geocoding
  ///
  /// Returns city name or null if no city found
  /// Results are cached in SharedPreferences to minimize API calls
  Future<String?> approximateToNearestCity(double lat, double lng) async {
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(lat, lng);
      final cachedCity = await _getCachedResult(cacheKey);
      if (cachedCity != null) {
        print('✅ GeocodingService: Found cached city: $cachedCity');
        return cachedCity;
      }

      print('🔵 GeocodingService: Geocoding ($lat, $lng)...');

      // Perform reverse geocoding
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) {
        print('❌ GeocodingService: No placemarks found');
        return null;
      }

      final placemark = placemarks.first;

      // Try to extract city name
      // Priority: locality > subAdministrativeArea > administrativeArea
      String? city = placemark.locality;
      city ??= placemark.subAdministrativeArea;
      city ??= placemark.administrativeArea;

      if (city != null && city.isNotEmpty) {
        print('✅ GeocodingService: Found city: $city');
        // Cache the result
        await _cacheResult(cacheKey, city);
        return city;
      }

      print('❌ GeocodingService: No city found in placemark');
      return null;
    } catch (error) {
      print('❌ GeocodingService: Error geocoding - $error');
      return null;
    }
  }

  /// Get country name from coordinates
  Future<String?> getCountry(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        print('❌ GeocodingService: No placemarks found for country');
        return null;
      }

      final placemark = placemarks.first;
      final country = placemark.country;
      final isoCode = placemark.isoCountryCode;

      print('🌍 GeocodingService: Country result for ($lat, $lng):');
      print('   - country: ${country ?? "NULL"}');
      print('   - isoCountryCode: ${isoCode ?? "NULL"}');
      print('   - administrativeArea: ${placemark.administrativeArea ?? "NULL"}');
      print('   - locality: ${placemark.locality ?? "NULL"}');

      // Try multiple approaches to get country name
      String? detectedCountry;

      // 1. Use country field if available
      if (country != null && country.isNotEmpty) {
        detectedCountry = country;
      }
      // 2. Fall back to ISO country code mapping
      else if (isoCode != null && isoCode.isNotEmpty) {
        detectedCountry = _getCountryNameFromIsoCode(isoCode);
        if (detectedCountry != null) {
          print('✅ GeocodingService: Mapped ISO code "$isoCode" to "$detectedCountry"');
        }
      }
      // 3. Try administrativeArea as last resort for some regions
      else if (placemark.administrativeArea != null &&
               placemark.administrativeArea!.isNotEmpty) {
        // Some geocoding APIs return country in administrativeArea
        final admin = placemark.administrativeArea!;
        // Only use if it looks like a country (short name, common patterns)
        if (_looksLikeCountryName(admin)) {
          detectedCountry = admin;
          print('⚠️ GeocodingService: Using administrativeArea as country: "$admin"');
        }
      }

      // Return detected country or "N/A"
      if (detectedCountry != null && detectedCountry.isNotEmpty) {
        return detectedCountry;
      }

      print('⚠️ GeocodingService: Country is null or empty, returning "N/A"');
      return 'N/A';
    } catch (error) {
      print('❌ GeocodingService: Error getting country - $error');
      return null;
    }
  }

  /// Map ISO country code to full country name
  String? _getCountryNameFromIsoCode(String isoCode) {
    // Common country code mappings
    final countryMap = <String, String>{
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'NZ': 'New Zealand',
      'IE': 'Ireland',
      'ZA': 'South Africa',
      'IN': 'India',
      'PK': 'Pakistan',
      'BD': 'Bangladesh',
      'NG': 'Nigeria',
      'KE': 'Kenya',
      'IL': 'Israel',
      'PS': 'Palestine',
      'JO': 'Jordan',
      'EG': 'Egypt',
      'SA': 'Saudi Arabia',
      'AE': 'United Arab Emirates',
      'FR': 'France',
      'DE': 'Germany',
      'IT': 'Italy',
      'ES': 'Spain',
      'PT': 'Portugal',
      'NL': 'Netherlands',
      'BE': 'Belgium',
      'CH': 'Switzerland',
      'AT': 'Austria',
      'PL': 'Poland',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'JP': 'Japan',
      'CN': 'China',
      'KR': 'South Korea',
      'TH': 'Thailand',
      'SG': 'Singapore',
      'MY': 'Malaysia',
      'ID': 'Indonesia',
      'PH': 'Philippines',
      'VN': 'Vietnam',
      'BR': 'Brazil',
      'AR': 'Argentina',
      'MX': 'Mexico',
      'CL': 'Chile',
      'CO': 'Colombia',
      'PE': 'Peru',
    };

    return countryMap[isoCode.toUpperCase()];
  }

  /// Check if a string looks like a country name
  bool _looksLikeCountryName(String value) {
    // Basic heuristic: short strings (< 30 chars) that don't contain numbers
    return value.length < 30 && !value.contains(RegExp(r'\d'));
  }

  /// Forward geocoding: Convert city name to coordinates
  ///
  /// Returns a Map with 'latitude' and 'longitude' keys, or null if geocoding fails
  Future<Map<String, double>?> getCoordinatesFromCity({
    required String city,
    required String country,
  }) async {
    try {
      print('🔵 GeocodingService: Forward geocoding "$city, $country"...');

      // Combine city and country for better accuracy
      final query = '$city, $country';
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        print('❌ GeocodingService: No coordinates found for "$query"');
        return null;
      }

      final location = locations.first;
      print(
          '✅ GeocodingService: Found coordinates: (${location.latitude}, ${location.longitude})');

      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    } catch (error) {
      print('❌ GeocodingService: Error forward geocoding - $error');
      return null;
    }
  }

  /// Generate cache key from coordinates (rounded to 2 decimal places)
  String _generateCacheKey(double lat, double lng) {
    final roundedLat = lat.toStringAsFixed(2);
    final roundedLng = lng.toStringAsFixed(2);
    return '$_cachePrefix${roundedLat}_$roundedLng';
  }

  /// Get cached geocoding result
  Future<String?> _getCachedResult(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached == null) return null;

      // Check if cache is expired
      final timestamp = prefs.getInt('${key}_time');
      if (timestamp == null) return null;

      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryDate = cacheDate.add(const Duration(days: _cacheExpiryDays));

      if (DateTime.now().isAfter(expiryDate)) {
        // Cache expired, remove it
        await prefs.remove(key);
        await prefs.remove('${key}_time');
        return null;
      }

      return cached;
    } catch (error) {
      print('❌ GeocodingService: Error reading cache - $error');
      return null;
    }
  }

  /// Cache geocoding result
  Future<void> _cacheResult(String key, String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, city);
      await prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
      print('💾 GeocodingService: Cached result for $key');
    } catch (error) {
      print('❌ GeocodingService: Error caching - $error');
    }
  }

  /// Clear all cached geocoding results
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        await prefs.remove(key);
        await prefs.remove('${key}_time');
      }

      print('✅ GeocodingService: Cache cleared');
    } catch (error) {
      print('❌ GeocodingService: Error clearing cache - $error');
    }
  }
}
