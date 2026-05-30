import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WeatherService {
  Future<Map<String, dynamic>?> getCoordinates(String cityName) async {
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&language=fr&format=json'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return {
            'lat': result['latitude'],
            'lon': result['longitude'],
            'name': result['name'],
          };
        }
      }
      return {'error': "Ville non trouvée"};
    } catch (e) {
      debugPrint("Erreur lors du géocodage : $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeather(double lat, double lon, String start, String end) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&start_date=$start&end_date=$end&hourly=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloud_cover,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Erreur API météo : $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getCitySuggestions(String query) async {
    final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=5&language=fr&format=json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results'].map((json) => {
                'name': json['name'],
                'country': json['country'] ?? '',
                'admin1': json['admin1'] ?? '',
                'postcode': (json['postcodes'] != null && json['postcodes'].isNotEmpty)
                    ? json['postcodes'][0]
                    : null,
                'lat': json['latitude'],
                'lon': json['longitude'],
              }));
        }
      }
    } catch (e) {
      debugPrint("Erreur suggestions : $e");
    }
    return [];
  }
}