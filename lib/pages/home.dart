import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../repositories/weather_repository.dart';
import '../viewmodels/home_view_model.dart';

class HomePage extends StatefulWidget {
  final WeatherRepository repository;

  const HomePage({super.key, required this.repository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      locale: const Locale("fr", "FR"),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      saveText: 'Valider',
      builder: (context, child) => Column(
        children: [ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400.0), child: child)],
      ),
    );

    if (picked != null) {
      _viewModel.setDateRange(picked); // On délègue l'action au ViewModel
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 54, 54, 211), Color(0xFF64B5F6)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _appBar(),
        // TOUT est encapsulé dans l'AnimatedBuilder qui écoute le ViewModel
        body: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Stack(
              children: [
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
                // Overlay de chargement réactif
                if (_viewModel.isLoading)
                  Container(
                    color: const Color.fromARGB(50, 0, 0, 0),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _nameCity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Text(
        _viewModel.cityName, // Lecture depuis le ViewModel
        style: const TextStyle(fontSize: 40, color: Color.fromARGB(200, 255, 255, 255)),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color.fromARGB(200, 0, 0, 0), blurRadius: 40)],
      ),
      child: Autocomplete<Map<String, dynamic>>(
        //Va prendre les data par le ViewModel
        optionsBuilder: (TextEditingValue textEditingValue) async {
          return await _viewModel.searchCitySuggestions(textEditingValue.text);
        },
        //Définit ce qui s'affiche quand sélectionné
        displayStringForOption: (option) => option['name'] as String,
        // clic sur une ville
        onSelected: (option) {
          _viewModel.selectCityFromSuggestion(option);
          FocusScope.of(context).unfocus(); 
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            decoration: InputDecoration(
              hintText: 'Rechercher une ville',
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
                  borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          );
        },
        //Le design du menu déroulant
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.white,
              elevation: 4.0,
              borderRadius: BorderRadius.circular(15),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 250,
                  maxWidth: MediaQuery.of(context).size.width - 40, 
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    // Formatage des data sous le titre
                    final country = option['country'] ?? '';
                    final region = option['admin1'] != null && option['admin1'].toString().isNotEmpty ? '${option['admin1']} - ' : '';
                    final postcode = option['postcode'] != null ? ' (${option['postcode']})' : '';

                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Color.fromARGB(255, 64, 141, 235)),
                      title: Text(
                        option['name'], 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(
                        '$region$country$postcode', 
                        style: const TextStyle(fontSize: 12)
                      ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  LayoutBuilder _responsiveWheatherCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 6 : (constraints.maxWidth > 500 ? 3 : 2);
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          childAspectRatio: 1.0,
          children: [
            _buildWeatherCard(label: "Température", value: _viewModel.temperature, unit: "°C"),
            _buildWeatherCard(label: "Ressenti", value: _viewModel.felt, unit: "°C"),
            _buildWeatherCard(label: "Humidité", value: _viewModel.humidity, unit: "%"),
            _buildWeatherCard(label: "Vent", value: _viewModel.wind, unit: "km/h"),
            _buildWeatherCard(label: "Précipitations", value: _viewModel.precipitation, unit: "mm"),
            _buildWeatherCard(label: "Nuages", value: _viewModel.cloud, unit: "%"),
          ],
        );
      },
    );
  }

  Widget _buildWeatherCard({required String label, required String value, required String unit}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
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

  Widget _dailyForecastList() {
    final forecasts = _viewModel.dailyForecasts;
    if (forecasts.isEmpty) return const SizedBox();

    return SizedBox(
      height: 150,
      child: Center(
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: forecasts.length,
          itemBuilder: (context, index) {
            var dayData = forecasts[index];
            DateTime date = DateTime.parse(dayData['day']);
            String formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
            List<String> weekdays = ["Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim."];
            String dayName = weekdays[date.weekday - 1];

            bool isSelected = _viewModel.selectedDayIndex == index;

            return GestureDetector(
              onTap: () => _viewModel.selectDay(index),
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromARGB(10, 255, 255, 255) : const Color.fromARGB(30, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 8),
                    Icon(_getWeatherIcon(dayData['code']), color: _getWeatherColor(dayData['code']), size: 28),
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