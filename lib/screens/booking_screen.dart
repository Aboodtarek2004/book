import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../models/doctor.dart';

class BookingScreen extends StatefulWidget {
  final Doctor doctor;
  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selected = DateTime.now();
  String _service = 'Consultation';
  final services = const ['Consultation', 'Follow-up'];

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctor.name, style: Theme.of(context).textTheme.titleLarge),
            Text(widget.doctor.specialty),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Date: ${_selected.toLocal()}'),
              trailing: TextButton(
                child: const Text('Select'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selected,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selected),
                    );
                    if (time != null) {
                      setState(() {
                        _selected = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ),
            DropdownButton<String>(
              value: _service,
              onChanged: (value) => setState(() => _service = value!),
              items: [for (final s in services) DropdownMenuItem(value: s, child: Text(s))],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (user != null) {
                    context.read<AppointmentProvider>().bookAppointment(
                          user.uid,
                          widget.doctor.id,
                          _service,
                          _selected,
                        );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
