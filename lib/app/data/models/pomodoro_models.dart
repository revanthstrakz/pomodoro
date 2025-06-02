import 'package:flutter/material.dart';

enum SessionType { work, shortBreak, longBreak }

class PomodoroSettings {
  final int workTime; // in minutes
  final int shortBreakTime; // in minutes
  final int longBreakTime; // in minutes
  final int sessionsBeforeLongBreak;

  const PomodoroSettings({
    required this.workTime,
    required this.shortBreakTime,
    required this.longBreakTime,
    required this.sessionsBeforeLongBreak,
  });

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    return PomodoroSettings(
      workTime: json['workTime'] as int,
      shortBreakTime: json['shortBreakTime'] as int,
      longBreakTime: json['longBreakTime'] as int,
      sessionsBeforeLongBreak: json['sessionsBeforeLongBreak'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workTime': workTime,
      'shortBreakTime': shortBreakTime,
      'longBreakTime': longBreakTime,
      'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
    };
  }

  PomodoroSettings copyWith({
    int? workTime,
    int? shortBreakTime,
    int? longBreakTime,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroSettings(
      workTime: workTime ?? this.workTime,
      shortBreakTime: shortBreakTime ?? this.shortBreakTime,
      longBreakTime: longBreakTime ?? this.longBreakTime,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }
}

class PomodoroSession {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final SessionType type;
  final int duration; // in seconds
  final int targetDuration; // in seconds
  final bool completed;

  PomodoroSession({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.duration,
    required this.targetDuration,
    required this.completed,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      type: SessionType.values.byName(json['type'] as String),
      duration: json['duration'] as int,
      targetDuration: json['targetDuration'] as int,
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'duration': duration,
      'targetDuration': targetDuration,
      'completed': completed,
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get typeLabel {
    switch (type) {
      case SessionType.work:
        return 'Work';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  Color getTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case SessionType.work:
        return colorScheme.primary;
      case SessionType.shortBreak:
        return colorScheme.tertiary;
      case SessionType.longBreak:
        return colorScheme.secondary;
    }
  }
}

class PomodoroDay {
  final DateTime date;
  final List<PomodoroSession> sessions;

  PomodoroDay({required this.date, required this.sessions});

  factory PomodoroDay.fromJson(Map<String, dynamic> json) {
    return PomodoroDay(
      date: DateTime.parse(json['date'] as String),
      sessions: (json['sessions'] as List)
          .map((e) => PomodoroSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };
  }

  int get totalWorkDuration {
    return sessions
        .where((s) => s.type == SessionType.work)
        .fold(0, (sum, session) => sum + session.duration);
  }

  String get formattedTotalWorkDuration {
    final total = totalWorkDuration;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    return hours > 0 ? '$hours h $minutes min' : '$minutes min';
  }

  int get completedSessions {
    return sessions
        .where((s) => s.type == SessionType.work && s.completed)
        .length;
  }
}
