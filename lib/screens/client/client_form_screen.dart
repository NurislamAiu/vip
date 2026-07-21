import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/client.dart';
import '../../models/client_status.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/section_card.dart';

/// Create a new client, or edit an existing one when [client] is provided.
///
/// On save the change is written to Firestore and propagates to every manager
/// through the live streams — no manual refresh anywhere.
class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.client});

  final Client? client;

  bool get isEditing => client != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;

  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  ClientStatus _status = ClientStatus.awaitingArrival;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _controllers = {
      'clientNumber': TextEditingController(text: c?.clientNumber),
      'name': TextEditingController(text: c?.name),
      'phone': TextEditingController(text: c?.phone),
      'country': TextEditingController(text: c?.country),
      'city': TextEditingController(text: c?.city),
      'arrivalFlight': TextEditingController(text: c?.arrivalFlight),
      'hotel': TextEditingController(text: c?.hotel),
      'doctorName': TextEditingController(text: c?.doctorName),
      'departureFlight': TextEditingController(text: c?.departureFlight),
      'driverName': TextEditingController(text: c?.driverName),
      'driverPhone': TextEditingController(text: c?.driverPhone),
      'notes': TextEditingController(text: c?.notes),
    };

    if (c != null) {
      _arrivalDate = c.arrivalDate;
      _arrivalTime = Formatters.parseTimeOfDay(c.arrivalTime);
      _appointmentDate = c.doctorAppointmentDate;
      _appointmentTime = Formatters.parseTimeOfDay(c.doctorAppointmentTime);
      _departureDate = c.departureDate;
      _departureTime = Formatters.parseTimeOfDay(c.departureTime);
      _status = c.status;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _controllers[key]!.text.trim();

  String _timeString(TimeOfDay? time) =>
      time == null ? '' : Formatters.timeOfDay(time);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() => _saving = true);

    final repo = ref.read(clientRepositoryProvider);
    final base = widget.client ??
        Client(id: '', clientNumber: '', name: '', phone: '');

    final client = base.copyWith(
      clientNumber: _text('clientNumber'),
      name: _text('name'),
      phone: _text('phone'),
      country: _text('country'),
      city: _text('city'),
      arrivalDate: _arrivalDate,
      arrivalTime: _timeString(_arrivalTime),
      arrivalFlight: _text('arrivalFlight'),
      hotel: _text('hotel'),
      doctorName: _text('doctorName'),
      doctorAppointmentDate: _appointmentDate,
      doctorAppointmentTime: _timeString(_appointmentTime),
      departureDate: _departureDate,
      departureTime: _timeString(_departureTime),
      departureFlight: _text('departureFlight'),
      driverName: _text('driverName'),
      driverPhone: _text('driverPhone'),
      status: _status,
      notes: _text('notes'),
    );

    try {
      if (widget.isEditing) {
        await repo.updateClient(client);
      } else {
        await repo.createClient(client, createdBy: currentUser.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Клиент обновлён' : 'Клиент добавлен',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Изменить клиента' : 'Новый клиент'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            SectionCard(
              title: 'Личные данные',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  _field('clientNumber', 'Номер клиента',
                      icon: Icons.tag_rounded,
                      keyboardType: TextInputType.number),
                  _field('name', 'ФИО',
                      icon: Icons.badge_rounded,
                      validator: (v) =>
                          Validators.required(v, field: 'ФИО')),
                  _field('phone', 'Телефон',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone),
                  _field('country', 'Страна', icon: Icons.public_rounded),
                  _field('city', 'Город',
                      icon: Icons.location_city_rounded, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Прибытие',
              icon: Icons.flight_land_rounded,
              accent: ClientStatus.awaitingArrival.color,
              child: Column(
                children: [
                  _dateTimeRow(
                    date: _arrivalDate,
                    time: _arrivalTime,
                    onDate: (d) => setState(() => _arrivalDate = d),
                    onTime: (t) => setState(() => _arrivalTime = t),
                  ),
                  const SizedBox(height: 12),
                  _field('arrivalFlight', 'Номер рейса',
                      icon: Icons.confirmation_number_rounded, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Отель',
              icon: Icons.hotel_rounded,
              accent: ClientStatus.inHotel.color,
              child: _field('hotel', 'Название отеля',
                  icon: Icons.apartment_rounded, isLast: true),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Приём у врача',
              icon: Icons.medical_services_rounded,
              accent: ClientStatus.inTreatment.color,
              child: Column(
                children: [
                  _field('doctorName', 'Имя врача',
                      icon: Icons.health_and_safety_rounded),
                  _dateTimeRow(
                    date: _appointmentDate,
                    time: _appointmentTime,
                    onDate: (d) => setState(() => _appointmentDate = d),
                    onTime: (t) => setState(() => _appointmentTime = t),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Вылет',
              icon: Icons.flight_takeoff_rounded,
              accent: ClientStatus.departed.color,
              child: Column(
                children: [
                  _dateTimeRow(
                    date: _departureDate,
                    time: _departureTime,
                    onDate: (d) => setState(() => _departureDate = d),
                    onTime: (t) => setState(() => _departureTime = t),
                  ),
                  const SizedBox(height: 12),
                  _field('departureFlight', 'Номер обратного рейса',
                      icon: Icons.confirmation_number_rounded, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Водитель / встреча',
              icon: Icons.directions_car_rounded,
              accent: ClientStatus.met.color,
              child: Column(
                children: [
                  _field('driverName', 'Кто встречает клиента',
                      icon: Icons.person_pin_rounded),
                  _field('driverPhone', 'Телефон водителя',
                      icon: Icons.phone_in_talk_rounded,
                      keyboardType: TextInputType.phone,
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Статус',
              icon: Icons.flag_rounded,
              accent: _status.color,
              child: _statusSelector(),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Комментарий',
              icon: Icons.notes_rounded,
              child: _field('notes', 'Заметки',
                  icon: null, maxLines: 4, isLast: true),
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
              label: Text(widget.isEditing ? 'Сохранить изменения' : 'Сохранить клиента'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }

  Widget _dateTimeRow({
    required DateTime? date,
    required TimeOfDay? time,
    required ValueChanged<DateTime> onDate,
    required ValueChanged<TimeOfDay> onTime,
  }) {
    return Row(
      children: [
        Expanded(
          child: _PickerTile(
            icon: Icons.calendar_today_rounded,
            label: 'Дата',
            value: Formatters.date(date),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 3),
              );
              if (picked != null) onDate(picked);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PickerTile(
            icon: Icons.schedule_rounded,
            label: 'Время',
            value: time == null ? '—' : Formatters.timeOfDay(time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time ?? TimeOfDay.now(),
              );
              if (picked != null) onTime(picked);
            },
          ),
        ),
      ],
    );
  }

  Widget _statusSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ClientStatus.values.map((status) {
        final selected = status == _status;
        return ChoiceChip(
          avatar: Icon(
            status.icon,
            size: 16,
            color: selected ? Colors.white : status.color,
          ),
          label: Text(status.label),
          selected: selected,
          selectedColor: status.color,
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _status = status),
        );
      }).toList(),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
