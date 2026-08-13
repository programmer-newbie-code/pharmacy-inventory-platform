import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.existingPatient});

  final Patient? existingPatient;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicConditionsController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    if (widget.existingPatient != null) {
      final p = widget.existingPatient!;
      _nameController.text = p.name;
      _phoneController.text = p.phone ?? '';
      _addressController.text = p.address ?? '';
      _allergiesController.text = p.allergies ?? '';
      _chronicConditionsController.text = p.chronicConditions ?? '';
      _notesController.text = p.notes ?? '';
      _dateOfBirth = p.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.patientNameRequired)),
      );
      return;
    }

    final repo = ref.read(patientRepositoryProvider);
    if (widget.existingPatient == null) {
      await repo.createPatient(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        chronicConditions: _chronicConditionsController.text.trim().isEmpty
            ? null
            : _chronicConditionsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    } else {
      await repo.updatePatient(
        id: widget.existingPatient!.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        chronicConditions: _chronicConditionsController.text.trim().isEmpty
            ? null
            : _chronicConditionsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existingPatient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editPatientTitle : l10n.addPatientTitle),
        actions: [
          TextButton(
            key: const Key('savePatientBtn'),
            onPressed: _save,
            child: Text(l10n.saveButton),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('patientNameInput'),
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.patientNameRequiredLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('patientPhoneInput'),
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.phoneLabel),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateOfBirthLabel,
                  border: const OutlineInputBorder(),
                ),
                child: Text(
                  _dateOfBirth == null
                      ? '${l10n.dateOfBirthLabel}...'
                      : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: l10n.addressLabel),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('patientAllergiesInput'),
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: l10n.knownAllergiesLabel,
                hintText: l10n.allergiesHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('patientChronicConditionsInput'),
              controller: _chronicConditionsController,
              decoration: InputDecoration(
                labelText: l10n.chronicConditionsLabel,
                hintText: l10n.chronicConditionsHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.notesLabel),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
