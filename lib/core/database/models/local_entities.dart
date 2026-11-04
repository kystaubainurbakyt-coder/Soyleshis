/// Local entities use stable string IDs; lesson IDs match the authored curriculum.
class LearnerRecord {
  const LearnerRecord({
    required this.id,
    required this.name,
    required this.learningData,
  });
  final String id, name;
  final Map<String, dynamic> learningData;
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'learningData': learningData,
  };
  factory LearnerRecord.fromMap(Map<String, dynamic> m) => LearnerRecord(
    id: m['id'] as String,
    name: m['name'] as String,
    learningData: Map<String, dynamic>.from(m['learningData'] as Map),
  );
}

class CourseRecord {
  const CourseRecord({required this.id, required this.position});
  final String id;
  final int position;
  Map<String, dynamic> toMap() => {'id': id, 'position': position};
  factory CourseRecord.fromMap(Map<String, dynamic> m) =>
      CourseRecord(id: m['id'] as String, position: m['position'] as int);
}

class FavoriteRecord {
  const FavoriteRecord({required this.ownerId, required this.lessonId});
  final String ownerId;
  final int lessonId;
  String get id => '$ownerId/$lessonId';
  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'lessonId': lessonId,
  };
  factory FavoriteRecord.fromMap(Map<String, dynamic> m) => FavoriteRecord(
    ownerId: m['ownerId'] as String,
    lessonId: m['lessonId'] as int,
  );
}

class LessonProgressRecord {
  const LessonProgressRecord({
    required this.ownerId,
    required this.lessonId,
    required this.score,
    required this.completed,
  });
  final String ownerId;
  final int lessonId, score;
  final bool completed;
  String get id => '$ownerId/$lessonId';
  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'lessonId': lessonId,
    'score': score,
    'completed': completed,
  };
  factory LessonProgressRecord.fromMap(Map<String, dynamic> m) =>
      LessonProgressRecord(
        ownerId: m['ownerId'] as String,
        lessonId: m['lessonId'] as int,
        score: m['score'] as int,
        completed: m['completed'] as bool,
      );
}

class StudyNote {
  const StudyNote({
    required this.id,
    required this.ownerId,
    required this.lessonId,
    required this.title,
    required this.body,
    required this.priority,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, ownerId, title, body;
  final int lessonId, priority;
  final bool favorite;
  final DateTime createdAt, updatedAt;
  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'lessonId': lessonId,
    'title': title,
    'body': body,
    'priority': priority,
    'favorite': favorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory StudyNote.fromMap(Map<String, dynamic> m) => StudyNote(
    id: m['id'] as String,
    ownerId: m['ownerId'] as String,
    lessonId: m['lessonId'] as int,
    title: m['title'] as String,
    body: m['body'] as String,
    priority: m['priority'] as int,
    favorite: m['favorite'] as bool,
    createdAt: DateTime.parse(m['createdAt'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
  );
}

enum NoteSort { updated, title, priority }
