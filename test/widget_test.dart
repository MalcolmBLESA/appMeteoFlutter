// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:meteo_aquatech/main.dart';
import 'package:meteo_aquatech/services/weather_service.dart';
import 'package:meteo_aquatech/repositories/weather_repository.dart';

void main() {
  testWidgets('Test de chargement de l\'application Météo', (WidgetTester tester) async {
    final weatherService = WeatherService();
    final weatherRepository = WeatherRepository(weatherService);
    await tester.pumpWidget(MyApp(repository: weatherRepository));
    expect(find.text('Météo'), findsOneWidget); 
    expect(find.text('Rechercher une ville'), findsOneWidget); 
  });
}