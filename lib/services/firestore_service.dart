import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

/// Service to handle Firestore database operations for trips
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _tripsCollection = 'trips';

  /// Create a new trip
  Future<String?> createTrip(Trip trip) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_tripsCollection)
          .add(trip.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Error creating trip: $e');
      return null;
    }
  }

  /// Get all trips for a specific user
  Stream<List<Trip>> getUserTrips(String userId) {
    return _firestore
        .collection(_tripsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Trip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get a specific trip by ID
  Future<Trip?> getTrip(String tripId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .get();

      if (doc.exists) {
        return Trip.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting trip: $e');
      return null;
    }
  }

  /// Update an existing trip
  Future<bool> updateTrip(Trip trip) async {
    try {
      if (trip.id == null) return false;

      await _firestore
          .collection(_tripsCollection)
          .doc(trip.id)
          .update(trip.toMap());

      return true;
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  /// Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting trip: $e');
      return false;
    }
  }

  /// Get upcoming trips for a user
  Stream<List<Trip>> getUpcomingTrips(String userId) {
    return _firestore
        .collection(_tripsCollection)
        .where('userId', isEqualTo: userId)
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('endDate')
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Trip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get past trips for a user
  Stream<List<Trip>> getPastTrips(String userId) {
    return _firestore
        .collection(_tripsCollection)
        .where('userId', isEqualTo: userId)
        .where('endDate', isLessThan: Timestamp.now())
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Trip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get trip count for a user
  Future<int> getUserTripCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_tripsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting trip count: $e');
      return 0;
    }
  }
}