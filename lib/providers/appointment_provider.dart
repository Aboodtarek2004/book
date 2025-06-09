import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  Stream<QuerySnapshot> userAppointments(String userId) {
    return _db.appointments.where('userId', isEqualTo: userId).snapshots();
  }

  Future<void> bookAppointment(
    String userId,
    String doctorId,
    String service,
    DateTime dateTime,
  ) async {
    await _db.bookAppointment(userId, service, dateTime, doctorId);
  }
}
