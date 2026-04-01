import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationController with ChangeNotifier {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal() {
    // Start listening to the broadcast stream on initialization
    _listenToForegroundMessages();
  }

  final List<NotificationModel> _notifications = [];
  final List<dynamic> _broadcastLogs = [];
  Map<String, dynamic> _broadcastStats = {
    'total': 0,
    'pushSent': 0,
    'smsSent': 0,
    'mostTargeted': 'None',
  };

  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  List<dynamic> get broadcastLogs => List.unmodifiable(_broadcastLogs);
  Map<String, dynamic> get broadcastStats => _broadcastStats;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void _listenToForegroundMessages() {
    NotificationService().onMessageReceived.listen((message) {
      debugPrint('NotificationController Received Foreground Message: ${message.notification?.title}');
      // Trigger a refresh of the list and counts when a new foreground message arrives
      fetchNotifications();
    });
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.getNotificationHistory();
      _notifications.clear();
      _notifications.addAll(result['notifications'] as List<NotificationModel>);
      _unreadCount = result['unreadCount'] as int;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String? notificationId, {bool markAll = false}) async {
    try {
      await ApiService.markNotificationAsRead(
        notificationId: notificationId,
        markAll: markAll,
      );
      // Refresh after marking as read
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // --- CRM Broadcast Logic ---

  Future<void> fetchBroadcastLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.getBroadcastLogs();
      _broadcastLogs.clear();
      _broadcastLogs.addAll(result['notifications'] as List);
      _broadcastStats = result['stats'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching broadcast logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBroadcast(Map<String, dynamic> payload) async {
    try {
      final response = await ApiService.createBroadcast(payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBroadcastLogs();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating broadcast: $e');
      return false;
    }
  }

  Future<void> deleteBroadcast(String notificationId) async {
    try {
      await ApiService.deleteBroadcastLog(notificationId);
      await fetchBroadcastLogs();
    } catch (e) {
      debugPrint('Error deleting broadcast: $e');
    }
  }

  IconData getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return Icons.calendar_today;
      case 'review':
        return Icons.star;
      case 'bookingconfirmed':
        return Icons.check_circle;
      case 'deal':
      case 'offer':
        return Icons.card_giftcard;
      case 'tips':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return Colors.blue;
      case 'review':
        return Colors.yellow.shade700;
      case 'bookingconfirmed':
        return Colors.green;
      case 'deal':
      case 'offer':
        return Colors.red;
      case 'tips':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
