import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/home.dart';
import 'services/weather_service.dart';
import 'repositories/weather_repository.dart';

void main() {
  //Création du service pur
  final weatherService = WeatherService();

  //Injection du service dans la Source Unique de Vérité
  final weatherRepository = WeatherRepository(weatherService);
  //Lancement de l'app avec la donnée injectée
  runApp(MyApp(repository: weatherRepository));
}

class MyApp extends StatelessWidget {
  final WeatherRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Météo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), 
        Locale('fr'), 
      ],
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: HomePage(repository: repository),
    );
  }
}