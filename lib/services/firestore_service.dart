import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get doctors => _db.collection('doctors');
  CollectionReference get appointments => _db.collection('appointments');

  Future<void> bookAppointment(String userId, String service, DateTime dateTime,
      String doctorId) {
    return appointments.add({
      'userId': userId,
      'service': service,
      'doctorId': doctorId,
      'dateTime': dateTime,
    });
  }
}
