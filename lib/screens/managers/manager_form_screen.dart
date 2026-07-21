import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/section_card.dart';

/// Create a new staff member, or edit an existing one when [user] is provided.
///
/// Email and password are only set at creation time — Firebase Auth cannot
/// change another user's credentials from the client, so those fields are
/// hidden when editing.
class ManagerFormScreen extends ConsumerStatefulWidget {
  const ManagerFormScreen({super.key, this.user});

  final AppUser? user;

  bool get isEditing => user != null;

  @override
  ConsumerState<ManagerFormScreen> createState() => _ManagerFormScreenState();
}

class _ManagerFormScreenState extends ConsumerState<ManagerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  final _password = TextEditingController();

  UserRole _role = UserRole.manager;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u?.name);
    _phone = TextEditingController(text: u?.phone);
    _email = TextEditingController(text: u?.email);
    _role = u?.role ?? UserRole.manager;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(userRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repo.updateStaff(
          widget.user!.copyWith(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            role: _role,
          ),
        );
      } else {
        await repo.createStaff(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.isEditing ? 'Сотрудник обновлён' : 'Сотрудник создан'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _fail(_authMessage(e));
    } catch (e) {
      _fail('Не удалось сохранить: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _authMessage(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' => 'Эта почта уже зарегистрирована.',
        'invalid-email' => 'Некорректный адрес эл. почты.',
        'weak-password' => 'Слишком простой пароль (минимум 6 символов).',
        _ => 'Не удалось создать аккаунт: ${e.message}',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Изменить сотрудника' : 'Новый сотрудник'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            SectionCard(
              title: 'Профиль',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'ФИО',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                    validator: (v) => Validators.required(v, field: 'ФИО'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    validator: Validators.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Учётные данные',
              icon: Icons.lock_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    enabled: !widget.isEditing,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Эл. почта',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: Validators.email,
                  ),
                  if (!widget.isEditing) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Временный пароль',
                        prefixIcon: const Icon(Icons.password_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Почту и пароль здесь изменить нельзя.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Роль',
              icon: Icons.shield_rounded,
              child: RadioGroup<UserRole>(
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v!),
                child: Column(
                  children: UserRole.values.map((role) {
                    return RadioListTile<UserRole>(
                      value: role,
                      contentPadding: EdgeInsets.zero,
                      title: Text(role.label),
                      subtitle: Text(
                        role.isAdmin
                            ? 'Полный доступ, включая удаление и управление сотрудниками'
                            : 'Может просматривать, создавать и изменять клиентов',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать сотрудника'),
            ),
          ],
        ),
      ),
    );
  }
}
