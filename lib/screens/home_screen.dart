import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import 'appointment_form_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return ListTile(
            title: Text(appointment.service),
            subtitle: Text(appointment.dateTime.toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AppointmentFormScreen(appointment: appointment),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    context.read<AppointmentProvider>().removeAppointment(appointment);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppointmentFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
