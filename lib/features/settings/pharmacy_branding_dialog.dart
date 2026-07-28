import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../data/pharmacy_settings_service.dart';

class PharmacyBrandingDialog extends ConsumerStatefulWidget {
  const PharmacyBrandingDialog({super.key});

  @override
  ConsumerState<PharmacyBrandingDialog> createState() => _PharmacyBrandingDialogState();
}

class _PharmacyBrandingDialogState extends ConsumerState<PharmacyBrandingDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _logoPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(pharmacySettingsServiceProvider);
    final settings = await service.getSettings();
    setState(() {
      _nameController.text = settings.name;
      _addressController.text = settings.address;
      _phoneController.text = settings.phone;
      _logoPath = settings.logoPath;
      _isLoading = false;
    });
  }

  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  Future<void> _saveSettings() async {
    final service = ref.read(pharmacySettingsServiceProvider);
    await service.saveSettings(
      PharmacySettings(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        logoPath: _logoPath,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pharmacy branding and logo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pharmacy Branding & Logo'),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickLogoImage,
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_logoPath!), fit: BoxFit.contain),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 32, color: Colors.teal),
                                SizedBox(height: 4),
                                Text('Upload Pharmacy Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('brandingNameInput'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Pharmacy Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('brandingAddressInput'),
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('brandingPhoneInput'),
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('saveBrandingBtn'),
          onPressed: _saveSettings,
          child: const Text('Save Branding'),
        ),
      ],
    );
  }
}
