import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';

class RegisterScreen extends StatefulWidget {
  final bool isAdminMode;

  const RegisterScreen({super.key, this.isAdminMode = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      bool success;
      String? error;

      if (widget.isAdminMode) {
        final patientProvider = context.read<PatientProvider>();
        success = await patientProvider.registerPatientUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          patientData: {
            'name': _nameController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'address': _addressController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
          },
        );
        error = patientProvider.error;
      } else {
        final auth = context.read<AuthProvider>();
        success = await auth.register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          patientData: {
            'name': _nameController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'address': _addressController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
          },
        );
        error = auth.error;
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          if (widget.isAdminMode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Patient registered successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/patients');
          } else {
            context.go('/');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              widget.isAdminMode ? context.go('/') : context.go('/login'),
        ),
        title: widget.isAdminMode ? const Text('Register New Patient') : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isAdminMode) ...[
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register to manage your medical records',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter username';
                    }
                    if (val.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter password';
                    }
                    if (val.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (val) =>
                      val?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter age';
                    }
                    final age = int.tryParse(val);
                    if (age == null || age < 0 || age > 100) {
                      return 'Please enter valid age (0-100)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter address';
                    }
                    if (val.length < 10) {
                      return 'Address must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '08123456789',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (!val.startsWith('08') || val.length < 10) {
                      return 'Phone must start with 08 and be at least 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isAdminMode
                            ? 'Register Patient'
                            : 'Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
