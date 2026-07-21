import 'package:flutter/material.dart';

import '../models/client_status.dart';

/// A single selectable status row: tinted icon, label and a check indicator.
/// Selected rows adopt the status' accent color.
class StatusOptionTile extends StatelessWidget {
  const StatusOptionTile({
    super.key,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final ClientStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(status.icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  status.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? color
                    : theme.colorScheme.outlineVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline vertical status picker used inside forms.
class StatusPicker extends StatelessWidget {
  const StatusPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ClientStatus value;
  final ValueChanged<ClientStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = ClientStatus.values;
    return Column(
      children: [
        for (var i = 0; i < statuses.length; i++) ...[
          StatusOptionTile(
            status: statuses[i],
            selected: statuses[i] == value,
            onTap: () => onChanged(statuses[i]),
          ),
          if (i != statuses.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Opens a modal sheet to pick a status. Returns the chosen status, or `null`
/// if dismissed.
Future<ClientStatus?> showStatusPickerSheet(
  BuildContext context, {
  required ClientStatus current,
}) {
  return showModalBottomSheet<ClientStatus>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final statuses = ClientStatus.values;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 14),
                child: Text(
                  'Изменить статус',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              for (var i = 0; i < statuses.length; i++) ...[
                StatusOptionTile(
                  status: statuses[i],
                  selected: statuses[i] == current,
                  onTap: () => Navigator.pop(context, statuses[i]),
                ),
                if (i != statuses.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    },
  );
}
