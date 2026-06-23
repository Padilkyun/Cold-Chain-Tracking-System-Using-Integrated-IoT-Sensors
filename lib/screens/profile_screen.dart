import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  bool _isEditing = false;

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _profileService.username);
    _emailController = TextEditingController(text: _profileService.email);
    _phoneController = TextEditingController(text: _profileService.phone);
    _addressController = TextEditingController(text: _profileService.address);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileService.updateProfile(
          username: _usernameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          imagePath: pickedFile.path,
        );
      });
    }
  }

  void _saveProfile() {
    _profileService.updateProfile(
      username: _usernameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
    );
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: AppColors.primary),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileService.imagePath != null
                          ? FileImage(File(_profileService.imagePath!))
                          : null,
                      child: _profileService.imagePath == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Fields
            _buildField(
              label: 'Nama Lengkap',
              controller: _usernameController,
              icon: Icons.person_outline,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Nomor Telepon',
              controller: _phoneController,
              icon: Icons.phone_android_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Alamat',
              controller: _addressController,
              icon: Icons.location_on_outlined,
              enabled: _isEditing,
              maxLines: 2,
            ),
            
            const SizedBox(height: 40),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textGrey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: enabled ? AppColors.primary : AppColors.textGrey, size: 20),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
