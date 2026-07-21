import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/client.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_picker.dart';
import 'client_form_screen.dart';

/// Full, block-by-block view of a single client. Stays live via the stream, so
/// edits by other managers appear here instantly.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text(
          'Клиент ${client.name.isEmpty ? '' : '«${client.name}» '}будет удалён безвозвратно. '
          'Отменить это действие нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(clientRepositoryProvider).deleteClient(client.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // leave detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Клиент удалён')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));
    final isAdmin = ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Данные клиента'),
        actions: [
          clientAsync.maybeWhen(
            data: (client) => client == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      IconButton(
                        tooltip: 'Изменить',
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientFormScreen(client: client),
                          ),
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          tooltip: 'Удалить',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () =>
                              _confirmDelete(context, ref, client),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Не удалось загрузить клиента: $e')),
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Этого клиента больше нет.'));
          }
          return _DetailBody(client: client);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.client});

  final Client client;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final picked =
        await showStatusPickerSheet(context, current: client.status);
    if (picked == null || picked == client.status) return;
    try {
      await ref
          .read(clientRepositoryProvider)
          .updateClient(client.copyWith(status: picked));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Статус изменён: ${picked.label}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось изменить статус: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gap = const SizedBox(height: 16);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _HeroCard(
          client: client,
          onChangeStatus: () => _changeStatus(context, ref),
        ),
        gap,
        SectionCard(
          title: 'Личные данные',
          icon: Icons.person_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.phone_rounded,
                label: 'Телефон',
                value: Formatters.text(client.phone),
              ),
              DetailRow(
                icon: Icons.public_rounded,
                label: 'Страна',
                value: Formatters.text(client.country),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Прибытие',
          icon: Icons.flight_land_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Дата',
                value: Formatters.date(client.arrivalDate),
              ),
              DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Время',
                value: Formatters.time(client.arrivalTime),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Отель',
          icon: Icons.hotel_rounded,
          child: DetailRow(
            icon: Icons.apartment_rounded,
            label: 'Отель',
            value: Formatters.text(client.hotel),
          ),
        ),
        gap,
        SectionCard(
          title: 'Приём у врача',
          icon: Icons.medical_services_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Дата',
                value: Formatters.date(client.doctorAppointmentDate),
              ),
              DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Время',
                value: Formatters.time(client.doctorAppointmentTime),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Вылет',
          icon: Icons.flight_takeoff_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Дата',
                value: Formatters.date(client.departureDate),
              ),
              DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Время',
                value: Formatters.time(client.departureTime),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Водитель / встреча',
          icon: Icons.directions_car_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.person_pin_rounded,
                label: 'Кто встречает',
                value: Formatters.text(client.driverName),
              ),
              DetailRow(
                icon: Icons.phone_in_talk_rounded,
                label: 'Телефон водителя',
                value: Formatters.text(client.driverPhone),
              ),
            ],
          ),
        ),
        if (client.notes.trim().isNotEmpty) ...[
          gap,
          SectionCard(
            title: 'Комментарий',
            icon: Icons.notes_rounded,
            child: Text(
              client.notes,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.client, required this.onChangeStatus});

  final Client client;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.royal.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.text(client.name),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.text(client.phone),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'СТАТУС',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onChangeStatus,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(status: client.status),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: client.status.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.75)),
              const SizedBox(width: 6),
              Text(
                'Нажмите, чтобы изменить статус',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
