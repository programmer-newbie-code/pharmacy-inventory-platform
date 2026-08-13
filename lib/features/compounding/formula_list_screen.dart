import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'formula_editor_screen.dart';

final formulaListFutureProvider =
    FutureProvider.autoDispose<List<CompoundingFormula>>((ref) {
  final repo = ref.watch(compoundingRepositoryProvider);
  return repo.listFormulas();
});

class FormulaListScreen extends ConsumerStatefulWidget {
  const FormulaListScreen({super.key});

  @override
  ConsumerState<FormulaListScreen> createState() => _FormulaListScreenState();
}

class _FormulaListScreenState extends ConsumerState<FormulaListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formulaListAsync = ref.watch(formulaListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compoundingFormulasTitle),
        actions: [
          IconButton(
            key: const Key('addFormulaBtn'),
            icon: const Icon(Icons.add),
            tooltip: l10n.addFormulaButton,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FormulaEditorScreen()),
              );
              ref.invalidate(formulaListFutureProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('formulaSearchInput'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchFormulasHint,
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
            child: formulaListAsync.when(
              data: (formulas) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? formulas
                    : formulas
                        .where((f) => f.name.toLowerCase().contains(query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formulas.isEmpty
                              ? 'No compounding formulas created yet.'
                              : 'No formulas match your search.',
                        ),
                        if (formulas.isEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            key: const Key('addFirstFormulaBtn'),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.createFirstFormulaButton),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FormulaEditorScreen(),
                                ),
                              );
                              ref.invalidate(formulaListFutureProvider);
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
                    final f = filtered[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.science),
                      ),
                      title: Text(f.name),
                      subtitle: Text(
                        'Form: ${f.dosageForm.toUpperCase()} • Yield: ${f.yieldQuantity} ${f.yieldUnit}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
