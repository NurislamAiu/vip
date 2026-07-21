import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Delete client?'),
        content: Text(
          'This permanently removes ${client.name.isEmpty ? 'this client' : client.name}. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
        const SnackBar(content: Text('Client deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));
    final isAdmin = ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client details'),
        actions: [
          clientAsync.maybeWhen(
            data: (client) => client == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClientFormScreen(client: client),
                          ),
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          tooltip: 'Delete',
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
        error: (e, _) => Center(child: Text('Could not load client: $e')),
        data: (client) {
          if (client == null) {
            return const Center(child: Text('This client no longer exists.'));
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
          title: 'Personal information',
          icon: Icons.person_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.tag_rounded,
                label: 'Client number',
                value: Formatters.text(client.clientNumber),
              ),
              DetailRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: Formatters.text(client.phone),
              ),
              DetailRow(
                icon: Icons.public_rounded,
                label: 'Country',
                value: Formatters.text(client.country),
              ),
              DetailRow(
                icon: Icons.location_city_rounded,
                label: 'City',
                value: Formatters.text(client.city),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Arrival',
          icon: Icons.flight_land_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: Formatters.date(client.arrivalDate),
              ),
              DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Time',
                value: Formatters.time(client.arrivalTime),
              ),
              DetailRow(
                icon: Icons.confirmation_number_rounded,
                label: 'Flight',
                value: Formatters.text(client.arrivalFlight),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Hotel',
          icon: Icons.hotel_rounded,
          child: DetailRow(
            icon: Icons.apartment_rounded,
            label: 'Hotel',
            value: Formatters.text(client.hotel),
          ),
        ),
        gap,
        SectionCard(
          title: 'Doctor appointment',
          icon: Icons.medical_services_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.health_and_safety_rounded,
                label: 'Doctor',
                value: Formatters.text(client.doctorName),
              ),
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: Formatters.date(client.doctorAppointmentDate),
              ),
              DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Time',
                value: Formatters.time(client.doctorAppointmentTime),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Departure',
          icon: Icons.flight_takeoff_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: Formatters.date(client.departureDate),
              ),
              DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Time',
                value: Formatters.time(client.departureTime),
              ),
              DetailRow(
                icon: Icons.confirmation_number_rounded,
                label: 'Return flight',
                value: Formatters.text(client.departureFlight),
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: 'Driver / meeting',
          icon: Icons.directions_car_rounded,
          child: Column(
            children: [
              DetailRow(
                icon: Icons.person_pin_rounded,
                label: 'Who meets',
                value: Formatters.text(client.driverName),
              ),
              DetailRow(
                icon: Icons.phone_in_talk_rounded,
                label: 'Driver phone',
                value: Formatters.text(client.driverPhone),
              ),
            ],
          ),
        ),
        if (client.notes.trim().isNotEmpty) ...[
          gap,
          SectionCard(
            title: 'Comment',
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${Formatters.text(client.clientNumber)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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
