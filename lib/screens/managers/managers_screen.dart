import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/empty_state.dart';
import 'manager_form_screen.dart';

/// Administrator-only screen to manage staff: list, add, edit, enable/disable,
/// and delete.
class ManagersScreen extends ConsumerWidget {
  const ManagersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Сотрудники')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManagerFormScreen()),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Добавить'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Не удалось загрузить сотрудников',
          message: '$e',
        ),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.group_outlined,
              title: 'Пока нет сотрудников',
              message: 'Добавьте первого менеджера, чтобы начать.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _StaffTile(user: users[index]),
          );
        },
      ),
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.user});

  final AppUser user;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сотрудника?'),
        content: Text(
          'Доступ ${user.name} будет удалён. Сам аккаунт для входа нужно '
          'удалить в консоли Firebase.',
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
      await ref.read(userRepositoryProvider).deleteStaff(user.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось удалить: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isSelf = currentUser?.id == user.id;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (user.isAdmin
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary)
                .withValues(alpha: 0.15),
            child: Icon(
              user.isAdmin ? Icons.shield_rounded : Icons.person_rounded,
              color: user.isAdmin
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RolePill(isAdmin: user.isAdmin),
                    if (!user.isActive) ...[
                      const SizedBox(width: 6),
                      _InactivePill(),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.phone.trim().isNotEmpty)
                  Text(
                    user.phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManagerFormScreen(user: user),
                    ),
                  );
                case 'toggle':
                  ref
                      .read(userRepositoryProvider)
                      .setActive(user.id, !user.isActive);
                case 'delete':
                  _confirmDelete(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_rounded),
                  title: Text('Изменить'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!isSelf)
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(user.isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded),
                    title: Text(user.isActive ? 'Отключить' : 'Включить'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (!isSelf)
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Удалить'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isAdmin ? theme.colorScheme.primary : theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Админ' : 'Менеджер',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InactivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Отключён',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
