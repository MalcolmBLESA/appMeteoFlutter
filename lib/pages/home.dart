
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meteo_aquatech/weather_service.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    // --- SERVICES ET VARIABLES D'ÉTAT ---
  final WeatherService _weatherService = WeatherService();
  String cityName = "...";
  String temperature = "--";
  String felt = "--";
  String humidity = "--";
  String wind = "--";
  String precipitation = "--";
  String cloud = "--";
  DateTimeRange? selectedDateRange;// Pour la sélection personnalisée de dates
  List<dynamic> dailyForecasts = [];// Liste des prévisions par jour
  int selectedDayIndex = 0;// Index du jour actuellement affiché
  Map<String, dynamic>? lastWeatherData;// Stockage des dernières données reçues
  bool isLoading = false;
  // --- LOGIQUE MÉTIER / APPELS API ---

  /// Ouvre le sélecteur de calendrier Flutter pour choisir une plage de dates
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      locale: const Locale("fr", "FR"),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 14)),// Limite à J+14 car sinon ce n'est plus précit
      saveText: 'Valider',
      builder: (context, child) {
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 400.0,
                  ),
                  child: child,
                )
              ],
            );
          });

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      _fetchWeatherData();// Recharge les données après sélection
      }
      
    }
// Récupère les coordonnées GPS puis les données météo 
    Future<void> _fetchWeatherData() async {
  if (cityName == "..." || cityName.isEmpty) return;
// Définition de la période (par défaut 7 jours)
  String start, end;
  if (selectedDateRange != null) {
    start = selectedDateRange!.start.toIso8601String().split('T')[0];
    end = selectedDateRange!.end.toIso8601String().split('T')[0];
  } else {
    start = DateTime.now().toIso8601String().split('T')[0];
    end = DateTime.now().add(const Duration(days: 6)).toIso8601String().split('T')[0];
  }
  // 1. Géocodage (Ville -> Lat/Lon)
  final coords = await _weatherService.getCoordinates(cityName);
  if (coords != null && coords.containsKey('error')) {
    setState(() {
      cityName = "ville non trouvée"; 
  });
  return; 
}
 // 2. Récupération météo
  if (coords != null) {
    final data = await _weatherService.getWeather(coords['lat']!, coords['lon']!, start, end);
    
    if (data != null) {
      setState(() {
        String nowHour = "${DateTime.now().toIso8601String().substring(0, 13)}:00";
        int index = data['hourly']['time'].indexOf(nowHour);
        if (index == -1) index = 0;


        lastWeatherData = data;
        selectedDayIndex = 0;
        // Mise à jour des variables d'affichage
        temperature = data['hourly']['temperature_2m'][index].toString();
        felt = data['hourly']['apparent_temperature'][index].toString();
        humidity = data['hourly']['relative_humidity_2m'][index].toString();
        wind = data['hourly']['wind_speed_10m'][index].toString();
        precipitation = data['hourly']['precipitation'][index].toString();
        cloud = data['hourly']['cloud_cover'][index].toString();
        // Formatage de la liste pour les prévisions
        dailyForecasts = [];
        for (int i = 0; i < data['daily']['time'].length; i++) {
          dailyForecasts.add({
            'day': data['daily']['time'][i],
            'max': data['daily']['temperature_2m_max'][i],
            'min': data['daily']['temperature_2m_min'][i],
            'code': data['daily']['weathercode'][i],
          });
        }
      });
    }
  }
}
// Met à jour les cartes de détails quand on clique sur un jour différent
  void _updateWeatherCards(int dayIndex) {
  if (lastWeatherData == null) return;

  setState(() {
      selectedDayIndex = dayIndex;
      String targetDate = lastWeatherData!['daily']['time'][dayIndex];
      String hourString;
      if (dayIndex == 0) {
        hourString = DateTime.now().hour.toString().padLeft(2, '0');
      } else {
        hourString = "12";
      }
      String targetTime = "${targetDate}T$hourString:00";
      List<dynamic> hourlyTimes = lastWeatherData!['hourly']['time'];
      int hourlyIndex = hourlyTimes.indexOf(targetTime);

    temperature = lastWeatherData!['hourly']['temperature_2m'][hourlyIndex].toString();
    felt = lastWeatherData!['hourly']['apparent_temperature'][hourlyIndex].toString();
    humidity = lastWeatherData!['hourly']['relative_humidity_2m'][hourlyIndex].toString();
    wind = lastWeatherData!['hourly']['wind_speed_10m'][hourlyIndex].toString();
    precipitation = lastWeatherData!['hourly']['precipitation'][hourlyIndex].toString();
    cloud = lastWeatherData!['hourly']['cloud_cover'][hourlyIndex].toString();
  });
}


  Map<String, String> getNextSevenDays() {
  DateTime now = DateTime.now();
  DateTime sevenDaysLater = now.add(Duration(days: 6)); 

  return {
    'start': now.toIso8601String().split('T')[0],
    'end': sevenDaysLater.toIso8601String().split('T')[0],
  };
}
// --- INTERFACE UTILISATEUR (WIDGETS) ---
@override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 54, 54, 211),
            Color(0xFF64B5F6),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _appBar(),
        body: Stack(
          children: [
            // Indicateur de chargement global via le service
            ValueListenableBuilder<bool>(
              valueListenable: WeatherService.isLoading,
              builder: (context, loading, child) {
                if (!loading) return const SizedBox.shrink();
                return Container(
                  color: Color.fromARGB(50, 255, 255, 255),
                  child: const Center(
                    child: CircularProgressIndicator()
                    ),
                );
              },
            ),
            
            SingleChildScrollView(
              child: Column(
                children: [
                  _searchBar(),
                  _nameCity(),
                  _dailyForecastList(),
                  _responsiveWheatherCard(),
                ],
              ),
            ),

           
            if (isLoading)
              Container(
                color: Color.fromARGB(10, 0, 0, 0), 
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
// Grille de détails météo responsive
  LayoutBuilder _responsiveWheatherCard() {
    return LayoutBuilder(
              builder: (context, constraints) {
                // Définit le nombre de colonnes selon la largeur de l'écran
                int crossAxisCount = constraints.maxWidth > 800 ? 6 : (constraints.maxWidth > 500 ? 3 : 2);
                
                return GridView.count(
                  
                  shrinkWrap: true,           
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  
                  childAspectRatio: 1.0, 
                  children: [
                    _buildWeatherCard(label: "Température", value: temperature, unit: "°C"),
                    _buildWeatherCard(label: "Ressenti", value: felt, unit: "°C"),
                    _buildWeatherCard(label: "Humidité", value: humidity, unit: "%"),
                    _buildWeatherCard(label: "Vent", value: wind, unit: "km/h"),
                    _buildWeatherCard(label: "Précipitations", value: precipitation, unit: "mm"),
                    _buildWeatherCard(label: "Nuages", value: cloud, unit: "%"),
                  ],
                );
              },
            );
  }



  Widget _nameCity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Text(
        cityName,
        style: const TextStyle(
          fontSize: 40,
          color: Color.fromARGB(200, 255, 255, 255),
        ),
      ),
    );
  }
  
// Barre de recherche avec icône calendrier
  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Color.fromARGB(200, 0, 0, 0), blurRadius: 40),
        ],
      ),
      child: TextField(
        onSubmitted: (value) async {
          setState(() {
          cityName = value; 
          cityName = cityName[0].toUpperCase() + cityName.substring(1).toLowerCase();
          });
          _fetchWeatherData();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une ville',
          hintStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: const Color.fromARGB(250, 255, 255, 255),
          contentPadding: const EdgeInsets.all(0),
          suffixIcon: GestureDetector(
            onTap: _pickDateRange, 
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: SvgPicture.asset('assets/icons/calendar-days-svgrepo-com.svg'),
            ),
          ),
          prefixIcon: SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: SvgPicture.asset('assets/icons/loupe-search-svgrepo-com (1).svg'),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
// Widget réutilisable pour les petites cartes de stats
  Widget _buildWeatherCard({required String label, required String value, required String unit}) {
    return Container(
      constraints: const BoxConstraints(
      minWidth: 100, 
      maxWidth: 150,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(50, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
  // Liste des prévisions journalières
  Widget _dailyForecastList() {
  if (dailyForecasts.isEmpty) return const SizedBox();

  return SizedBox(
    height: 150,
    child: Center(
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dailyForecasts.length,
        itemBuilder: (context, index) {
          var dayData = dailyForecasts[index];
          
          DateTime date = DateTime.parse(dayData['day']);
          String formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
          List<String> weekdays = ["Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."];
          String dayName = weekdays[date.weekday - 1];

          return GestureDetector(
            onTap: () => _updateWeatherCards(index),
            child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: selectedDayIndex == index 
                    ? Color.fromARGB(10, 255, 255, 255)
                    : Color.fromARGB(30, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selectedDayIndex == index ? Colors.white : Colors.transparent,
                        width: 2,
                        ),
                     ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              
                    
                    Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 8),
                    
                    Icon(
                        _getWeatherIcon(dayData['code']),
                        color: _getWeatherColor(dayData['code']),
                        size: 28, 
                      ),
                    const SizedBox(height: 8),
                    Text("${dayData['max']}°", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("${dayData['min']}°", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            
          );
        },
      ),
    ),
  );
}

  
  // --- ICONES ET COULEURS ---
// Retourne l'icône correspondante au code météo
  IconData _getWeatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code >= 1 && code <= 3) return Icons.wb_cloudy;
  if (code >= 45 && code <= 48) return Icons.foggy;
  if (code >= 51 && code <= 67) return Icons.umbrella;
  if (code >= 71 && code <= 77) return Icons.ac_unit;   
  if (code >= 80 && code <= 82) return Icons.thunderstorm; 
  if (code >= 95) return Icons.flash_on;               
  return Icons.help_outline; 
}
// Retourne la couleur de l'icône selon la météo
Color _getWeatherColor(int code) {
  if (code == 0) return Colors.yellow[600]!;
  if (code >= 1 && code <= 3) return Colors.white70;
  if (code >= 51 && code <= 82) return Colors.lightBlueAccent;
  return Colors.white;
}

AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text("Météo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

}