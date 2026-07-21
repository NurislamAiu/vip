import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/client_filter.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/client_card.dart';
import '../../widgets/empty_state.dart';
import '../client/client_detail_screen.dart';
import '../client/client_form_screen.dart';
import '../managers/managers_screen.dart';

/// The home dashboard: search, quick filters, and the live client list.
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final clientsAsync = ref.watch(clientsStreamProvider);
    final filtered = ref.watch(filteredClientsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add client'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(clientsStreamProvider),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _Header(user: user)),
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
                    title: 'Could not load clients',
                    message: '$e',
                  ),
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No clients found',
                        message: 'Adjust your search or add a new client.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final client = filtered[index];
                        return ClientCard(
                          client: client,
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
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.user});

  final AppUser? user;

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'VIP Manager',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (user?.isAdmin ?? false)
            _RoundIconButton(
              icon: Icons.group_rounded,
              tooltip: 'Managers',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManagersScreen()),
              ),
            ),
          const SizedBox(width: 10),
          _RoundIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Sign out',
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: TextField(
        onChanged: (value) =>
            ref.read(clientSearchProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Search name, phone, №, hotel, driver…',
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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: ClientFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ClientFilter.values[index];
          final isSelected = filter == selected;
          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(clientFilterProvider.notifier).state = filter,
          );
        },
      ),
    );
  }
}
