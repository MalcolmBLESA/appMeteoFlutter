import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherRepository extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherRepository(this._weatherService);

  // --- ÉTAT GLOBAL ---
  String _cityName = "...";
  Map<String, dynamic>? _weatherData;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  // --- GETTERS (Lecture seule) ---
  String get cityName => _cityName;
  Map<String, dynamic>? get weatherData => _weatherData;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isLoading => _isLoading;

  // --- ACTIONS ---
  Future<void> fetchWeatherForCity(String city) async {
    _isLoading = true;
    notifyListeners();

    _cityName = city[0].toUpperCase() + city.substring(1).toLowerCase();

    String start, end;
    if (_selectedDateRange != null) {
      start = _selectedDateRange!.start.toIso8601String().split('T')[0];
      end = _selectedDateRange!.end.toIso8601String().split('T')[0];
    } else {
      start = DateTime.now().toIso8601String().split('T')[0];
      end = DateTime.now().add(const Duration(days: 6)).toIso8601String().split('T')[0];
    }

    final coords = await _weatherService.getCoordinates(_cityName);
    if (coords != null && coords.containsKey('error')) {
      _cityName = "Ville non trouvée";
      _weatherData = null;
    } else if (coords != null) {
      final data = await _weatherService.getWeather(coords['lat']!, coords['lon']!, start, end);
      if (data != null) {
        _weatherData = data;
      }
    }

    _isLoading = false;
    notifyListeners(); // Prévient tous les ViewModels que la donnée a changé
  }

  void updateDateRange(DateTimeRange range) {
    _selectedDateRange = range;
    if (_cityName != "..." && _cityName != "Ville non trouvée") {
      fetchWeatherForCity(_cityName);
    } else {
      notifyListeners();
    }
  }
}