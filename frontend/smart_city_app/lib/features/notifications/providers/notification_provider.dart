import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const _storageKey = 'notification_read_ids_v1';

  NotificationProvider() {
    _notifications = NotificationService().getSampleNotifications();
    loadReadStatus();
  }

  late List<NotificationModel> _notifications;

  bool _isLoading = true;
  bool _disposed = false;
  String? _storageError;

  // Keep saves in order when several notifications are marked quickly.
  Future<void> _saveQueue = Future<void>.value();

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  bool get isLoading => _isLoading;

  String? get storageError => _storageError;

  void _updateListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> loadReadStatus() async {
    _isLoading = true;
    _storageError = null;
    _updateListeners();

    try {
      final storage = await SharedPreferences.getInstance();
      final savedIds = (storage.getStringList(_storageKey) ?? []).toSet();

      if (_disposed) return;

      _notifications = _notifications.map((item) {
        return savedIds.contains(item.id) ? item.markAsRead() : item;
      }).toList();
    } catch (_) {
      if (_disposed) return;

      _storageError = 'Could not load saved read status. Please try again.';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _updateListeners();
      }
    }
  }

  void markAsRead(String id) {
    if (_isLoading || _disposed) return;

    final index = _notifications.indexWhere((item) => item.id == id);

    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].markAsRead();

    _updateListeners();
    saveReadStatus();
  }

  void markAllAsRead() {
    if (_isLoading || _disposed || unreadCount == 0) return;

    _notifications = _notifications.map((item) => item.markAsRead()).toList();

    _updateListeners();
    saveReadStatus();
  }

  Future<void> saveReadStatus() {
    final readIds = _notifications
        .where((item) => item.isRead)
        .map((item) => item.id)
        .toList();

    _saveQueue = _saveQueue.then((_) async {
      try {
        final storage = await SharedPreferences.getInstance();
        final saved = await storage.setStringList(_storageKey, readIds);

        if (!saved) {
          throw StateError('Read status was not saved.');
        }

        if (!_disposed) {
          _storageError = null;
          _updateListeners();
        }
      } catch (_) {
        if (!_disposed) {
          _storageError = 'Could not save read status. Please retry saving.';
          _updateListeners();
        }
      }
    });

    return _saveQueue;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
