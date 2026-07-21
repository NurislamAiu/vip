import 'package:flutter/material.dart';

import '../core/utils/auto_status.dart';
import '../core/utils/formatters.dart';
import '../models/client.dart';
import 'status_badge.dart';

/// A compact, scannable client row: a status-colored accent stripe, identity,
/// the single most relevant upcoming event, and who added the client. Kept
/// short on purpose so long VIP lists stay readable.
class ClientCard extends StatelessWidget {
  const ClientCard({super.key, required this.client, required this.onTap});

  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final event = _nextEvent(client);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: client.status.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        Formatters.text(client.name),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(
                                      status: client.status,
                                      dense: true,
                                      filled: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _MetaLine(
                                  icon: event.icon,
                                  iconColor: client.status.color,
                                  text: event.text,
                                  strong: true,
                                ),
                                const SizedBox(height: 3),
                                _MetaLine(
                                  icon: Icons.call_rounded,
                                  text: _subtitle(client),
                                ),
                                if (client.driverName.trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  _MetaLine(
                                    icon: Icons.directions_car_rounded,
                                    text: 'Встречает: ${client.driverName.trim()}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.outline,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(Client c) {
    final phone = Formatters.text(c.phone);
    if (c.createdByName.trim().isNotEmpty) {
      return '$phone  ·  ${c.createdByName.trim()}';
    }
    return phone;
  }

  /// The soonest upcoming event; if all are past, the most recent one.
  _EventInfo _nextEvent(Client c) {
    final now = DateTime.now();
    final events = <_EventInfo>[
      _EventInfo(
        Icons.flight_land_rounded,
        'Прибытие',
        combineDateTime(c.arrivalDate, c.arrivalTime),
        Formatters.dateTime(c.arrivalDate, c.arrivalTime),
      ),
      _EventInfo(
        Icons.medical_services_rounded,
        'Приём',
        combineDateTime(c.doctorAppointmentDate, c.doctorAppointmentTime),
        Formatters.dateTime(
            c.doctorAppointmentDate, c.doctorAppointmentTime),
      ),
      _EventInfo(
        Icons.flight_takeoff_rounded,
        'Вылет',
        combineDateTime(c.departureDate, c.departureTime),
        Formatters.dateTime(c.departureDate, c.departureTime),
      ),
    ].where((e) => e.when != null).toList();

    if (events.isEmpty) {
      return _EventInfo(Icons.event_busy_rounded, '', null, 'Нет дат');
    }

    final upcoming = events.where((e) => !e.when!.isBefore(now)).toList()
      ..sort((a, b) => a.when!.compareTo(b.when!));
    final chosen = upcoming.isNotEmpty
        ? upcoming.first
        : (events..sort((a, b) => b.when!.compareTo(a.when!))).first;

    return _EventInfo(
      chosen.icon,
      chosen.label,
      chosen.when,
      '${chosen.label}: ${chosen.text}',
    );
  }
}

class _EventInfo {
  const _EventInfo(this.icon, this.label, this.when, this.text);
  final IconData icon;
  final String label;
  final DateTime? when;
  final String text;
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    this.iconColor,
    this.strong = false,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: strong
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
