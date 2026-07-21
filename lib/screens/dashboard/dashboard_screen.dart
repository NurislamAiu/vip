import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auto_status.dart';
import '../../models/app_user.dart';
import '../../models/client.dart';
import '../../models/client_filter.dart';
import '../../models/client_status.dart';
import '../../models/reminder_settings.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/client_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_picker.dart';
import '../client/client_detail_screen.dart';
import '../client/client_form_screen.dart';
import '../managers/managers_screen.dart';
import '../settings/settings_screen.dart';

/// The home dashboard: a premium hero header with live stats, search, quick
/// filters, and the live client list.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Grow the Firestore query limit as the user nears the end of the list.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final streamed = ref.read(clientsStreamProvider).valueOrNull?.length ?? 0;
      final limit = ref.read(clientsLimitProvider);
      // Only extend when the current page is full (more may exist).
      if (streamed >= limit) {
        ref.read(clientsLimitProvider.notifier).state =
            limit + AppConstants.clientsPageSize;
      }
    }
  }

  /// Auto-advance client statuses to match the schedule (auto-status mode).
  void _reconcileStatuses(List<Client> clients) {
    final now = DateTime.now();
    final repo = ref.read(clientRepositoryProvider);
    for (final c in clients) {
      final expected = expectedStatus(c, now);
      if (expected != c.status) {
        repo.updateClient(c.copyWith(status: expected));
      }
    }
  }

  /// (Re)schedule reminders and optionally reconcile statuses.
  void _applyAutomation(List<Client> clients, ReminderSettings settings) {
    ref.read(reminderServiceProvider).sync(clients, settings);
    if (settings.autoStatus) _reconcileStatuses(clients);
  }

  /// Quick status change straight from the list — tap a card's status badge.
  Future<void> _quickChangeStatus(BuildContext context, Client client) async {
    final picked =
        await showStatusPickerSheet(context, current: client.status);
    if (picked == null || picked == client.status) return;
    try {
      await ref
          .read(clientRepositoryProvider)
          .updateClient(client.copyWith(status: picked));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус: ${picked.label}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось изменить статус: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final clientsAsync = ref.watch(clientsStreamProvider);
    final filtered = ref.watch(filteredClientsProvider);

    // Keep reminders + auto-status in sync with live data and settings.
    ref.listen<AsyncValue<List<Client>>>(clientsStreamProvider, (_, next) {
      final clients = next.valueOrNull;
      if (clients != null) {
        _applyAutomation(clients, ref.read(reminderSettingsProvider));
      }
    });
    ref.listen<ReminderSettings>(reminderSettingsProvider, (_, next) {
      final clients = ref.read(clientsStreamProvider).valueOrNull;
      if (clients != null) _applyAutomation(clients, next);
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить клиента'),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(clientsStreamProvider),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
              SliverToBoxAdapter(child: _HeroHeader(user: user)),
              const SliverToBoxAdapter(child: _SearchField()),
              const SliverToBoxAdapter(child: _FilterChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              clientsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Не удалось загрузить клиентов',
                    message: '$e',
                  ),
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'Клиенты не найдены',
                        message: 'Измените поиск или добавьте нового клиента.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final client = filtered[index];
                        return ClientCard(
                          client: client,
                          onStatusTap: () =>
                              _quickChangeStatus(context, client),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClientDetailScreen(clientId: client.id),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient hero card: greeting, VIP badge, quick actions and live counters.
class _HeroHeader extends ConsumerWidget {
  const _HeroHeader({required this.user});

  final AppUser? user;

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Чтобы продолжить, нужно будет войти снова.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clients = ref.watch(clientsStreamProvider).valueOrNull ?? const [];
    final now = DateTime.now();

    bool sameDay(DateTime? d) =>
        d != null && d.year == now.year && d.month == now.month && d.day == now.day;

    final arrivingToday = clients.where((c) => sameDay(c.arrivalDate)).length;
    final inTreatment =
        clients.where((c) => c.status == ClientStatus.inTreatment).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royal.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 42, glow: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'С возвращением',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const VipTag(compact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'VIP-менеджер',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (user?.isAdmin ?? false)
                _GlassIconButton(
                  icon: Icons.group_rounded,
                  tooltip: 'Сотрудники',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManagersScreen()),
                  ),
                ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Настройки',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.logout_rounded,
                tooltip: 'Выйти',
                onPressed: () => _confirmSignOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _StatTile(
                value: '${clients.length}',
                label: 'Клиентов',
                icon: Icons.people_alt_rounded,
              ),
              const SizedBox(width: 12),
              _StatTile(
                value: '$arrivingToday',
                label: 'Прибывают',
                icon: Icons.flight_land_rounded,
              ),
              const SizedBox(width: 12),
              _StatTile(
                value: '$inTreatment',
                label: 'На лечении',
                icon: Icons.medical_services_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 19, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(clientSearchProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: TextField(
        onChanged: (value) =>
            ref.read(clientSearchProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Поиск: имя, телефон, отель, водитель…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () =>
                      ref.read(clientSearchProvider.notifier).state = '',
                ),
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(clientFilterProvider);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: ClientFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ClientFilter.values[index];
          final isSelected = filter == selected;
          final theme = Theme.of(context);
          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (_) =>
                ref.read(clientFilterProvider.notifier).state = filter,
          );
        },
      ),
    );
  }
}
