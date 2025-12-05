import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a trip with waypoints
class Trip {
  final String? id;
  final String userId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final bool visaRequired;
  final String? visaInfo;
  final List<DayItinerary> itinerary;
  final List<Waypoint> waypoints;
  final DateTime createdAt;
  final bool hasMapCache;

  Trip({
    this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.visaRequired,
    this.visaInfo,
    required this.itinerary,
    this.waypoints = const [],
    required this.createdAt,
    this.hasMapCache = false,
  });

  /// Convert Trip to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'visaRequired': visaRequired,
      'visaInfo': visaInfo,
      'itinerary': itinerary.map((day) => day.toMap()).toList(),
      'waypoints': waypoints.map((wp) => wp.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'hasMapCache': hasMapCache,
    };
  }

  /// Create Trip from Firebase document
  factory Trip.fromMap(Map<String, dynamic> map, String documentId) {
    return Trip(
      id: documentId,
      userId: map['userId'] ?? '',
      destination: map['destination'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      visaRequired: map['visaRequired'] ?? false,
      visaInfo: map['visaInfo'],
      itinerary: (map['itinerary'] as List<dynamic>?)
              ?.map((item) => DayItinerary.fromMap(item))
              .toList() ??
          [],
      waypoints: (map['waypoints'] as List<dynamic>?)
              ?.map((item) => Waypoint.fromMap(item))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      hasMapCache: map['hasMapCache'] ?? false,
    );
  }

  /// Get trip duration in days
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Get total activities count
  int get totalActivities {
    return itinerary.fold(0, (sum, day) => sum + day.activities.length);
  }

  /// Get progress percentage (0-100)
  double getProgress() {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;

    final totalDuration = endDate.difference(startDate).inDays + 1;
    final daysPassed = now.difference(startDate).inDays + 1;
    return (daysPassed / totalDuration * 100).clamp(0.0, 100.0);
  }

  /// Copy with method for updates
  Trip copyWith({
    String? id,
    String? userId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    bool? visaRequired,
    String? visaInfo,
    List<DayItinerary>? itinerary,
    List<Waypoint>? waypoints,
    DateTime? createdAt,
    bool? hasMapCache,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      visaRequired: visaRequired ?? this.visaRequired,
      visaInfo: visaInfo ?? this.visaInfo,
      itinerary: itinerary ?? this.itinerary,
      waypoints: waypoints ?? this.waypoints,
      createdAt: createdAt ?? this.createdAt,
      hasMapCache: hasMapCache ?? this.hasMapCache,
    );
  }
}

/// Model for daily itinerary
class DayItinerary {
  final int dayNumber;
  final DateTime date;
  final List<String> activities;
  final String? notes;
  final String? directions;

  DayItinerary({
    required this.dayNumber,
    required this.date,
    required this.activities,
    this.notes,
    this.directions,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'date': Timestamp.fromDate(date),
      'activities': activities,
      'notes': notes,
      'directions': directions,
    };
  }

  factory DayItinerary.fromMap(Map<String, dynamic> map) {
    return DayItinerary(
      dayNumber: map['dayNumber'] ?? 0,
      date: (map['date'] as Timestamp).toDate(),
      activities: List<String>.from(map['activities'] ?? []),
      notes: map['notes'],
      directions: map['directions'],
    );
  }

  DayItinerary copyWith({
    int? dayNumber,
    DateTime? date,
    List<String>? activities,
    String? notes,
    String? directions,
  }) {
    return DayItinerary(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
      directions: directions ?? this.directions,
    );
  }
}

/// Model for trip waypoints (for integration with Student B)
class Waypoint {
  final double latitude;
  final double longitude;
  final String name;
  final String type; // 'start', 'destination', 'poi'

  Waypoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'type': type,
    };
  }

  factory Waypoint.fromMap(Map<String, dynamic> map) {
    return Waypoint(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      name: map['name'] ?? '',
      type: map['type'] ?? 'poi',
    );
  }
}