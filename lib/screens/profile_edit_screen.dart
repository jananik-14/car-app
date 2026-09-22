import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/profile_storage_helper.dart';
import '../widgets/profile_form_fields.dart';
import '../widgets/responsive_secondary_scaffold.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Local state
  bool _isLoading = true;
  Uint8List? _profileImageBytes;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final phone = await ProfileStorageHelper.getCurrentLoggedInPhone();
    if (phone == null) return;

    final name = await ProfileStorageHelper.getProfileField(phone, 'user_name');
    final email =
        await ProfileStorageHelper.getProfileField(phone, 'user_email');
    final city = await ProfileStorageHelper.getProfileField(phone, 'user_city');
    final dob = await ProfileStorageHelper.getProfileField(phone, 'user_dob');

    setState(() {
      _nameController.text = name ?? '';
      _emailController.text = email ?? '';
      _addressController.text = city ?? '';
      _dobController.text = dob ?? '';
      _mobileController.text = phone; // Actually display the logged in phone!
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final phone = await ProfileStorageHelper.getCurrentLoggedInPhone();
    if (phone == null) return;

    await ProfileStorageHelper.saveProfileField(
        phone, 'user_name', _nameController.text.trim());
    await ProfileStorageHelper.saveProfileField(
        phone, 'user_email', _emailController.text.trim());
    await ProfileStorageHelper.saveProfileField(
        phone, 'user_city', _addressController.text.trim());
    await ProfileStorageHelper.saveProfileField(
        phone, 'user_dob', _dobController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSecondaryScaffold(
      currentIndex: 4,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfileFormFields(
                          nameController: _nameController,
                          emailController: _emailController,
                          cityController: _addressController,
                          dobController: _dobController,
                          mobileController: _mobileController,
                          initialProfileImageBytes: _profileImageBytes,
                          onImageChanged: (file, bytes) {
                            _profileImageBytes = bytes;
                          },
                          onChanged: () {
                            // Update state if we wanted to validate
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
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
              ),
            ),
    );
  }
}
