Meteo Aquatech 🌦️
Meteo Aquatech est une application mobile moderne et performante développée avec Flutter. Elle offre une visualisation précise des conditions météorologiques en s'appuyant sur les données de l'API Open-Meteo.

✨ Fonctionnalités
🔍 Recherche Intelligente : Trouvez instantanément la météo de n'importe quelle ville grâce au service de géocodage intégré.

📊 Données Complètes : Visualisez en un clin d'œil la température actuelle, le ressenti, le taux d'humidité, la vitesse du vent, les précipitations et la nébulosité.

📅 Prévisions Flexibles : Consultez les prévisions classiques ou utilisez le sélecteur de plage de dates pour explorer la météo sur une période précise.

🎨 Interface Intuitive : Une UI soignée avec des dégradés dynamiques et des icônes SVG pour une expérience utilisateur fluide.

📱 Multiplateforme : Conçu pour fonctionner sur Android, iOS, Web et Desktop.

------------------------------------------

🚀 Installation et Lancement
Prérequis
Flutter SDK (version ^3.11.5 recommandée).

Un terminal ou un IDE configuré (VS Code / Android Studio).

Étapes:

1.Cloner le projet
- git clone https://github.com/malcolmblesa/appMeteoFlutter.git cd appMeteoFlutter
  
2.Installer les dépendances
- flutter pub get

3.Lancer l'application
- flutter run
  
------------------------------------------

🛠️ Technologies et API
Framework : Flutter

Source de données : Open-Meteo API (Géocodage et Weather API).

Packages clés :

http : Pour les requêtes API.

flutter_svg : Pour l'affichage des icônes.

google_fonts : Pour la typographie personnalisée.

------------------------------------------

📁 Structure du Projet
L'arborescence respecte la séparation des responsabilités du pattern MVVM :

lib/pages/ : Interface principale, écrans et composants visuels (UI).

lib/viewmodels/ : Logique de présentation, traitement des données pour les vues.

lib/repositories/ : Source Unique de Vérité, gestionnaire de l'état global et de la donnée brute.

lib/services/ : Service de gestion des appels API vers Open-Meteo.

assets/icons/ : Collection d'icônes SVG pour l'interface.

------------------------------------------

🤝 Contribution
Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request pour améliorer l'application.
