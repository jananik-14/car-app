import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/profile_storage_helper.dart';
import '../widgets/profile_form_fields.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  bool _isFormValid = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid = true;
    String? error;

    if (_nameController.text.trim().length < 3) {
      isValid = false;
      error = 'Full Name must be at least 3 characters.';
    } else if (!_isValidEmail(_emailController.text.trim())) {
      isValid = false;
      error = 'Please enter a valid email address.';
    } else if (_cityController.text.trim().isEmpty) {
      isValid = false;
      error = 'City / Location is required.';
    }

    setState(() {
      _isFormValid = isValid;
      _errorMessage = error;
    });
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return regex.hasMatch(email);
  }

  Future<void> _saveAndContinue() async {
    if (!_isFormValid) return;

    final phone = await ProfileStorageHelper.getCurrentLoggedInPhone();
    if (phone == null) return; // Fallback, shouldn't happen

    await ProfileStorageHelper.saveProfileField(phone, 'user_name', _nameController.text.trim());
    await ProfileStorageHelper.saveProfileField(phone, 'user_email', _emailController.text.trim());
    await ProfileStorageHelper.saveProfileField(phone, 'user_city', _cityController.text.trim());
    await ProfileStorageHelper.saveProfileField(phone, 'user_dob', _dobController.text.trim());
    await ProfileStorageHelper.setProfileComplete(phone);
    
    if (mounted) {
      context.go('/terms');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false, // No back button
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 48),
              const SizedBox(height: 16),
              const Text(
                'One Last Step!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need a few details before you can start bidding or selling',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              ProfileFormFields(
                nameController: _nameController,
                emailController: _emailController,
                cityController: _cityController,
                dobController: _dobController,
                onImageChanged: (file, bytes) {
                  _profileImage = file;
                  _profileImageBytes = bytes;
                },
                onChanged: _validateForm,
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer, // orange #fb7800
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
