import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'patient_form_screen.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final int patientId;

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Patient? _patient;
  List<SaleTransaction> _history = [];
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final patientRepo = ref.read(patientRepositoryProvider);
    final prescriptionRepo = ref.read(prescriptionRepositoryProvider);

    final patient = await patientRepo.getPatientById(widget.patientId);
    final history =
        await patientRepo.getPatientTransactionHistory(widget.patientId);
    final prescriptions =
        await prescriptionRepo.getPrescriptionsForPatient(widget.patientId);

    if (!mounted) return;
    setState(() {
      _patient = patient;
      _history = history;
      _prescriptions = prescriptions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading || _patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.patientDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = _patient!;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            key: const Key('editPatientBtn'),
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PatientFormScreen(existingPatient: p),
                ),
              );
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.person), text: l10n.infoTab),
            Tab(icon: const Icon(Icons.history), text: l10n.historyTab),
            Tab(icon: const Icon(Icons.description), text: l10n.prescriptionsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(p),
          _buildHistoryTab(),
          _buildPrescriptionsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Patient p) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (p.phone != null)
                          Text('${l10n.phoneLabel}: ${p.phone}',
                              style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _detailTile(
            Icons.cake,
            l10n.dateOfBirthLabel,
            p.dateOfBirth == null
                ? null
                : '${p.dateOfBirth!.day}/${p.dateOfBirth!.month}/${p.dateOfBirth!.year}',
          ),
          _detailTile(Icons.location_on, l10n.addressLabel, p.address),
          _detailTile(Icons.warning, l10n.knownAllergiesLabel, p.allergies),
          _detailTile(
            Icons.medical_services,
            l10n.chronicConditionsLabel,
            p.chronicConditions,
          ),
          _detailTile(Icons.note, l10n.notesLabel, p.notes),
        ],
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
              Text(
                value ?? '-',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_history.isEmpty) {
      return Center(child: Text(l10n.noTxnHistoryPatient));
    }

    return ListView.builder(
      itemCount: _history.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (ctx, idx) {
        final txn = _history[idx];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
            title: Text(txn.txnNo),
            subtitle: Text(
              '${txn.createdAt.toString().split('.')[0]} • ${txn.paymentMethod}',
            ),
            trailing: Text(
              '${l10n.currencyPrefix}${txn.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_prescriptions.isEmpty) {
      return Center(child: Text(l10n.noPrescriptionsRecorded));
    }

    return ListView.builder(
      itemCount: _prescriptions.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (ctx, idx) {
        final rx = _prescriptions[idx];
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.receipt,
              color: rx.isChronic ? Colors.amber.shade700 : Colors.blue,
            ),
            title: Text('Dr. ${rx.doctorName}'),
            subtitle: Text(
              'Date: ${rx.prescriptionDate.toString().split(' ')[0]}'
              '${rx.clinicName != null ? " • ${rx.clinicName}" : ""}',
            ),
            trailing: rx.isChronic
                ? Chip(
                    label: Text(l10n.chronicBadge),
                    backgroundColor: Colors.amber,
                  )
                : null,
          ),
        );
      },
    );
  }
}
