// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lolscrimapp/services/players_provider.dart';
import 'package:lolscrimapp/services/teams_provider.dart';
import 'package:lolscrimapp/services/scrims_provider.dart';
import 'package:lolscrimapp/screens/home_screen.dart';

void main() {
  testWidgets('App interface loads correctly', (WidgetTester tester) async {
    // Create a test app without database initialization
    final testApp = MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => PlayersProvider()),
          ChangeNotifierProvider(create: (context) => TeamsProvider()),
          ChangeNotifierProvider(create: (context) => ScrimsProvider()),
        ],
        child: const HomeScreen(),
      ),
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(testApp);
    await tester.pumpAndSettle();

    // Verify that our app title appears.
    expect(find.text('LoL Scrim Manager'), findsOneWidget);

    // Verify that we have the main tabs
    expect(find.text('Équipes'), findsOneWidget);
    expect(find.text('Joueurs'), findsOneWidget);
    expect(find.text('Scrims'), findsOneWidget);
    expect(find.text('Recherche'), findsOneWidget);
  });

  testWidgets('Search screen shows correctly', (WidgetTester tester) async {
    final testApp = MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => PlayersProvider()),
          ChangeNotifierProvider(create: (context) => TeamsProvider()),
          ChangeNotifierProvider(create: (context) => ScrimsProvider()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pumpWidget(testApp);
    await tester.pumpAndSettle();

    // Tap on Recherche tab
    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();

    // Verify search screen content
    expect(find.text('Recherche Statistique Avancée'), findsOneWidget);
    expect(find.text('Moteur de Requêtes Prêt'), findsOneWidget);
  });
}
