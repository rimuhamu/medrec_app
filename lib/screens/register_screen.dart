import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/widgets.dart';

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

      final patientData = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'address': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      if (widget.isAdminMode) {
        final patientProvider = context.read<PatientProvider>();
        success = await patientProvider.registerPatientUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          patientData: patientData,
        );
        error = patientProvider.error;
      } else {
        final auth = context.read<AuthProvider>();
        success = await auth.register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          patientData: patientData,
        );
        error = auth.error;
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          if (widget.isAdminMode) {
            AppSnackBar.showSuccess(context, 'Patient registered successfully');
            context.go('/patients');
          } else {
            context.go('/');
          }
        } else {
          AppSnackBar.showError(context, error ?? 'Registration failed');
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
                if (!widget.isAdminMode) _buildHeader(),
                _buildAccountSection(),
                const SizedBox(height: 32),
                _buildPersonalInfoSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Account Information'),
        const SizedBox(height: 16),
        AppTextField(
          controller: _usernameController,
          labelText: 'Username',
          prefixIcon: Icons.person,
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
        PasswordTextField(
          controller: _passwordController,
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
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Personal Information'),
        const SizedBox(height: 16),
        AppTextField(
          controller: _nameController,
          labelText: 'Full Name',
          prefixIcon: Icons.badge,
          validator: (val) =>
              val?.isEmpty ?? true ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _ageController,
          labelText: 'Age',
          prefixIcon: Icons.calendar_today,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please enter age';
            }
            final age = int.tryParse(val);
            if (age == null || age < 0 || age > 150) {
              return 'Please enter valid age (0-150)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _addressController,
          labelText: 'Address',
          prefixIcon: Icons.home,
          maxLines: 2,
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
        AppTextField(
          controller: _phoneController,
          labelText: 'Phone Number',
          hintText: '08123456789',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
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
      ],
    );
  }

  Widget _buildSubmitButton() {
    return LoadingButton(
      onPressed: _handleRegister,
      isLoading: _isLoading,
      label: widget.isAdminMode ? 'Register Patient' : 'Register',
    );
  }
}
