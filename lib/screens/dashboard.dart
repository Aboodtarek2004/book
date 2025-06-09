import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../models/doctor.dart';
import 'booking_screen.dart';

class Dashboard extends StatelessWidget {
  final bool isDoctor;
  const Dashboard({super.key, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Welcome, ${user.email}',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final doctors = docs
                    .map((d) => Doctor(
                        id: d.id,
                        name: d['name'],
                        specialty: d['specialty']))
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final doc in doctors)
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(doc.name),
                          subtitle: Text(doc.specialty),
                          onTap: () {
                            if (!isDoctor) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(doctor: doc),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
