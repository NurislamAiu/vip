import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          const SizedBox(height: 24),
          Text(
            'Диагностика',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const _DiagnosticsCard(),
        ],
      ),
    );
  }
}

/// Shows whether server (FCM) push notifications can reach this device.
class _DiagnosticsCard extends ConsumerWidget {
  const _DiagnosticsCard();

  static String _perm(String value) => switch (value) {
        'authorized' => 'Разрешены',
        'denied' => 'Запрещены',
        'notDetermined' => 'Не запрошены',
        'provisional' => 'Тихие',
        _ => value,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(notificationDiagnosticsProvider);

    return SectionCard(
      title: 'Серверные push-уведомления',
      icon: Icons.podcasts_rounded,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              SizedBox(width: 12),
              Text('Проверяем готовность устройства…'),
            ],
          ),
        ),
        error: (e, _) => Text('Не удалось проверить: $e'),
        data: (d) {
          final ok = d.canReceivePush;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (ok ? const Color(0xFF10B981) : theme.colorScheme.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      ok
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: ok
                          ? const Color(0xFF10B981)
                          : theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ok
                            ? 'Устройство готово принимать серверные пуши.'
                            : 'Серверные пуши на это устройство не дойдут '
                                '(нужен реальный iPhone + APNs-ключ).',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Row(label: 'Разрешение', value: _perm(d.permission)),
              if (d.isApple)
                _Row(
                  label: 'APNS-токен',
                  value: d.apnsToken != null
                      ? 'есть'
                      : 'нет (симулятор не выдаёт)',
                ),
              _TokenRow(token: d.fcmToken),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(notificationDiagnosticsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Обновить'),
                  ),
                  if (d.fcmToken != null)
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: d.fcmToken!));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('FCM-токен скопирован')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Скопировать токен'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final String short;
    if (token == null) {
      short = 'недоступен';
    } else {
      final n = token!.length < 14 ? token!.length : 14;
      short = '${token!.substring(0, n)}…';
    }
    return _Row(label: 'FCM-токен', value: short);
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
