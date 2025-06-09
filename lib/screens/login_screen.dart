import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isDoctor = false;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ToggleButtons(
                isSelected: [!isDoctor, isDoctor],
                onPressed: (index) {
                  setState(() => isDoctor = index == 1);
                },
                borderRadius: BorderRadius.circular(8),
                children: const [Text('Patient'), Text('Doctor')],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 16),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await context
                          .read<AuthProvider>()
                          .signIn(_emailController.text, _passwordController.text);
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => Dashboard(isDoctor: isDoctor)),
                        );
                      }
                    } catch (e) {
                      setState(() => _error = 'Login failed');
                    }
                  }
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
