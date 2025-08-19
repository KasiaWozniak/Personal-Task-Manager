// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Menedżer Zadań Osobistych';

  @override
  String get taskListEmpty => 'Brak zadań!';

  @override
  String get tasksTab => 'Zadania';

  @override
  String get statsTab => 'Statystyki';

  @override
  String get settingsTab => 'Ustawienia';

  @override
  String get addTask => 'Dodaj zadanie';

  @override
  String get editTask => 'Edytuj zadanie';

  @override
  String get title => 'Tytuł';

  @override
  String get description => 'Opis';

  @override
  String get deadline => 'Termin';

  @override
  String get save => 'Zapisz';

  @override
  String get completedTasks => 'Wykonane zadania';

  @override
  String get restore => 'Przywróć';

  @override
  String get delete => 'Usuń';

  @override
  String totalCompleted(Object count) {
    return 'Łącznie wykonanych: $count';
  }
}
