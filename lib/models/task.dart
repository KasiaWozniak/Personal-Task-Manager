class Task {
  final int? id; // może być null przy nowym zadaniu
  final String title;
  final String description;
  final String date; // np. "2025-08-16T15:30:00"
  final bool isDone;
  final String? doneDate; // data/godzina wykonania zadania

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isDone = false,
    this.doneDate,
  });

  // zamiana Task -> Map (do SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date, // pełny ISO8601
      'isDone': isDone ? 1 : 0,
      'doneDate': doneDate,
    };
  }

  // zamiana Map -> Task (z SQLite)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: map['date'], // pełny ISO8601
      isDone: map['isDone'] == 1,
      doneDate: map['doneDate'],
    );
  }

  // umożliwia tworzenie nowego obiektu na bazie istniejącego
  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? date,
    bool? isDone,
    String? doneDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isDone: isDone ?? this.isDone,
      doneDate: doneDate ?? this.doneDate,
    );
  }
}
