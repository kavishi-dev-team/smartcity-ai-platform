import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService() {
    loadNotifications();
  }

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _disposed = false;
  String? _error;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadNotifications() async {
    if (_disposed || _isSaving) return;

    _isLoading = true;
    _error = null;
    _notify();

    try {
      final items = await _service.getNotifications();
      final count = await _service.getUnreadCount();

      if (_disposed) return;

      _notifications = items;
      _unreadCount = count;
    } catch (error) {
      if (_disposed) return;
      _error = error.toString();
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<NotificationModel> getNotification(String id) {
    return _service.getNotification(id);
  }

  Future<NotificationModel> markAsRead(String id) async {
    if (_disposed || _isLoading || _isSaving) {
      throw const NotificationApiException(
        'Please wait for the current request to finish.',
      );
    }

    _isSaving = true;
    _notify();

    try {
      final updated = await _service.markAsRead(id);

      if (!_disposed) {
        final index = _notifications.indexWhere((item) => item.id == id);
        if (index != -1) {
          _notifications[index] = updated;
        }
        _unreadCount = _notifications.where((item) => !item.isRead).length;
      }

      return updated;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  Future<void> markAllAsRead() async {
    if (_disposed || _isLoading || _isSaving || _unreadCount == 0) return;

    _isSaving = true;
    _notify();

    try {
      await _service.markAllAsRead();

      if (_disposed) return;

      _notifications = _notifications.map((item) => item.markAsRead()).toList();
      _unreadCount = 0;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
