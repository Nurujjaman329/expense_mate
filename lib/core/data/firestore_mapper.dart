import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts between Firestore timestamps and Dart [DateTime] for sync payloads.
class FirestoreMapper {
  FirestoreMapper._();

  static dynamic toFirestoreValue(dynamic value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    return value;
  }

  static Map<String, dynamic> toFirestoreMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, Timestamp.fromDate(value));
      }
      return MapEntry(key, value);
    });
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
