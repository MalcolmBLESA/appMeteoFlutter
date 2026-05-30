import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherRepository extends ChangeNotifier {
  final WeatherService _weatherService;

  WeatherRepository(this._weatherService);

  // --- ÉTAT GLOBAL---
  String _cityName = "...";
  Map<String, dynamic>? _weatherData;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  
  // Stockage des coordonnées pour optimiser les requêtes 
  double? _currentLat;
  double? _currentLon;

  // --- GETTERS (Lecture seule pour les ViewModels) ---
  String get cityName => _cityName;
  Map<String, dynamic>? get weatherData => _weatherData;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isLoading => _isLoading;

  // --- ACTIONS ---

  /// Relais vers le service pour obtenir les suggestions de villes (Autocomplétion)
  Future<List<Map<String, dynamic>>> getCitySuggestions(String query) {
    return _weatherService.getCitySuggestions(query);
  }

  /// Méthode optimisée : Récupère la météo directement via les coordonnées (Depuis l'autocomplétion)
  Future<void> fetchWeatherForLocation(double lat, double lon, String cityName) async {
    _isLoading = true;
    notifyListeners();

    _cityName = cityName;
    _currentLat = lat;
    _currentLon = lon;

    final dates = _getStartAndEndDates();

    final data = await _weatherService.getWeather(lat, lon, dates['start']!, dates['end']!);
    if (data != null) {
      _weatherData = data;
    } else {
      _weatherData = null;
    }

    _isLoading = false;
    notifyListeners(); 
  }

  /// Méthode classique 
  Future<void> fetchWeatherForCity(String city) async {
    _isLoading = true;
    notifyListeners();

    _cityName = city[0].toUpperCase() + city.substring(1).toLowerCase();

    final coords = await _weatherService.getCoordinates(_cityName);
    
    if (coords != null && coords.containsKey('error')) {
      _cityName = "Ville non trouvée";
      _weatherData = null;
      _currentLat = null;
      _currentLon = null;
    } else if (coords != null) {
      // On a trouvé les coordonnées, on bascule sur la méthode opti
      await fetchWeatherForLocation(coords['lat'], coords['lon'], _cityName);
      return; 
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 4. Met à jour la plage de dates 
  void updateDateRange(DateTimeRange range) {
    _selectedDateRange = range;
    
    // Si on a déjà une ville sélectionnée avec des coordonnées, on recharge la météo
    if (_currentLat != null && _currentLon != null) {
      fetchWeatherForLocation(_currentLat!, _currentLon!, _cityName);
    } else {
      notifyListeners();
    }
  }

  // --- MÉTHODES UTILITAIRES PRIVÉES ---

  /// Formate les dates de début et de fin pour l'API
  Map<String, String> _getStartAndEndDates() {
    String start, end;
    if (_selectedDateRange != null) {
      start = _selectedDateRange!.start.toIso8601String().split('T')[0];
      end = _selectedDateRange!.end.toIso8601String().split('T')[0];
    } else {
      start = DateTime.now().toIso8601String().split('T')[0];
      end = DateTime.now().add(const Duration(days: 6)).toIso8601String().split('T')[0];
    }
    return {'start': start, 'end': end};
  }
}