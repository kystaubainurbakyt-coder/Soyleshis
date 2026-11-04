/// Calendar dates are stored without a timezone so daily goals survive restarts.
String learningDay(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class LearningCertificate {
  const LearningCertificate({
    required this.id,
    required this.level,
    required this.name,
    required this.email,
    required this.issuedAt,
    required this.lessonCount,
    required this.average,
  });
  final String id, level, name, email, issuedAt;
  final int lessonCount, average;
  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'name': name,
    'email': email,
    'issuedAt': issuedAt,
    'lessonCount': lessonCount,
    'average': average,
  };
  factory LearningCertificate.fromJson(Map<String, dynamic> json) =>
      LearningCertificate(
        id: json['id'] as String,
        level: json['level'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        issuedAt: json['issuedAt'] as String,
        lessonCount: json['lessonCount'] as int,
        average: json['average'] as int,
      );

  static String identifier(String email, String level) {
    var hash = 0x811c9dc5;
    for (final code in '$email/$level/course-v2'.codeUnits) {
      hash = ((hash ^ code) * 31) & 0x7fffffff;
    }
    return 'SOYLE-$level-${hash.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}

class LearningBadge {
  const LearningBadge(this.id, this.title, this.description, this.earned);
  final String id, title, description;
  final bool earned;
}

int learningStreak(Map<String, int> activity, DateTime now) {
  var cursor = DateTime.utc(now.year, now.month, now.day);
  if (!activity.containsKey(learningDay(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var count = 0;
  while (activity.containsKey(learningDay(cursor))) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}
