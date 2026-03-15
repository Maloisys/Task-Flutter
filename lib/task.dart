class Task {
  int? id;
  String title;
  DateTime created;
  Duration duration;
  bool completed;
  DateTime? deadline;
  int priority;

  Task({
    this.id,
    required this.title,
    required this.created,
    this.duration = Duration.zero,
    this.completed = false,
    this.deadline,
    this.priority = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created': created.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'completed': completed ? 1 : 0,
      'deadline': deadline?.millisecondsSinceEpoch,
      'priority': priority,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      created: DateTime.fromMillisecondsSinceEpoch(map['created']),
      duration: Duration(milliseconds: map['duration']),
      completed: map['completed'] == 1,
      deadline: map['deadline'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'])
          : null,
      priority: map['priority'],
    );
  }

  Task copyWith({
    int? id,
    String? title,
    DateTime? created,
    Duration? duration,
    bool? completed,
    DateTime? deadline,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      created: created ?? this.created,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
    );
  }
}