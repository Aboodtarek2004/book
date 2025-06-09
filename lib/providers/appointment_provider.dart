import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  final List<Appointment> _appointments = [];

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  void addAppointment(String service, DateTime dateTime) {
    final appointment = Appointment(
      id: const Uuid().v4(),
      service: service,
      dateTime: dateTime,
    );
    _appointments.add(appointment);
    notifyListeners();
  }

  void updateAppointment(Appointment appointment, String service, DateTime dateTime) {
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      _appointments[index].service = service;
      _appointments[index].dateTime = dateTime;
      notifyListeners();
    }
  }

  void removeAppointment(Appointment appointment) {
    _appointments.removeWhere((a) => a.id == appointment.id);
    notifyListeners();
  }
}
