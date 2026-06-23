import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double humidity;
  final double rainfall; // in mm
  final String cityName;
  final String region;
  final double latitude;
  final double longitude;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.cityName,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String name, String region, double lat, double lon) {
    final current = json['current'] ?? {};
    return WeatherData(
      temperature: (current['temperature_2m'] ?? 25.0).toDouble(),
      humidity: (current['relative_humidity_2m'] ?? 60.0).toDouble(),
      rainfall: (current['rain'] ?? 0.0).toDouble(),
      cityName: name,
      region: region,
      latitude: lat,
      longitude: lon,
    );
  }
}

class WeatherService {
  /// Resolves a city/region name to coordinates.
  /// Returns a list of maps containing 'name', 'admin1' (region), 'country', 'latitude', 'longitude'.
  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.trim().isEmpty) return [];
    
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=5&language=en&format=json'
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null) {
          return results.map((item) {
            return {
              'name': item['name'] ?? '',
              'region': item['admin1'] ?? item['country'] ?? '',
              'country': item['country'] ?? '',
              'latitude': (item['latitude'] ?? 0.0).toDouble(),
              'longitude': (item['longitude'] ?? 0.0).toDouble(),
            };
          }).toList();
        }
      }
    } catch (e) {
      print('Geocoding search failed: $e');
    }
    return [];
  }

  /// Fetches weather data for specific latitude and longitude.
  static Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    required String cityName,
    required String region,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,rain&timezone=auto'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data, cityName, region, latitude, longitude);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Weather fetch failed: $e. Falling back to default values.');
      // Return sensible defaults if fetch fails
      return WeatherData(
        temperature: 24.5,
        humidity: 65.0,
        rainfall: 45.0,
        cityName: cityName,
        region: region,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }
}
