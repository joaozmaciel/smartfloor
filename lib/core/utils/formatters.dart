/// Formats a number with two decimal places and a decimal comma.
String formatDecimal(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

/// Parses a number using either a decimal comma or decimal point.
double? parseDecimal(String? text) {
  if (text == null) return null;
  return double.tryParse(text.trim().replaceAll(',', '.'));
}

/// Formats dimensions compactly: 20 m, 3,5 m, 3,25 m.
String formatMetersCompact(double value) {
  var text = value.toStringAsFixed(2);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return '${text.replaceAll('.', ',')} m';
}
