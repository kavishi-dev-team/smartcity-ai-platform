const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

int _hour12(DateTime d) => d.hour % 12 == 0 ? 12 : d.hour % 12;
String _ampm(DateTime d) => d.hour >= 12 ? 'PM' : 'AM';

/// e.g. "20 Oct 2026, 2:15 PM"
String formatDateTime(DateTime dt) {
  final l = dt.toLocal();
  final minute = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${_months[l.month - 1]} ${l.year}, ${_hour12(l)}:$minute ${_ampm(l)}';
}

/// e.g. "20 Oct"
String formatShortDate(DateTime dt) {
  final l = dt.toLocal();
  return '${l.day} ${_months[l.month - 1]}';
}

/// e.g. "2 PM"
String formatHour(DateTime dt) {
  final l = dt.toLocal();
  return '${_hour12(l)} ${_ampm(l)}';
}

/// e.g. "a few moments ago", "12 min ago", "3 h ago", "2 d ago"
String formatRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'a few moments ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 30) return '${diff.inDays} d ago';
  return formatShortDate(dt);
}
