import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';

final patientListFutureProvider = FutureProvider.autoDispose<List<Patient>>((ref) {
  final repo = ref.watch(patientRepositoryProvider);
  return repo.listPatients();
});

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientListAsync = ref.watch(patientListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Directory'),
        actions: [
          IconButton(
            key: const Key('addPatientBtn'),
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Patient',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PatientFormScreen()),
              );
              ref.invalidate(patientListFutureProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('patientSearchInput'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: patientListAsync.when(
              data: (patients) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? patients
                    : patients.where((p) {
                        final n = p.name.toLowerCase();
                        final ph = (p.phone ?? '').toLowerCase();
                        return n.contains(query) || ph.contains(query);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          patients.isEmpty
                              ? 'No patients added yet.'
                              : 'No patients match your search.',
                        ),
                        if (patients.isEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            key: const Key('addFirstPatientBtn'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Patient'),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PatientFormScreen(),
                                ),
                              );
                              ref.invalidate(patientListFutureProvider);
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final p = filtered[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        [
                          if (p.phone != null) 'Phone: ${p.phone}',
                          if (p.chronicConditions != null)
                            'Chronic: ${p.chronicConditions}',
                          if (p.allergies != null) 'Allergies: ${p.allergies}',
                        ].join(' • '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PatientDetailScreen(patientId: p.id),
                          ),
                        );
                        ref.invalidate(patientListFutureProvider);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
