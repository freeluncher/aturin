import 'package:flutter/material.dart';

class FilterChips<T> extends StatelessWidget {
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final Map<T, String> options;
  final String allLabel;
  final bool showAllOption;

  const FilterChips({
    super.key,
    required this.selectedValue,
    required this.onSelected,
    required this.options,
    this.allLabel = 'All',
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showAllOption) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(allLabel),
                selected: selectedValue == null,
                onSelected: (selected) {
                  if (selected) onSelected(null);
                },
              ),
            ),
          ],
          ...options.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selectedValue == entry.key,
                onSelected: (selected) {
                  onSelected(selected ? entry.key : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
