import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Tytuł aplikacji (weźmie go z tłumaczeń)
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      // Lista obsługiwanych języków
      supportedLocales: const [
        Locale('en'), // angielski
        Locale('pl'), // polski
      ],

      // Delegaty lokalizacyjne (wymagane)
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Domyślny język aplikacji
      locale: const Locale('pl'),

      // Domyślna strona aplikacji
      home: const HomeScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
