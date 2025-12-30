/// ISO 3166-1 country names for standardized location data
/// Used for country selection and validation
class Countries {
  Countries._(); // Private constructor to prevent instantiation

  /// Complete list of countries (ISO 3166-1 standard names)
  static const List<String> all = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Democratic Republic of the Congo',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'East Timor',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macedonia',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Swaziland',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  /// Common variations and abbreviations mapped to standard names
  static const Map<String, String> _variations = {
    // United States variations
    'usa': 'United States',
    'u.s.a': 'United States',
    'u.s.': 'United States',
    'us': 'United States',
    'america': 'United States',
    'united states of america': 'United States',

    // United Kingdom variations
    'uk': 'United Kingdom',
    'u.k': 'United Kingdom',
    'u.k.': 'United Kingdom',
    'britain': 'United Kingdom',
    'great britain': 'United Kingdom',
    'england': 'United Kingdom',
    'scotland': 'United Kingdom',
    'wales': 'United Kingdom',

    // UAE variations
    'uae': 'United Arab Emirates',
    'u.a.e': 'United Arab Emirates',
    'u.a.e.': 'United Arab Emirates',
    'emirates': 'United Arab Emirates',

    // Democratic Republic of the Congo
    'drc': 'Democratic Republic of the Congo',
    'd.r.c': 'Democratic Republic of the Congo',
    'dr congo': 'Democratic Republic of the Congo',
    'congo-kinshasa': 'Democratic Republic of the Congo',

    // Republic of the Congo
    'congo-brazzaville': 'Congo',
    'republic of the congo': 'Congo',

    // Czech Republic
    'czechia': 'Czech Republic',

    // Ivory Coast
    'côte d\'ivoire': 'Ivory Coast',
    'cote d\'ivoire': 'Ivory Coast',

    // South Korea
    'korea': 'South Korea',
    'republic of korea': 'South Korea',
    'rok': 'South Korea',

    // North Korea
    'dprk': 'North Korea',
    'democratic people\'s republic of korea': 'North Korea',

    // Netherlands
    'holland': 'Netherlands',

    // Myanmar
    'burma': 'Myanmar',

    // East Timor
    'timor-leste': 'East Timor',

    // Macedonia
    'north macedonia': 'Macedonia',

    // Swaziland
    'eswatini': 'Swaziland',
  };

  /// Standardize country name from various input formats
  ///
  /// Handles:
  /// - Case variations (USA → United States)
  /// - Common abbreviations (UK → United Kingdom)
  /// - Different spellings (Côte d'Ivoire → Ivory Coast)
  ///
  /// Returns the standardized country name if found, null otherwise
  static String? standardize(String input) {
    if (input.isEmpty) return null;

    final normalized = input.trim().toLowerCase();

    // Check for invalid values
    if (normalized == 'n/a' ||
        normalized == 'unknown' ||
        normalized == 'null' ||
        normalized == '') {
      return null;
    }

    // Check exact match (case-insensitive)
    for (final country in all) {
      if (country.toLowerCase() == normalized) {
        return country;
      }
    }

    // Check variations map
    if (_variations.containsKey(normalized)) {
      return _variations[normalized];
    }

    // Check partial match (contains)
    for (final country in all) {
      if (country.toLowerCase().contains(normalized) ||
          normalized.contains(country.toLowerCase())) {
        return country;
      }
    }

    return null; // No match found
  }

  /// Check if a country name is valid (exists in the list or can be standardized)
  static bool isValid(String? country) {
    if (country == null || country.isEmpty) return false;
    return standardize(country) != null;
  }

  /// Filter country list by search query
  ///
  /// Used for searchable dropdown - returns all countries that contain the query
  static List<String> search(String query) {
    if (query.isEmpty) return all;

    final normalized = query.trim().toLowerCase();

    return all.where((country) {
      return country.toLowerCase().contains(normalized);
    }).toList();
  }
}
