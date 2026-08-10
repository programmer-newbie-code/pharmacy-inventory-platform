import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../data/pharmacy_settings_service.dart';
import '../../data/receipt_storage_service.dart';
import '../../l10n/app_localizations.dart';

class PharmacyBrandingDialog extends ConsumerStatefulWidget {
  const PharmacyBrandingDialog({super.key});

  @override
  ConsumerState<PharmacyBrandingDialog> createState() => _PharmacyBrandingDialogState();
}

class _PharmacyBrandingDialogState extends ConsumerState<PharmacyBrandingDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _receiptDirController = TextEditingController();
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
    final receiptStorage = ref.read(receiptStorageServiceProvider);
    final customReceiptDir = await receiptStorage.getCustomBaseDirectoryPath();

    setState(() {
      _nameController.text = settings.name;
      _addressController.text = settings.address;
      _phoneController.text = settings.phone;
      _logoPath = settings.logoPath;
      if (customReceiptDir != null) {
        _receiptDirController.text = customReceiptDir;
      }
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

    final receiptStorage = ref.read(receiptStorageServiceProvider);
    await receiptStorage.setCustomBaseDirectoryPath(_receiptDirController.text.trim());

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pharmacy branding, logo, and receipt folder updated!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.brandingTitle),
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
                                Icon(Icons.add_a_photo, size: 32, color: AppTheme.primaryColor),
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
                    decoration: InputDecoration(labelText: l10n.pharmacyNameLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('brandingAddressInput'),
                    controller: _addressController,
                    decoration: InputDecoration(labelText: l10n.pharmacyAddressLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('brandingPhoneInput'),
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: l10n.pharmacyPhoneLabel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('receiptDirInput'),
                    controller: _receiptDirController,
                    decoration: InputDecoration(
                      labelText: 'Receipt Folder Path (Optional)',
                      hintText: 'Default: Documents/PharmaLoka/Receipts/',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () async {
                          final selectedDir = await FilePicker.platform.getDirectoryPath();
                          if (selectedDir != null) {
                            setState(() => _receiptDirController.text = selectedDir);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          key: const Key('saveBrandingBtn'),
          onPressed: _saveSettings,
          child: Text(l10n.saveBranding),
        ),
      ],
    );
  }
}
