/// Reusable form-field validators.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'Это поле'}) {
    if (value == null || value.trim().isEmpty) return 'Заполните: $field';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Укажите эл. почту';
    final pattern = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!pattern.hasMatch(value.trim())) return 'Введите корректную эл. почту';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Укажите пароль';
    if (value.length < 6) return 'Минимум 6 символов';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Укажите телефон';
    final pattern = RegExp(r'^\+?[0-9\s\-()]{6,}$');
    if (!pattern.hasMatch(value.trim())) return 'Введите корректный номер телефона';
    return null;
  }
}
