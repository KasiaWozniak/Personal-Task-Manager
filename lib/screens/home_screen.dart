import 'package:flutter/material.dart';
import 'package:task_manager/l10n/app_localizations.dart';
import 'package:task_manager/data/task_database.dart';
import 'package:task_manager/models/task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:task_manager/screens/stats_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<List<Task>> _tasksNotifier = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _requestNotificationPermission();
    _loadTasks();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    print('Notification permission status: \\${status}');
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> scheduleTaskNotification(Task task) async {
    print('scheduleTaskNotification called for task: \\${task.title}, deadline: \\${task.date}');
    final deadline = DateTime.parse(task.date);
    final notificationTime = deadline.subtract(const Duration(days: 1));
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647; // poprawka: ID mieści się w zakresie 32-bit int

    print('Parsed deadline: \\${deadline.toIso8601String()}');
    print('Notification should be scheduled for: \\${notificationTime.toIso8601String()}');
    print('Current time: \\${DateTime.now().toIso8601String()}');
    String formattedDeadline = '';
    try {
      final deadlineDate = DateTime.parse(task.date);
      formattedDeadline = '${deadlineDate.day.toString().padLeft(2, '0')}.${deadlineDate.month.toString().padLeft(2, '0')}.${deadlineDate.year} ${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      formattedDeadline = task.date;
    }
    final notificationBody = 'Zadanie: ${task.title}\nDeadline: ${formattedDeadline}';

    const androidDetails = AndroidNotificationDetails(
      'task_channel', 'Zadania',
      channelDescription: 'Przypomnienia o zadaniach',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    if (notificationTime.isBefore(DateTime.now())) {
      // Powiadomienie natychmiastowe
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Przypomnienie o zadaniu',
        notificationBody,
        notificationDetails,
      );
      print('Natychmiastowe powiadomienie wysłane dla zadania: ${task.title}');
      return;
    }

    final tzTime = tz.TZDateTime.from(notificationTime, tz.local);
    print('Final tzTime for notification: \\${tzTime.toString()}');
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Przypomnienie o zadaniu',
        notificationBody,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Exact notification scheduled for task: ${task.title}');
    } catch (e) {
      print('Exact alarm not permitted, falling back to inexact. Error: \\${e.toString()}');
      // Otwórz ustawienia exact alarm
      await openExactAlarmSettings();
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Przypomnienie o zadaniu',
        notificationBody,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('Inexact notification scheduled for task: ${task.title}');
    }
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskDatabase.instance.readAllTasks();
    _tasksNotifier.value = tasks;
  }

  Future<void> _refreshTasks() async {
    await _loadTasks();
  }

  Future<void> _toggleTaskDone(Task task) async {
    final nowIso = DateTime.now().toIso8601String();
    final updatedTask = task.copyWith(
      isDone: !task.isDone,
      doneDate: !task.isDone ? nowIso : null,
    );
    await TaskDatabase.instance.update(updatedTask);
    final idx = _tasksNotifier.value.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      final newList = List<Task>.from(_tasksNotifier.value);
      newList[idx] = updatedTask;
      _tasksNotifier.value = newList;
    }
  }

  List<Task> _getSortedTasks(List<Task> tasks, bool done) {
    final filtered = tasks.where((t) => t.isDone == done).toList();
    filtered.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    return filtered;
  }

  Future<void> _addTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.addTask),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.deadline + ': '),
                        Text(selectedDate == null ? '-' : selectedDate!.toIso8601String().substring(0, 10)),
                        IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Godzina: '),
                        Text(selectedTime == null ? '-' : selectedTime!.format(context)),
                        IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedTime = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.restore),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && selectedDate != null && selectedTime != null) {
                      final deadline = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      final newTask = Task(
                        title: titleController.text,
                        description: descriptionController.text,
                        date: deadline.toIso8601String(),
                      );
                      await TaskDatabase.instance.create(newTask);
                      await scheduleTaskNotification(newTask);
                      await _loadTasks();
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDate = DateTime.parse(task.date);
    TimeOfDay selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edytuj zadanie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.deadline + ': '),
                        Text(selectedDate.toIso8601String().substring(0, 10)),
                        IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Godzina: '),
                        Text(selectedTime.format(context)),
                        IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedTime = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.restore),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final deadline = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final updatedTask = task.copyWith(
                        title: titleController.text,
                        description: descriptionController.text,
                        date: deadline.toIso8601String(),
                      );
                      await TaskDatabase.instance.update(updatedTask);
                      final idx = _tasksNotifier.value.indexWhere((t) => t.id == task.id);
                      if (idx != -1) {
                        final newList = List<Task>.from(_tasksNotifier.value);
                        newList[idx] = updatedTask;
                        _tasksNotifier.value = newList;
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    await TaskDatabase.instance.delete(task.id!);
    final newList = List<Task>.from(_tasksNotifier.value)..removeWhere((t) => t.id == task.id);
    _tasksNotifier.value = newList;
  }

  Future<void> openExactAlarmSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StatsScreen(tasks: _tasksNotifier.value),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              await flutterLocalNotificationsPlugin.show(
                0,
                'Test',
                'To jest test powiadomienia',
                const NotificationDetails(
                  android: AndroidNotificationDetails('test_channel', 'Test'),
                ),
              );
              print('Test notification sent');
            },
            child: Text('Test powiadomienia'),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Task>>(
              valueListenable: _tasksNotifier,
              builder: (context, tasks, _) {
                if (tasks.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.taskListEmpty));
                }
                return ListView(
                  children: [
                    if (_getSortedTasks(tasks, false).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Aktywne zadania', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._getSortedTasks(tasks, false).map((task) => ListTile(
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(DateTime.parse(task.date).toString().substring(0, 16)), // yyyy-MM-dd HH:mm
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editTaskDialog(task),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteTask(task),
                            ),
                          ],
                        ),
                        leading: Checkbox(
                          value: task.isDone,
                          onChanged: (_) => _toggleTaskDone(task),
                        ),
                      )),
                    ],
                    if (_getSortedTasks(tasks, true).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Wykonane zadania', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._getSortedTasks(tasks, true).map((task) => ListTile(
                        title: Text(task.title, style: TextStyle(decoration: TextDecoration.lineThrough)),
                        subtitle: Text(task.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(DateTime.parse(task.date).toString().substring(0, 16)), // yyyy-MM-dd HH:mm
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editTaskDialog(task),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteTask(task),
                            ),
                          ],
                        ),
                        leading: Checkbox(
                          value: task.isDone,
                          onChanged: (_) => _toggleTaskDone(task),
                        ),
                      )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
