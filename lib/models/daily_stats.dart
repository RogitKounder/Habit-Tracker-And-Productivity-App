class DailyStats {
  int completedHabits;
  int totalMinutes;
  DateTime date;

  DailyStats({
    this.completedHabits = 0,
    this.totalMinutes = 0,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'completedHabits': completedHabits,
      'totalMinutes': totalMinutes,
      'date': date.toIso8601String(),
    };
  }

  static DailyStats fromMap(Map<String, dynamic> map) {
    return DailyStats(
      completedHabits: map['completedHabits'] ?? 0,
      totalMinutes: map['totalMinutes'] ?? 0,
      date: DateTime.parse(map['date']),
    );
  }
}