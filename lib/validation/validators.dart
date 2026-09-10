String? validateText(String? value, {int minLength = 1, int maxLength = 200}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Обязательное поле';
  if (text.length < minLength) return 'Минимум $minLength символов';
  if (text.length > maxLength) return 'Максимум $maxLength символов';
  return null;
}

String? validateInteger(String? value, {int? min, int? max}) {
  if (value == null || value.trim().isEmpty) return 'Обязательное поле';
  final number = int.tryParse(value.trim());
  if (number == null) return 'Введите целое число';
  if (min != null && number < min) return 'Значение должно быть не меньше $min';
  if (max != null && number > max) return 'Значение должно быть не больше $max';
  return null;
}

String? validatePositiveInteger(String? value) =>
    validateInteger(value, min: 1);

// ID вводятся через запятую, например: 1, 2, 3.
List<int> parseIds(String value) =>
    value.split(',').map((part) => int.parse(part.trim())).toList();

String? validateIds(String? value) {
  final textError = validateText(value, maxLength: 500);
  if (textError != null) return textError;
  for (final part in value!.split(',')) {
    if (validatePositiveInteger(part) != null) {
      return 'Введите положительные целые ID через запятую';
    }
  }
  return null;
}
