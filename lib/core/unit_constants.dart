import 'package:flutter/material.dart';

/// Predefined standard pharmaceutical base units
const List<String> defaultBaseUnits = [
  'tablet',
  'kapsul',
  'kaplet',
  'ampul',
  'vial',
  'sachet',
  'tube',
  'botol',
  'suppositoria',
  'strip',
  'pcs',
  'ml',
  'gram',
  'patch',
  'pen',
  'ovula',
  'blister',
];

/// Predefined standard pharmaceutical purchase units
const List<String> defaultPurchaseUnits = [
  'box',
  'dus',
  'pack',
  'strip',
  'botol',
  'vial',
  'ampul',
  'sachet',
  'galon',
  'pot',
  'karton',
  'pcs',
  'tube',
  'toples',
];

/// Session memory for custom user-entered units
final Set<String> customUserUnits = {};

/// Returns all combined unit suggestions (defaults + user-entered custom units)
List<String> getCombinedUnits(List<String> defaults) {
  final set = <String>{...defaults, ...customUserUnits};
  return set.toList()..sort();
}

/// Dynamic Editable Dropdown field for base unit or purchase unit input.
/// Allows selecting from pre-defined options OR typing custom text.
/// Typing custom text automatically saves the unit into [customUserUnits] for future dropdowns.
class EditableUnitDropdown extends StatelessWidget {
  const EditableUnitDropdown({
    super.key,
    required this.controller,
    required this.labelText,
    required this.defaultOptions,
    this.validator,
    this.onChanged,
    this.widgetKey,
  });

  final TextEditingController controller;
  final String labelText;
  final List<String> defaultOptions;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Key? widgetKey;

  @override
  Widget build(BuildContext context) {
    final options = getCombinedUnits(defaultOptions);

    return RawAutocomplete<String>(
      key: widgetKey,
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text.trim().toLowerCase();
        if (text.isEmpty) {
          return options;
        }
        return options.where((opt) => opt.toLowerCase().contains(text));
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (onChanged != null) onChanged!(selection);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
            suffixIcon: PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (val) {
                textEditingController.text = val;
                if (onChanged != null) onChanged!(val);
              },
              itemBuilder: (ctx) => options
                  .map(
                    (opt) => PopupMenuItem<String>(
                      value: opt,
                      child: Text(opt),
                    ),
                  )
                  .toList(),
            ),
          ),
          validator: validator,
          onChanged: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty && !options.contains(trimmed)) {
              customUserUnits.add(trimmed);
            }
            if (onChanged != null) onChanged!(val);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, optionsList) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionsList.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = optionsList.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
