import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/profile_storage_helper.dart';
import '../widgets/profile_form_fields.dart';
import '../services/admin_notification_store.dart';
import '../widgets/responsive_secondary_scaffold.dart';
import '../widgets/kyc_upload_field.dart';
import '../services/auth_service.dart';
import '../utils/blob_storage.dart';
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Local state
  bool _isLoading = true;
  Uint8List? _profileImageBytes;
  bool _kycUploaded = false;
  String? _kycFileName;
  Uint8List? _kycDocumentBytes;
  bool _kycRemoved = false;

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
    final phone = AuthService().currentPhone;
    if (phone == null) return;

    final name = await ProfileStorageHelper.getProfileField(phone, 'user_name');
    final email =
        await ProfileStorageHelper.getProfileField(phone, 'user_email');
    final city = await ProfileStorageHelper.getProfileField(phone, 'user_city');
    final dob = await ProfileStorageHelper.getProfileField(phone, 'user_dob');
    final prefs = await SharedPreferences.getInstance();
    
    final blob = BlobStorage();
    final kycBytes = await blob.get('$phone/kyc');
    final kycUploaded = kycBytes != null;
    final kycFileName = prefs.getString('kyc_file_name_$phone');

    setState(() {
      _nameController.text = name ?? '';
      _emailController.text = email ?? '';
      _addressController.text = city ?? '';
      _dobController.text = dob ?? '';
      _mobileController.text = phone; // Actually display the logged in phone!
      _kycUploaded = kycUploaded;
      _kycFileName = kycFileName;
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
    final phone = AuthService().currentPhone;
    if (phone == null) return;

    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _addressController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name, Email, and City are required.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_kycUploaded && _kycDocumentBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a KYC document'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await ProfileStorageHelper.saveProfileField(
        phone, 'user_name', _nameController.text.trim());
    await ProfileStorageHelper.saveProfileField(
        phone, 'user_email', _emailController.text.trim());
    await ProfileStorageHelper.saveProfileField(
        phone, 'user_city', _addressController.text.trim());
    await ProfileStorageHelper.saveProfileField(
        phone, 'user_dob', _dobController.text.trim());
        
    final prefs = await SharedPreferences.getInstance();
    final blob = BlobStorage();
    if (_kycDocumentBytes != null) {
      await blob.put('$phone/kyc', _kycDocumentBytes!);
      await prefs.setBool('kyc_uploaded_$phone', true);
      if (_kycFileName != null) {
        await prefs.setString('kyc_file_name_$phone', _kycFileName!);
      }
    } else if (_kycRemoved) {
      await blob.delete('$phone/kyc');
      await prefs.setBool('kyc_uploaded_$phone', false);
      await prefs.remove('kyc_file_name_$phone');
    }

    if (mounted) {
      final fullName = _nameController.text.trim();
      AdminNotificationStore().addNotification('Profile updated: $fullName updated their profile details', 'profile_edit');
      
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
                        const SizedBox(height: 24),
                        KycUploadField(
                          initialFileName: _kycUploaded ? (_kycFileName ?? 'document.pdf') : null,
                          onChanged: (fileName, bytes) {
                            if (bytes != null) {
                              _kycFileName = fileName;
                              _kycDocumentBytes = bytes;
                              _kycRemoved = false;
                            } else {
                              _kycFileName = null;
                              _kycDocumentBytes = null;
                              _kycUploaded = false;
                              _kycRemoved = true;
                            }
                            setState(() {});
                          },
                        ),
                        if (!_kycUploaded && _kycDocumentBytes == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Please upload a KYC document',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
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
