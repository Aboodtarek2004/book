import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: MaterialApp(
        title: 'Appointment Booking',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) =>
              auth.isLoggedIn ? const Dashboard(isDoctor: false) : const LoginScreen(),
        ),
      ),
    );
  }
}
