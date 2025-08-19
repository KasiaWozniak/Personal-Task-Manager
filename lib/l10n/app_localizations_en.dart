// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Personal Task Manager';

  @override
  String get taskListEmpty => 'No tasks yet!';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get statsTab => 'Statistics';

  @override
  String get settingsTab => 'Settings';

  @override
  String get addTask => 'Add Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get deadline => 'Deadline';

  @override
  String get save => 'Save';

  @override
  String get completedTasks => 'Completed Tasks';

  @override
  String get restore => 'Restore';

  @override
  String get delete => 'Delete';

  @override
  String totalCompleted(Object count) {
    return 'Total completed: $count';
  }
}
