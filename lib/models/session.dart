import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String id;
  final String userId;
  final String categoryId;
  final String description;
  final DateTime startTime;
  final int duration;
  final DateTime? endTime;

  Session({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.description,
    required this.startTime,
    required this.duration,
    this.endTime,
  });

  factory Session.fromMap(String id, Map<String, dynamic> map) {
    return Session(
      id: id,
      userId: map['userId'] as String,
      categoryId: map['categoryId'] as String,
      description: map['description'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      duration: map['duration'] as int,
      endTime:
          map['endTime'] != null
              ? (map['endTime'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'duration': duration,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }
}
