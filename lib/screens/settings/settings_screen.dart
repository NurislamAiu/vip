import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/client_status.dart';
import '../../models/reminder_settings.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/section_card.dart';

/// Manager-configurable reminder and automation settings (per device).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Уведомления',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Выберите, за сколько времени напоминать о событиях клиента.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ReminderCard(
            title: 'Прибытие',
            icon: Icons.flight_land_rounded,
            accent: ClientStatus.awaitingArrival.color,
            lead: settings.arrival,
            onChanged: notifier.setArrival,
          ),
          const SizedBox(height: 16),
          _ReminderCard(
            title: 'Приём у врача',
            icon: Icons.medical_services_rounded,
            accent: ClientStatus.inTreatment.color,
            lead: settings.appointment,
            onChanged: notifier.setAppointment,
          ),
          const SizedBox(height: 16),
          _ReminderCard(
            title: 'Вылет',
            icon: Icons.flight_takeoff_rounded,
            accent: ClientStatus.departed.color,
            lead: settings.departure,
            onChanged: notifier.setDeparture,
          ),
          const SizedBox(height: 24),
          Text(
            'Автоматизация',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Автостатус',
            icon: Icons.auto_mode_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.autoStatus,
                  onChanged: notifier.setAutoStatus,
                  title: const Text('Менять статус по расписанию'),
                  subtitle: const Text(
                    'Статус клиента автоматически переключается: ожидание → '
                    'встречен → в отеле → на лечении → готовится к вылету → улетел.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.lead,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final ReminderLead lead;
  final ValueChanged<ReminderLead> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: title,
      icon: icon,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: lead.enabled,
            activeColor: accent,
            onChanged: (v) => onChanged(lead.copyWith(enabled: v)),
            title: Text(
              lead.enabled ? 'Напоминать ${leadLabel(lead.minutes)}' : 'Выключено',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (lead.enabled) ...[
            const SizedBox(height: 4),
            Text(
              'За сколько напомнить',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kLeadPresets.map((m) {
                final selected = m == lead.minutes;
                return ChoiceChip(
                  label: Text(leadLabel(m)),
                  selected: selected,
                  selectedColor: accent,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (_) => onChanged(lead.copyWith(minutes: m)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
