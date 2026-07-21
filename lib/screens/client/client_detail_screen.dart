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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = const SizedBox(height: 16);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _HeroCard(client: client),
        gap,
        SectionCard(
          title: 'Личные данные',
          icon: Icons.person_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.tag_rounded,
                label: 'Номер клиента',
                value: Formatters.text(client.clientNumber),
              ),
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
              DetailRow(
                icon: Icons.location_city_rounded,
                label: 'Город',
                value: Formatters.text(client.city),
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
              DetailRow(
                icon: Icons.confirmation_number_rounded,
                label: 'Рейс',
                value: Formatters.text(client.arrivalFlight),
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
                icon: Icons.health_and_safety_rounded,
                label: 'Врач',
                value: Formatters.text(client.doctorName),
              ),
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
              DetailRow(
                icon: Icons.confirmation_number_rounded,
                label: 'Обратный рейс',
                value: Formatters.text(client.departureFlight),
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
  const _HeroCard({required this.client});

  final Client client;

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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '#${Formatters.text(client.clientNumber)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: StatusBadge(status: client.status),
            ),
          ),
        ],
      ),
    );
  }
}
