import 'package:flutter/material.dart';
import '../repositories/weather_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final WeatherRepository _repository;
  int _selectedDayIndex = 0;

  HomeViewModel({required WeatherRepository repository}) : _repository = repository {
    _repository.addListener(_onRepositoryUpdated);
  }

  void _onRepositoryUpdated() {
    _selectedDayIndex = 0; // Réinitialise au jour 1 quand la ville change
    notifyListeners();
  }

  // --- GETTERS POUR LA VUE ---
  bool get isLoading => _repository.isLoading;
  String get cityName => _repository.cityName;
  int get selectedDayIndex => _selectedDayIndex;

  // Formate les données du jour sélectionné
  String get temperature => _getHourlyValue('temperature_2m');
  String get felt => _getHourlyValue('apparent_temperature');
  String get humidity => _getHourlyValue('relative_humidity_2m');
  String get wind => _getHourlyValue('wind_speed_10m');
  String get precipitation => _getHourlyValue('precipitation');
  String get cloud => _getHourlyValue('cloud_cover');

  List<Map<String, dynamic>> get dailyForecasts {
    final data = _repository.weatherData;
    if (data == null) return [];
    
    List<Map<String, dynamic>> forecasts = [];
    for (int i = 0; i < data['daily']['time'].length; i++) {
      forecasts.add({
        'day': data['daily']['time'][i],
        'max': data['daily']['temperature_2m_max'][i],
        'min': data['daily']['temperature_2m_min'][i],
        'code': data['daily']['weathercode'][i],
      });
    }
    return forecasts;
  }

  // --- ACTIONS DE LA VUE ---
  void searchCity(String city) {
    _repository.fetchWeatherForCity(city);
  }

  void setDateRange(DateTimeRange range) {
    _repository.updateDateRange(range);
  }

  void selectDay(int index) {
    _selectedDayIndex = index;
    notifyListeners(); // Met à jour uniquement la vue liée à ce ViewModel
  }

  // --- LOGIQUE MÉTIER INTERNE ---
  // Toute l'ancienne logique complexe de recherche d'index horaire est isolée ici
  String _getHourlyValue(String key) {
    final data = _repository.weatherData;
    if (data == null) return "--";

    try {
      String targetDate = data['daily']['time'][_selectedDayIndex];
      int hourlyIndex = 0;
      
      if (_selectedDayIndex == 0) {
        String nowHour = "${DateTime.now().toIso8601String().substring(0, 13)}:00";
        hourlyIndex = data['hourly']['time'].indexOf(nowHour);
      } else {
        String targetTime = "${targetDate}T12:00";
        hourlyIndex = data['hourly']['time'].indexOf(targetTime);
      }
      
      if (hourlyIndex == -1) hourlyIndex = 0;
      return data['hourly'][key][hourlyIndex].toString();
    } catch (e) {
      return "--";
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }
}