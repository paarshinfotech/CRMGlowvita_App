import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:http/io_client.dart' as http_io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../utils/navigator_key.dart';
import '../intro_page.dart';
import '../customer_model.dart';
import '../appointment_model.dart';
import '../addon_model.dart';
import '../vendor_model.dart';
import '../billing_invoice_model.dart';
import 'marketplace_models.dart';
import '../supplier_model.dart';
import '../models/notification_model.dart';
import '../models/shipping_model.dart';

class StaffMember {
  final String? id;
  final String? vendorId;
  final String? fullName;
  final String? email;
  final String? mobile;
  final String? position;
  final String? photo;
  final String? status;
  final List<dynamic>? permissions;
  final Map<String, dynamic>? availability;
  final List<dynamic>? blockedTimes;
  final Map<String, dynamic>? bankDetails;
  final int? salary;
  final int? yearOfExperience;
  final int? clientsServed;
  final bool? commission;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final double? commissionPercentage;

  String? get emailAddress => email;
  String? get mobileNo => mobile;

  StaffMember({
    this.id,
    this.vendorId,
    this.fullName,
    this.email,
    this.mobile,
    this.position,
    this.photo,
    this.status,
    this.permissions,
    this.availability,
    this.blockedTimes,
    this.bankDetails,
    this.salary,
    this.yearOfExperience,
    this.clientsServed,
    this.commission,
    this.startDate,
    this.endDate,
    this.description,
    this.commissionPercentage,
  });

  /// Safely parses the blockedTimes array from JSON.
  /// Using List.from() instead of .cast<dynamic>() avoids CastError
  /// when the list contains _JsonMap instances that Dart can't lazily cast.
  static List<dynamic> _parseBlockedTimes(dynamic raw) {
    if (raw == null) return [];
    try {
      final list = raw as List;
      final result = list
          .map((item) {
            if (item == null) return null;
            if (item is Map<String, dynamic>) return item;
            if (item is Map) return Map<String, dynamic>.from(item);
            return item;
          })
          .where((e) => e != null)
          .toList();
      debugPrint(
        '⚡ _parseBlockedTimes: parsed ${result.length} blocked entries',
      );
      return result;
    } catch (e) {
      debugPrint('⚡ _parseBlockedTimes ERROR: $e  raw=$raw');
      return [];
    }
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    // Construct availability map from root fields if 'availability' is missing
    Map<String, dynamic>? availabilityMap = json['availability'] != null
        ? Map<String, dynamic>.from(json['availability'])
        : null;

    if (availabilityMap == null) {
      final days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      availabilityMap = {};
      for (var day in days) {
        if (json.containsKey('${day}Available')) {
          availabilityMap['${day}Available'] = json['${day}Available'];
        }
        if (json.containsKey('${day}Slots')) {
          availabilityMap['${day}Slots'] = json['${day}Slots'];
        }
      }
      if (json.containsKey('timezone')) {
        availabilityMap['timezone'] = json['timezone'];
      }
    }

    return StaffMember(
      id: json['_id'],
      vendorId: (json['vendorId'] is Map)
          ? json['vendorId']['_id']
          : (json['vendorId']?.toString()),
      fullName: json['fullName'] ?? json['name'],
      email: json['emailAddress'] ?? json['email'],
      mobile: json['mobileNo'] ?? json['mobile'],
      position: json['position'],
      photo: json['photo'] ?? json['image'] ?? json['profileImage'],
      status: json['status'] ?? 'Active',
      permissions: json['permissions']?.cast<dynamic>() ?? [],
      availability: availabilityMap,
      blockedTimes: _parseBlockedTimes(json['blockedTimes']),
      bankDetails: json['bankDetails'] != null
          ? Map<String, dynamic>.from(json['bankDetails'])
          : null,
      salary: (json['salary'] as num?)?.toInt(),
      yearOfExperience: (json['yearOfExperience'] as num?)?.toInt(),
      clientsServed: (json['clientsServed'] as num?)?.toInt(),
      commission: json['commission'] ?? false,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      description: json['description'],
      commissionPercentage:
          (json['commissionRate'] ?? json['commissionPercentage'] as num?)
              ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'vendorId': vendorId,
      'fullName': fullName,
      'emailAddress': email,
      'mobileNo': mobile,
      'position': position,
      'photo': photo,
      'status': status,
      'permissions': permissions,
      'bankDetails': bankDetails,
      'salary': salary,
      'yearOfExperience': yearOfExperience,
      'clientsServed': clientsServed,
      'commission': commission,
      'commissionPercentage': commissionPercentage,
      'commissionRate': commissionPercentage,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
    };

    if (availability != null) {
      data['availability'] = availability;
      // Flatten availability fields for API compatibility
      availability!.forEach((key, value) {
        data[key] = value;
      });
    }

    if (blockedTimes != null) {
      data['blockedTimes'] = blockedTimes;
    }

    return data;
  }

  String getWorkingHours(DateTime date) {
    if (availability == null) return 'Closed';

    // date.weekday: 1 = Mon, 7 = Sun
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayName = days[date.weekday - 1]; // 0-indexed for array

    final isAvailable = availability?['${dayName}Available'] == true;
    if (!isAvailable) return 'Closed';

    final slots = availability?['${dayName}Slots'] as List<dynamic>?;
    if (slots == null || slots.isEmpty) return 'Closed';

    // Taking the first slot for simplicity as per requirements usually,
    // or join them if multiple. For display "09:00 - 18:30" is typical.
    final firstSlot = slots.first;
    final start = firstSlot['startTime'] ?? '';
    final end = firstSlot['endTime'] ?? '';

    if (start.isEmpty || end.isEmpty) return 'Closed';

    return '$start - $end';
  }
}

class B2BOrder {
  final String id;
  final String orderId;
  final String vendorId;
  final String supplierId;
  final String status;
  final double totalAmount;
  final String shippingAddress;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<StatusHistory> statusHistory;
  final String? courier;
  final String? trackingNumber;

  B2BOrder({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.supplierId,
    required this.status,
    required this.totalAmount,
    required this.shippingAddress,
    required this.createdAt,
    required this.items,
    required this.statusHistory,
    this.courier,
    this.trackingNumber,
  });

  factory B2BOrder.fromJson(Map<String, dynamic> json) {
    return B2BOrder(
      id: json['_id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: json['shippingAddress'] is Map
          ? (json['shippingAddress']['formattedAddress'] ??
                json['shippingAddress'].toString())
          : (json['shippingAddress']?.toString() ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      items:
          (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      statusHistory:
          (json['statusHistory'] as List?)
              ?.map((s) => StatusHistory.fromJson(s))
              .toList() ??
          [],
      courier: json['courier']?.toString(),
      trackingNumber: json['trackingNumber']?.toString(),
    );
  }
}

class ClientOrder {
  final String id;
  final String userId;
  final String vendorId;
  final String regionId;
  final List<ClientOrderItem> items;
  final double totalAmount;
  final double shippingAmount;
  final double taxAmount;
  final String shippingAddress;
  final String contactNumber;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final String? courier;
  final String? trackingNumber;

  ClientOrder({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.regionId,
    required this.items,
    required this.totalAmount,
    required this.shippingAmount,
    required this.taxAmount,
    required this.shippingAddress,
    required this.contactNumber,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.courier,
    this.trackingNumber,
  });

  factory ClientOrder.fromJson(Map<String, dynamic> json) {
    return ClientOrder(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      regionId: json['regionId']?.toString() ?? '',
      items:
          (json['items'] as List?)
              ?.map((i) => ClientOrderItem.fromJson(i))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingAmount: (json['shippingAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: json['shippingAddress'] is Map
          ? (json['shippingAddress']['formattedAddress'] ??
                json['shippingAddress'].toString())
          : (json['shippingAddress']?.toString() ?? ''),
      contactNumber: json['contactNumber']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      courier: json['courier']?.toString(),
      trackingNumber: json['trackingNumber']?.toString(),
    );
  }
}

class ClientOrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? image;

  ClientOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
  });

  factory ClientOrderItem.fromJson(Map<String, dynamic> json) {
    return ClientOrderItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'],
    );
  }
}

class Cart {
  final String id;
  final String vendorId;
  final List<CartItem> items;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.vendorId,
    required this.items,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'] ?? '',
      vendorId: json['vendorId'] ?? '',
      items:
          (json['items'] as List?)?.map((i) => CartItem.fromJson(i)).toList() ??
          [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class CartItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? vendorId;
  final String? supplierName;
  final double? minOrderValue;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.vendorId,
    this.supplierName,
    this.minOrderValue,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      vendorId: json['vendorId'],
      supplierName: json['supplierName'],
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StatusHistory {
  final String status;
  final String notes;
  final DateTime date;

  StatusHistory({
    required this.status,
    required this.notes,
    required this.date,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://partners.glowvitasalon.com/api';
  static const String clientsEndpoint = '/crm/clients';
  static const String staffEndpoint = '/crm/staff';
  static const String servicesEndpoint = '/crm/services';
  static const String adminBaseUrl = 'https://admin.glowvitasalon.com/api';
  static const String productCategoriesEndpoint = '/admin/product-categories';
  static const String crmProductCategoriesEndpoint = '/crm/product-categories';
  static const String notificationTokenEndpoint =
      '/crm/notifications/register-token';
  static const String notificationsEndpoint = '/notifications';
  static const String crmNotificationsEndpoint = '/crm/notifications';
  static const String shippingEndpoint = '/crm/shipping';
  static const String addressesEndpoint = '/crm/addresses';

  // Static notifier for vendor profile
  static final ValueNotifier<VendorProfile?> vendorProfileNotifier =
      ValueNotifier<VendorProfile?>(null);

  // Static notifier for supplier profile
  static final ValueNotifier<SupplierProfile?> supplierProfileNotifier =
      ValueNotifier<SupplierProfile?>(null);

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      print(
        'Warning: No authentication token found in SharedPreferences. API calls may fail.',
      );
    }

    return token.isEmpty ? null : token;
  }

  // Public method to get auth token
  static Future<String?> getAuthToken() async {
    return await _getAuthToken();
  }

  // Centralized HTTP client with SSL bypass
  static http.Client _getHttpClient() {
    final ioClient = HttpClient();
    ioClient.connectionTimeout = const Duration(seconds: 15);
    ioClient.maxConnectionsPerHost = 5; // limit concurrent connections per host
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return http_io.IOClient(
      ioClient,
    ); //  fresh client every call — no shared state
  }

  static bool _isUnauthorizedHandling = false;

  // Handle 401 Unauthorized globally
  static Future<void> _handleUnauthorized() async {
    if (_isUnauthorizedHandling) return;
    _isUnauthorizedHandling = true;

    try {
      print('UNAURHORIZED (401) DETECTED - Logging out user');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      // Keep other data or clear it depending on requirements, usually clear all auth data
      // await prefs.clear();

      if (navigatorKey.currentState != null) {
        // Show a message to the user
        ScaffoldMessengerState? scaffoldMessenger = ScaffoldMessenger.maybeOf(
          navigatorKey.currentContext!,
        );

        if (scaffoldMessenger != null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Navigate to Intro/Login page
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const IntroPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error in handleUnauthorized: $e');
    } finally {
      // Small delay to prevent multiple redirections if many APIs fail at once
      await Future.delayed(const Duration(seconds: 2));
      _isUnauthorizedHandling = false;
    }
  }

  // Generic POST request helper
  static Future<http.Response> _post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool useAuth = true,
  }) async {
    final client = _getHttpClient(); // ✅ fresh client per request
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (useAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Cookie'] = 'crm_access_token=$token';
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }

      final response = await client
          .post(
            Uri.parse(url),
            headers: requestHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 && useAuth) {
        _handleUnauthorized();
      }

      // ✅ Log errors clearly for debugging
      if (response.statusCode >= 400) {
        debugPrint('⚠️ POST $url → ${response.statusCode}: ${response.body}');
      }

      return response;
    } on TimeoutException {
      debugPrint('⏱️ POST $url timed out');
      rethrow;
    } catch (e) {
      debugPrint('❌ POST $url error: $e');
      rethrow;
    } finally {
      client.close(); // ✅ always close to free connection
    }
  }

  // Generic Multipart request helper
  static Future<http.StreamedResponse> _multipartRequest(
    String method,
    String url,
    Map<String, dynamic> body, {
    List<http.MultipartFile>? files,
    bool useAuth = true,
  }) async {
    final client = _getHttpClient();
    try {
      final request = http.MultipartRequest(method, Uri.parse(url));

      if (useAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          request.headers['Cookie'] = 'crm_access_token=$token';
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add fields
      body.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      return await client.send(request).timeout(const Duration(seconds: 60));
    } finally {
      client.close();
    }
  }

  // Generic GET request helper
  static Future<http.Response> _get(
    String url, {
    Map<String, String>? headers,
    bool useAuth = true,
  }) async {
    final client = _getHttpClient();
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (useAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Cookie'] = 'crm_access_token=$token';
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }

      final response = await client
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 && useAuth) {
        _handleUnauthorized();
      }

      return response;
    } finally {
      client.close();
    }
  }

  // Generic PUT request helper
  static Future<http.Response> _put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool useAuth = true,
  }) async {
    final client = _getHttpClient();
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (useAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Cookie'] = 'crm_access_token=$token';
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }

      final response = await client
          .put(Uri.parse(url), headers: requestHeaders, body: json.encode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 && useAuth) {
        _handleUnauthorized();
      }

      return response;
    } finally {
      client.close();
    }
  }

  // Generic DELETE request helper
  static Future<http.Response> _delete(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool useAuth = true,
  }) async {
    final client = _getHttpClient();
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (useAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Cookie'] = 'crm_access_token=$token';
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }

      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(requestHeaders);
      if (body != null) {
        request.body = json.encode(body);
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && useAuth) {
        _handleUnauthorized();
      }

      return response;
    } finally {
      client.close();
    }
  }

  // Generic PATCH request helper
  static Future<http.Response> _patch(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool useAuth = true,
  }) async {
    final client = _getHttpClient();
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (useAuth) {
        final token = await _getAuthToken();
        if (token != null) {
          requestHeaders['Cookie'] = 'crm_access_token=$token';
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }

      final response = await client
          .patch(
            Uri.parse(url),
            headers: requestHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 && useAuth) {
        _handleUnauthorized();
      }

      return response;
    } finally {
      client.close();
    }
  }

  // Login
  static Future<http.Response> login(String email, String password) async {
    return await _post('$baseUrl/crm/auth/login', {
      'email': email,
      'password': password,
    }, useAuth: false);
  }

  // A. Token Registration (POST)
  static Future<http.Response> registerFCMToken(String token) async {
    return await _post('$baseUrl$notificationTokenEndpoint', {
      'token': token,
    }, useAuth: true);
  }

  // B. Fetch Notification History (GET)
  static Future<Map<String, dynamic>> getNotificationHistory() async {
    try {
      final response = await _get('$baseUrl$notificationsEndpoint');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List notificationsData = data['data'] ?? [];
          final int unreadCount = data['unreadCount'] ?? 0;
          return {
            'notifications': notificationsData
                .map((j) => NotificationModel.fromJson(j))
                .toList(),
            'unreadCount': unreadCount,
          };
        }
      }
      throw Exception('Failed to fetch notification history');
    } catch (e) {
      debugPrint('Error fetching notification history: $e');
      rethrow;
    }
  }

  // C. Mark as Read (PATCH)
  static Future<http.Response> markNotificationAsRead({
    String? notificationId,
    bool markAll = false,
  }) async {
    final Map<String, dynamic> body = {};
    if (markAll) {
      body['markAll'] = true;
    } else if (notificationId != null) {
      body['notificationId'] = notificationId;
    }

    return await _patch('$baseUrl$notificationsEndpoint', body, useAuth: true);
  }

  // --- CRM Broadcast Management (Vendors Only) ---

  // POST /api/crm/notifications (Create/Send Broadcast)
  static Future<http.Response> createBroadcast(
    Map<String, dynamic> payload,
  ) async {
    return await _post(
      '$baseUrl$crmNotificationsEndpoint',
      payload,
      useAuth: true,
    );
  }

  // GET /api/crm/notifications (List Sent Broadcasts + Stats)
  static Future<Map<String, dynamic>> getBroadcastLogs() async {
    try {
      final response = await _get('$baseUrl$crmNotificationsEndpoint');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['notifications'] as List? ?? [];

        // Use server provided stats or compute from list
        final stats =
            data['stats'] ??
            {
              'total': notifications.length,
              'pushSent': notifications.where((n) {
                final channels = n['channels'] as List?;
                return channels != null && channels.contains('Push');
              }).length,
              'smsSent': notifications.where((n) {
                final channels = n['channels'] as List?;
                return channels != null && channels.contains('SMS');
              }).length,
              'mostTargeted': 'None',
            };

        return {'notifications': notifications, 'stats': stats};
      }
      throw Exception('Failed to fetch broadcast logs');
    } catch (e) {
      debugPrint('Error fetching broadcast logs: $e');
      rethrow;
    }
  }

  // DELETE /api/crm/notifications (Delete Broadcast Log)
  static Future<http.Response> deleteBroadcastLog(String notificationId) async {
    return await _delete(
      '$baseUrl$crmNotificationsEndpoint',
      body: {'notificationId': notificationId},
      useAuth: true,
    );
  }

  // Forgot Password
  static Future<http.Response> forgotPassword(String email) async {
    return await _post('$baseUrl/crm/auth/forgot-password', {
      'email': email,
    }, useAuth: false);
  }

  // Vendor Register
  static Future<http.Response> registerVendor(
    Map<String, dynamic> payload,
  ) async {
    return await _post('$baseUrl/crm/auth/register', payload, useAuth: false);
  }

  // Supplier Register
  static Future<http.Response> registerSupplier(
    Map<String, dynamic> payload,
  ) async {
    return await _post(
      '$adminBaseUrl/admin/suppliers',
      payload,
      useAuth: false,
    );
  }

  // Send OTP for email verification
  static Future<http.Response> sendOtp(
    String email, {
    String? firstName,
    String? lastName,
    String role = 'vendor',
  }) async {
    final Map<String, dynamic> body = {
      'email': email,
      'role': role.toLowerCase(),
    };

    if (firstName != null && firstName.isNotEmpty) {
      body['firstName'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      body['lastName'] = lastName;
    }

    // Add fullName as a fallback for some backend versions
    if ((firstName != null && firstName.isNotEmpty) ||
        (lastName != null && lastName.isNotEmpty)) {
      body['fullName'] = '${firstName ?? ""} ${lastName ?? ""}'.trim();
      body['name'] = body['fullName']; // Some backends expect 'name'
    }

    return await _post('$baseUrl/crm/auth/send-otp', body, useAuth: false);
  }

  // Verify OTP for email verification
  static Future<http.Response> verifyOtp(
    String email,
    String otp, {
    String role = 'vendor',
  }) async {
    return await _post('$baseUrl/crm/auth/verify-otp', {
      'email': email,
      'otp': otp,
      'role': role.toLowerCase(),
    }, useAuth: false);
  }

  // Get all clients
  static Future<List<Customer>> getClients() async {
    try {
      final response = await _get('$baseUrl$clientsEndpoint');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> clientsData = data['data'];
          return clientsData.map((json) => Customer.fromJson(json)).toList();
        } else {
          throw Exception(
            'Failed to load clients: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load clients: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching clients: $e');
      rethrow;
    }
  }

  // ==================== SUPPLIER PROFILE ==================== //

  static Future<SupplierProfile> getSupplierProfile() async {
    try {
      final response = await _get('$baseUrl/crm/supplier-profile');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final profile = SupplierProfile.fromJson(data['data']);
          supplierProfileNotifier.value = profile;
          return profile;
        } else {
          throw Exception(
            'Failed to load supplier profile: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load supplier profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching supplier profile: $e');
      rethrow;
    }
  }

  static Future<SupplierProfile> updateSupplierProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _put('$baseUrl/crm/supplier-profile', profileData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final profile = SupplierProfile.fromJson(data['data']);
          supplierProfileNotifier.value = profile;
          return profile;
        } else {
          throw Exception(
            'Failed to update supplier profile: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to update supplier profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating supplier profile: $e');
      rethrow;
    }
  }

  // Get all clients
  static Future<List<Customer>> getOnlineClients() async {
    try {
      final response = await _get('$baseUrl$clientsEndpoint?source=online');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> clientsData = data['data'];
          return clientsData.map((json) => Customer.fromJson(json)).toList();
        } else {
          throw Exception(
            'Failed to load online clients: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load online clients: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching online clients: $e');
      rethrow;
    }
  }

  // ==================== SUPPLIER CLIENTS ==================== //
  static Future<List<Customer>> getSupplierClients() async {
    try {
      final response = await _get('$baseUrl/crm/clients');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> clientsData = data['data'];
          return clientsData.map((json) => Customer.fromJson(json)).toList();
        } else {
          throw Exception(
            'Failed to load supplier clients: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load supplier clients: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching supplier clients: $e');
      rethrow;
    }
  }

  static Future<List<Customer>> getOnlineSupplierClients() async {
    try {
      final response = await _get('$baseUrl/crm/clients?source=online');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> clientsData = data['data'];
          return clientsData.map((json) => Customer.fromJson(json)).toList();
        } else {
          throw Exception(
            'Failed to load online supplier clients: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load online supplier clients: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching online supplier clients: $e');
      rethrow;
    }
  }

  static Future<Customer> addSupplierClient(Customer customer) async {
    try {
      final response = await _post('$baseUrl/crm/clients', customer.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Customer.fromJson(data['data']);
        } else {
          throw Exception(
            'Failed to add supplier client: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to add supplier client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error adding supplier client: $e');
      rethrow;
    }
  }

  static Future<Customer> updateSupplierClient(Customer customer) async {
    try {
      if (customer.id == null)
        throw Exception('Customer ID is required for update');
      final response = await _put('$baseUrl/crm/clients', customer.toJson());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Customer.fromJson(data['data']);
        } else {
          throw Exception(
            'Failed to update supplier client: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to update supplier client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating supplier client: $e');
      rethrow;
    }
  }

  static Future<bool> deleteSupplierClient(String clientId) async {
    try {
      final response = await _delete(
        '$baseUrl/crm/clients',
        body: {'id': clientId},
      );
      if ([200, 201, 204].contains(response.statusCode)) {
        return true;
      } else {
        throw Exception(
          'Failed to delete supplier client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting supplier client: $e');
      rethrow;
    }
  }

  // Get all products
  static Future<List<Product>> getProducts() async {
    try {
      final response = await _get('$baseUrl/crm/products');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> productsData = data['data'];
          return productsData.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception(
            'Failed to load products: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load products: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  // Get products by category
  static Future<List<Product>> getProductMastersByCategory(
    String categoryName,
  ) async {
    try {
      final response = await _get(
        '$baseUrl/crm/product-masters?category=$categoryName',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> productsData = data['data'];
          List<Product> allMasters = productsData
              .map((json) => Product.fromJson(json))
              .toList();
          // Client-side filtering to ensure strict category matching
          return allMasters
              .where(
                (p) => p.category?.toLowerCase() == categoryName.toLowerCase(),
              )
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load product masters: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching product masters: $e');
      rethrow;
    }
  }

  // Delete a product
  static Future<bool> deleteProduct(String productId) async {
    try {
      final response = await _delete(
        '$baseUrl/crm/products',
        body: {'id': productId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
            'Failed to delete product: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to delete product: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Create a new product
  static Future<bool> createProduct(
    Map<String, dynamic> productData, {
    List<String>? imagePaths,
  }) async {
    try {
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final List<http.MultipartFile> files = [];
        for (var path in imagePaths) {
          if (File(path).existsSync()) {
            files.add(await http.MultipartFile.fromPath('productImages', path));
          }
        }

        final streamedResponse = await _multipartRequest(
          'POST',
          '$baseUrl/crm/products',
          productData,
          files: files,
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          return data['success'] == true;
        } else {
          throw Exception(
            'Failed to create product: ${response.statusCode} - ${response.body}',
          );
        }
      } else {
        final response = await _post('$baseUrl/crm/products', productData);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          return data['success'] == true;
        } else {
          throw Exception(
            'Failed to create product: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Update an existing product
  static Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> productData, {
    List<String>? imagePaths,
  }) async {
    try {
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final List<http.MultipartFile> files = [];
        for (var path in imagePaths) {
          if (!path.startsWith('http') && File(path).existsSync()) {
            files.add(await http.MultipartFile.fromPath('productImages', path));
          }
        }

        final streamedResponse = await _multipartRequest(
          'PUT',
          '$baseUrl/crm/products?id=$productId',
          {...productData, 'id': productId},
          files: files,
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        } else {
          throw Exception(
            'Failed to update product: ${response.statusCode} - ${response.body}',
          );
        }
      } else {
        final response = await _put('$baseUrl/crm/products?id=$productId', {
          ...productData,
          'id': productId,
        });
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        } else {
          throw Exception(
            'Failed to update product: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Get all product categories
  static Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final response = await _get(
        '$adminBaseUrl$productCategoriesEndpoint',
        useAuth: false,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(
            'Failed to load categories: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  // Add a new product category
  static Future<Map<String, dynamic>> addProductCategory(
    String name,
    String description,
  ) async {
    try {
      final response = await _post('$adminBaseUrl$productCategoriesEndpoint', {
        'name': name,
        'description': description,
      }, useAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(
            'Failed to add category: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to add category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  // ==================== CRM PRODUCT CATEGORIES ==================== //

  static Future<List<Map<String, dynamic>>> getCRMProductCategories() async {
    try {
      final response = await _get('$baseUrl$crmProductCategoriesEndpoint');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(
            'Failed to load crm categories: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load crm categories: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching crm categories: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addCRMProductCategory(
    String name,
    String description,
  ) async {
    try {
      final response = await _post('$baseUrl$crmProductCategoriesEndpoint', {
        'name': name,
        'description': description,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(
            'Failed to add crm category: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Failed to add crm category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding crm category: $e');
      rethrow;
    }
  }

  static Future<List<StaffMember>> getStaff() async {
    try {
      final response = await _get('$baseUrl$staffEndpoint');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> staffList = [];

        if (data is List) {
          staffList = data;
        } else if (data is Map) {
          staffList = data['data'] ?? data['staff'] ?? [];
        }

        return staffList.map((json) => StaffMember.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load staff: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching staff: $e');
      rethrow;
    }
  }

  // Create a new staff member
  static Future<http.Response> createStaff(
    Map<String, dynamic> staffData,
  ) async {
    return await _post('$baseUrl$staffEndpoint', staffData);
  }

  // Update an existing staff member
  static Future<http.Response> updateStaff(
    String staffId,
    Map<String, dynamic> staffData,
  ) async {
    return await _put('$baseUrl$staffEndpoint?id=$staffId', staffData);
  }

  // Delete a staff member
  static Future<http.Response> deleteStaff(String staffId) async {
    return await _delete('$baseUrl$staffEndpoint?id=$staffId');
  }

  // Get staff earnings
  static Future<Map<String, dynamic>> getStaffEarnings(String staffId) async {
    try {
      final response = await _get('$baseUrl$staffEndpoint/earnings/$staffId');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load staff earnings: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching staff earnings: $e');
      rethrow;
    }
  }

  // Record a new payout for staff
  static Future<http.Response> recordStaffPayout(
    String staffId,
    Map<String, dynamic> payoutData,
  ) async {
    return await _post('$baseUrl$staffEndpoint/earnings/$staffId', payoutData);
  }

  // Send login credentials to a staff member via email
  static Future<bool> sendStaffCredentials(String staffId) async {
    try {
      final response = await _post('$baseUrl$staffEndpoint/send-credentials', {
        'staffId': staffId,
      });
      print(
        'Send Credentials Response [${response.statusCode}]: ${response.body}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true ||
            data['message']?.toString().toLowerCase().contains('sent') ==
                true ||
            data['message']?.toString().toLowerCase().contains('success') ==
                true;
      } else {
        throw Exception(
          'Failed to send credentials: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending staff credentials: $e');
      rethrow;
    }
  }

  // ==================== MARKETPLACE SUPPLIERS & PRODUCTS ==================== //

  /// Fetch all products from suppliers for the marketplace
  static Future<List<MarketplaceProduct>> getSupplierProducts() async {
    try {
      final response = await _get('$baseUrl/crm/supplier-products');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => MarketplaceProduct.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to load supplier products',
          );
        }
      } else {
        throw Exception(
          'Failed to load supplier products: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching supplier products: $e');
      rethrow;
    }
  }

  /// Create a new order in the marketplace
  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _post('$baseUrl/crm/orders', orderData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to create order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Addresses APIs
  static Future<Map<String, dynamic>> getAddresses() async {
    final response = await _get('$baseUrl$addressesEndpoint');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load addresses: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addAddress(
    Map<String, dynamic> addressData,
  ) async {
    final response = await _post('$baseUrl$addressesEndpoint', addressData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add address: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateAddress(
    String id,
    Map<String, dynamic> addressData,
  ) async {
    final response = await _put('$baseUrl$addressesEndpoint/$id', addressData);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update address: ${response.body}');
    }
  }

  /// Fetch all orders from the marketplace
  static Future<List<B2BOrder>> getOrders() async {
    try {
      final response = await _get('$baseUrl/crm/orders');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> ordersData = [];
        if (decoded is List) {
          ordersData = decoded;
        } else if (decoded is Map) {
          ordersData = decoded['data'] ?? decoded['orders'] ?? [];
        }
        return ordersData.map((json) => B2BOrder.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load orders: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Fetch all client orders
  static Future<List<ClientOrder>> getClientOrders() async {
    try {
      final response = await _get('$baseUrl/crm/client-orders');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> ordersData = [];
        if (decoded is List) {
          ordersData = decoded;
        } else if (decoded is Map) {
          ordersData = decoded['data'] ?? decoded['orders'] ?? [];
        }
        return ordersData.map((json) => ClientOrder.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load client orders: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching client orders: $e');
      rethrow;
    }
  }

  /// Update the status of an existing order
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? trackingNumber,
    String? courier,
    bool isClientOrder = false,
  }) async {
    try {
      final Map<String, dynamic> body = {'orderId': orderId, 'status': status};

      if (trackingNumber != null && trackingNumber.isNotEmpty) {
        body['trackingNumber'] = trackingNumber;
      }
      if (courier != null && courier.isNotEmpty) {
        body['courier'] = courier;
      }

      final endpoint = isClientOrder ? '/crm/client-orders' : '/crm/orders';
      final response = await _patch('$baseUrl$endpoint', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update order status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Add product to cart
  static Future<Cart> addToCart(Map<String, dynamic> itemData) async {
    try {
      final response = await _post('$baseUrl/crm/cart', itemData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Cart.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to add to cart');
        }
      } else {
        throw Exception(
          'Failed to add to cart: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Update cart item quantity
  static Future<Cart> updateCartQuantity(String productId, int quantity) async {
    try {
      final response = await _put('$baseUrl/crm/cart', {
        "productId": productId,
        "quantity": quantity,
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Cart.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update cart');
        }
      } else {
        throw Exception(
          'Failed to update cart: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating cart quantity: $e');
      rethrow;
    }
  }

  /// Delete item from cart
  static Future<Cart> deleteFromCart(String productId) async {
    try {
      final response = await _delete(
        '$baseUrl/crm/cart',
        body: {"productId": productId},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Cart.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to delete from cart');
        }
      } else {
        throw Exception(
          'Failed to delete from cart: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting from cart: $e');
      rethrow;
    }
  }

  /// Fetch cart data
  static Future<Cart?> getCart() async {
    try {
      final response = await _get('$baseUrl/crm/cart');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Cart.fromJson(data['data']);
        }
        return null; // Cart might be empty
      } else {
        throw Exception(
          'Failed to load cart: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching cart: $e');
      rethrow;
    }
  }

  // ==================== INVENTORY ==================== //

  static Future<List<InventoryTransaction>>
  getSupplierInventoryTransactions() async {
    try {
      final response = await _get('$baseUrl/crm/inventory/transactions');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => InventoryTransaction.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to load inventory transactions',
          );
        }
      } else {
        throw Exception(
          'Failed to load inventory transactions: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching inventory transactions: $e');
      rethrow;
    }
  }

  // ==================== PRODUCT QUESTIONS ==================== //

  /// Fetch all product questions for the vendor
  static Future<List<Map<String, dynamic>>> getProductQuestions() async {
    try {
      final response = await _get('$baseUrl/crm/product-questions');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['questions'] != null) {
          return List<Map<String, dynamic>>.from(data['questions'] as List);
        } else {
          throw Exception(data['message'] ?? 'Failed to load questions');
        }
      } else {
        throw Exception(
          'Failed to load questions: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching product questions: $e');
      rethrow;
    }
  }

  /// Answer or update a product question (also controls isPublished)
  static Future<bool> answerProductQuestion(
    String questionId,
    String answer,
    bool isPublished,
  ) async {
    final client = _getHttpClient();
    try {
      final token = await _getAuthToken();
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) {
        requestHeaders['Cookie'] = 'crm_access_token=$token';
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      final url = '$baseUrl/crm/product-questions/$questionId';
      final bodyStr = json.encode({
        'answer': answer,
        'isPublished': isPublished,
      });

      // Build raw PATCH request (same pattern as DELETE to avoid SSL issues)
      final request = http.Request('PATCH', Uri.parse(url));
      request.headers.addAll(requestHeaders);
      request.body = bodyStr;

      print('PATCH $url  body=$bodyStr');

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Answer product question response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to answer question: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error answering product question: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Toggle publish status of a product question
  static Future<bool> togglePublishProductQuestion(
    String questionId,
    bool isPublished,
  ) async {
    try {
      final response = await _put(
        '$baseUrl/crm/product-questions/$questionId',
        {'isPublished': isPublished},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to toggle publish: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error toggling publish product question: $e');
      rethrow;
    }
  }

  /// Delete a product question
  static Future<bool> deleteProductQuestion(String questionId) async {
    try {
      final response = await _delete(
        '$baseUrl/crm/product-questions/$questionId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Failed to delete question: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting product question: $e');
      rethrow;
    }
  }

  // Add a new client
  static Future<Customer> addClient(Customer customer) async {
    try {
      final response = await _post(
        '$baseUrl$clientsEndpoint',
        customer.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Customer.fromJson(data['data']);
        } else {
          throw Exception(
            'Failed to add client: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to add client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error adding client: $e');
      rethrow;
    }
  }

  // Update an existing client
  static Future<Customer> updateClient(Customer customer) async {
    try {
      if (customer.id == null)
        throw Exception('Customer ID is required for update');

      final response = await _put(
        '$baseUrl$clientsEndpoint',
        customer.toJson(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Customer.fromJson(data['data']);
        } else {
          throw Exception(
            'Failed to update client: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to update client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating client: $e');
      rethrow;
    }
  }

  // Delete a client
  static Future<bool> deleteClient(String clientId) async {
    try {
      final response = await _delete(
        '$baseUrl$clientsEndpoint',
        body: {'id': clientId},
      );

      if ([200, 201, 204].contains(response.statusCode)) {
        return true;
      } else {
        throw Exception(
          'Failed to delete client: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting client: $e');
      rethrow;
    }
  }

  // ==================== GET SERVICES ==================== //
  static Future<List<Service>> getServices() async {
    try {
      final response = await _get('$baseUrl$servicesEndpoint');

      // print('Services API Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> servicesList = [];

        if (data is List) {
          servicesList = data;
        } else if (data is Map) {
          servicesList = data['services'] ?? data['data'] ?? [];
        }

        return servicesList.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load services: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching services: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getWeddingStaffAndServices() async {
    try {
      final response = await _get('$baseUrl/crm/wedding-packages');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final staffData = data['data']['staff'] as List? ?? [];
          final servicesData = data['data']['services'] as List? ?? [];

          return {
            'staff': staffData
                .map((json) => StaffMember.fromJson(json))
                .toList(),
            'services': servicesData
                .map((json) => Service.fromJson(json))
                .toList(),
          };
        } else {
          return {'staff': [], 'services': []};
        }
      } else {
        throw Exception(
          'Failed to load wedding packages: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching wedding packages: $e');
      rethrow;
    }
  }

  // ==================== SERVICE CATEGORIES ==================== //
  static Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      final response = await _get('$baseUrl/crm/categories');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
        if (decoded is Map) {
          final data =
              decoded['data'] ??
              decoded['categories'] ??
              decoded['category'] ??
              [];
          if (data is List) return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  static Future<http.Response> createServiceCategory(
    Map<String, dynamic> data,
  ) async {
    return await _post('$baseUrl/crm/categories', data);
  }

  // ==================== SERVICES BY CATEGORY ==================== //
  static Future<List<Map<String, dynamic>>> getServicesByCategory(
    String categoryName,
  ) async {
    try {
      // Filtering by category (can be ID or name depending on server)
      final response = await _get(
        '$baseUrl/crm/services?category=$categoryName',
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = decoded['data'] ?? decoded['services'] ?? [];
        }
        return List<Map<String, dynamic>>.from(list);
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching services by category: $e');
      rethrow;
    }
  }

  // ==================== MASTER SERVICES ==================== //
  static Future<http.Response> createMasterCategory(
    Map<String, dynamic> data,
  ) async {
    return await _post('$adminBaseUrl/admin/categories', data);
  }

  static Future<http.Response> createMasterService(
    Map<String, dynamic> data,
  ) async {
    return await _post('$adminBaseUrl/admin/services', data);
  }

  // ==================== ADD-ONS ==================== //
  static Future<List<AddOn>> getAddOns() async {
    try {
      final response = await _get('$baseUrl/crm/add-ons');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // User provided response format: { "addOns": [...] }
        if (data['addOns'] != null) {
          List<dynamic> addonsData = data['addOns'];
          return addonsData.map((json) => AddOn.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          // Fallback for old format if any
          List<dynamic> addonsData = data['data'];
          return addonsData.map((json) => AddOn.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load add-ons: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching add-ons: $e');
      rethrow;
    }
  }

  static Future<bool> createAddOn(AddOn addon) async {
    try {
      final response = await _post('$baseUrl/crm/add-ons', addon.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['addOn'] != null || data['success'] == true;
      } else {
        throw Exception(
          'Failed to create add-on: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating add-on: $e');
      rethrow;
    }
  }

  static Future<bool> updateAddOn(String id, AddOn addon) async {
    try {
      final response = await _put('$baseUrl/crm/add-ons', addon.toJson());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message']?.contains('successfully') == true ||
            data['addOn'] != null ||
            data['success'] == true;
      } else {
        throw Exception(
          'Failed to update add-on: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating add-on: $e');
      rethrow;
    }
  }

  static Future<bool> deleteAddOn(String id) async {
    try {
      final response = await _delete('$baseUrl/crm/add-ons?id=$id');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message']?.contains('successfully') == true;
      } else {
        throw Exception(
          'Failed to delete add-on: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting add-on: $e');
      rethrow;
    }
  }
  // ============================================================

  static Future<bool> deleteService(String serviceId) async {
    try {
      final response = await _delete(
        '$baseUrl$servicesEndpoint',
        body: {'serviceId': serviceId},
      );

      print(
        'Delete Service Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message']?.contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Failed to delete service');
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized. Your session may have expired. Please login again.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You do not have permission to delete this service.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Service not found. It may have already been deleted.');
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server. Please try again later.');
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Unexpected error in deleteService: $e');
      rethrow;
    }
  }

  static Future<bool> createService(Map<String, dynamic> serviceData) async {
    try {
      // IMPORTANT: category must be the MongoDB _id (String), not the name
      final String? categoryId =
          serviceData['category_id']; // will be passed from UI
      if (categoryId == null || categoryId.isEmpty) {
        throw Exception('Category ID is required');
      }

      // Staff must be list of staff IDs (from StaffMember.id), not names
      final List<String> staffIds =
          ((serviceData['staff_ids'] ?? serviceData['staff']) as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [];

      // Parse duration string like "30 min" → minutes (int)
      final int durationMinutes = _parseDuration(serviceData['duration']);

      // Build the service object exactly as the API expects
      final Map<String, dynamic> mappedServiceData = {
        'name': serviceData['name']?.toString().trim(),
        'category': categoryId,
        'price': (serviceData['price'] as num).toDouble().toInt(),
        if (serviceData['discounted_price'] != null)
          'discountedPrice': (serviceData['discounted_price'] as num)
              .toDouble()
              .toInt(),
        'duration': durationMinutes,
        'description': serviceData['description']?.toString().trim() ?? '',
        'gender': serviceData['gender'] ?? 'unisex',
        'staff': staffIds,
        'commission': serviceData['allow_commission'] ?? false,
        'homeService': serviceData['home_service'] is Map
            ? serviceData['home_service']
            : serviceData['homeService'] ??
                  {
                    'available': serviceData['home_service'] ?? false,
                    'charges': null,
                  },
        'weddingService': serviceData['wedding_service'] is Map
            ? serviceData['wedding_service']
            : serviceData['weddingService'] ??
                  {
                    'available': serviceData['wedding_service'] ?? false,
                    'charges': null,
                  },
        'bookingInterval':
            int.tryParse(serviceData['booking_interval']?.toString() ?? '0') ??
            0,
        'tax': serviceData['tax'] is Map
            ? serviceData['tax']
            : {
                'enabled': serviceData['enable_tax'] ?? false,
                'type': 'percentage',
                'value': serviceData['tax_value'] ?? 0,
              },
        'onlineBooking': serviceData['onlineBooking'] ?? true,
        if (serviceData['image'] != null)
          'image': serviceData['image'], // base64 data URL
        'addOns': serviceData['addOns'] ?? [],
      };

      final response = await _post('$baseUrl$servicesEndpoint', {
        'services': [mappedServiceData],
      });

      print(
        'Create Service Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['message'] != null &&
            data['message'].toString().contains('successfully')) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Unknown response from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized. Your session may have expired. Please login again.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You do not have permission to create services.',
        );
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server. Please try again later.');
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Unexpected error in createService: $e');
      rethrow;
    }
  }

  // Helper method to parse duration string to minutes
  static int _parseDuration(String? durationStr) {
    if (durationStr == null) return 0;

    // Handle format like "30 min", "1 hour", "1 hour 30 min"
    if (durationStr.contains('hour')) {
      final parts = durationStr.split(' ');
      int hours = 0;
      int minutes = 0;

      for (int i = 0; i < parts.length; i++) {
        if (parts[i].contains(RegExp(r'[0-9]+'))) {
          final value = int.tryParse(parts[i]);
          if (value != null) {
            if (i + 1 < parts.length && parts[i + 1].contains('hour')) {
              hours = value;
            } else if (i + 1 < parts.length && parts[i + 1].contains('min')) {
              minutes = value;
            }
          }
        }
      }

      return hours * 60 + minutes;
    } else {
      // Handle format like "30 min"
      final parts = durationStr.split(' ');
      if (parts.isNotEmpty) {
        final value = int.tryParse(parts[0]);
        if (value != null) return value;
      }
    }

    return 0;
  }

  // Helper method to parse tax rate string to number
  static double? _parseTaxRate(String? taxRateStr) {
    if (taxRateStr == null || taxRateStr == 'Tax Free') return null;

    // Extract numeric part from strings like "18%"
    final taxPercent = taxRateStr.replaceAll('%', '');
    return double.tryParse(taxPercent);
  }

  static Future<bool> updateService(
    String serviceId,
    Map<String, dynamic> serviceData,
  ) async {
    try {
      // Map the field names to match API expectations (same structure as createService)
      final mappedServiceData = {
        '_id': serviceId,
        'name': serviceData['name'],
        'category': serviceData['category_id'],
        'price': (serviceData['price'] as num).toInt(),
        if (serviceData['discounted_price'] != null)
          'discountedPrice': (serviceData['discounted_price'] as num)
              .toDouble()
              .toInt(),
        'duration': (serviceData['duration'] is int)
            ? serviceData['duration'] as int
            : _parseDuration(serviceData['duration']?.toString()),
        'description': serviceData['description'] ?? '',
        'gender': serviceData['gender'] ?? 'unisex',
        'staff': serviceData['staff'] ?? [],
        'commission': serviceData['allow_commission'] ?? false,
        'homeService': serviceData['homeService'] is Map
            ? serviceData['homeService']
            : {
                'available': serviceData['home_service'] ?? false,
                'charges': serviceData['homeService']?['charges'],
              },
        'weddingService': serviceData['weddingService'] is Map
            ? serviceData['weddingService']
            : {
                'available': serviceData['wedding_service'] ?? false,
                'charges': serviceData['weddingService']?['charges'],
              },
        'bookingInterval':
            int.tryParse(serviceData['booking_interval']?.toString() ?? '0') ??
            0,
        'tax': serviceData['tax'] is Map
            ? serviceData['tax']
            : {
                'enabled': serviceData['enable_tax'] ?? false,
                'type': 'percentage',
                'value': serviceData['tax_value'] ?? 0,
              },
        'onlineBooking': serviceData['onlineBooking'] ?? true,
        'addOns': serviceData['addOns'] ?? [],
      };

      if (serviceData['image'] != null) {
        mappedServiceData['image'] = serviceData['image'];
      }

      final response = await _put('$baseUrl$servicesEndpoint', {
        'services': [mappedServiceData],
      });

      print(
        'Update Service Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message']?.contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Failed to update service');
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized. Your session may have expired. Please login again.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You do not have permission to update this service.',
        );
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server. Please try again later.');
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Unexpected error in updateService: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAppointments({
    int? page,
    int? limit,
  }) async {
    try {
      String url = '$baseUrl/crm/appointments';
      Map<String, String> queryParams = {};

      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      } else {
        queryParams['limit'] = '100';
      }

      if (queryParams.isNotEmpty) {
        url += '?' + Uri(queryParameters: queryParams).query;
      }

      final response = await _get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<AppointmentModel> items = [];
        int total = 0;

        if (data is List) {
          items = data
              .whereType<Map<String, dynamic>>()
              .map((json) => AppointmentModel.fromJson(json))
              .toList();
          total = items.length;
        } else if (data is Map) {
          final rawData = data['data'] ?? [];
          if (rawData is List) {
            items = rawData
                .whereType<Map<String, dynamic>>()
                .map((json) => AppointmentModel.fromJson(json))
                .toList();
          }
          // Some APIs use 'total', 'totalItems', 'count', etc.
          total =
              data['total'] ??
              data['totalItems'] ??
              data['count'] ??
              items.length;
        }

        return {'data': items, 'total': total};
      } else {
        throw Exception(
          'Failed to load appointments: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow;
    }
  }

  // Update appointment status
  static Future<Map<String, dynamic>> updateAppointmentStatus(
    String id,
    String status, {
    String? cancellationReason,
  }) async {
    try {
      final Map<String, dynamic> body = {'_id': id, 'status': status};

      if (status == 'cancelled' && cancellationReason != null) {
        body['cancellationReason'] = cancellationReason;
      }

      print('🔄 Updating status: $status for ID: $id');

      final response = await _patch('$baseUrl/crm/appointments', body);

      print(
        '📥 Update Status Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // Returns the full response including updated appointment
      } else {
        throw Exception(
          'Failed to update status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      rethrow;
    }
  }

  static Future<AppointmentModel> getAppointmentById(String id) async {
    try {
      print('🔍 Fetching appointment with ID: $id');

      final response = await _get('$baseUrl/crm/appointments?id=$id');

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          print('📋 Received ${data.length} appointments in response');

          // Find the appointment matching the requested ID
          final matchingAppt = data.firstWhere(
            (appt) => appt['_id'] == id,
            orElse: () => data[0], // Fallback to first if no match
          );

          print('✅ Using appointment with ID: ${matchingAppt['_id']}');
          return AppointmentModel.fromJson(matchingAppt);
        } else if (data is Map && data['data'] != null) {
          print('📦 Received appointment data as Map');
          return AppointmentModel.fromJson(data['data']);
        } else {
          throw Exception(
            'Unexpected response format from appointment detail API',
          );
        }
      } else {
        throw Exception(
          'Failed to load appointment details: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching appointment details: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      final response = await _post(
        '$baseUrl/crm/appointments',
        appointmentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to create appointment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  static Future<void> deleteAppointment(String id) async {
    try {
      print('🗑️ Deleting appointment with ID: $id');

      final response = await _delete('$baseUrl/crm/appointments/$id');

      print('📥 Delete response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Successfully deleted appointment: $id');
      } else {
        throw Exception(
          'Failed to delete appointment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> collectPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      print(
        '🔄 Collecting payment for appointment ID: ${paymentData['appointmentId']}',
      );

      final response = await _post(
        '$baseUrl/crm/payments/collect',
        paymentData,
      );

      print(
        '📥 Collect Payment Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to collect payment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error collecting payment: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateAppointment(
    String id,
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      print('🔄 Updating appointment with ID: $id');

      final response = await _put(
        '$baseUrl/crm/appointments/$id',
        appointmentData,
      );

      print(
        '📥 Update Appointment Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to update appointment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error updating appointment: $e');
      rethrow;
    }
  }

  static Future<List<WeddingPackage>> getWeddingPackages() async {
    try {
      final response = await _get('$baseUrl/crm/wedding-packages');

      print(
        'Wedding Packages Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic>? packagesData;

        if (data is List) {
          packagesData = data;
        } else if (data is Map) {
          packagesData =
              data['weddingPackages'] ?? data['data'] ?? data['packages'];
        }

        if (packagesData != null) {
          return packagesData
              .map((json) => WeddingPackage.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Failed to load wedding packages: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching wedding packages: $e');
      rethrow;
    }
  }

  static Future<bool> toggleWeddingPackageStatus(
    String id,
    bool isActive,
  ) async {
    try {
      final response = await _patch('$baseUrl/crm/wedding-packages/$id', {
        'isActive': isActive,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to toggle status: ${response.body}');
      }
    } catch (e) {
      print('Error toggling package status: $e');
      return false;
    }
  }

  static Future<bool> createWeddingPackage(
    Map<String, dynamic> packageData,
  ) async {
    try {
      final response = await _post(
        '$baseUrl/crm/wedding-packages',
        packageData,
      );

      print(
        'Create Wedding Package Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['message']?.toString().contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
          'Failed to create wedding package: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating wedding package: $e');
      rethrow;
    }
  }

  static Future<bool> updateWeddingPackage(
    String? id,
    Map<String, dynamic> packageData,
  ) async {
    try {
      if (id == null) return false;

      final response = await _put('$baseUrl/crm/wedding-packages', {
        ...packageData,
        'packageId': id,
      });

      print(
        'Update Wedding Package Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true ||
            data['message']?.toString().contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
          'Failed to update wedding package: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating wedding package: $e');
      rethrow;
    }
  }

  static Future<bool> deleteWeddingPackage(String id) async {
    try {
      final response = await _delete(
        '$baseUrl/crm/wedding-packages',
        body: {'packageId': id},
      );

      print(
        'Delete Wedding Package Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true ||
            data['message']?.toString().contains('successfully') == true;
      } else {
        throw Exception(
          'Failed to delete wedding package: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error deleting wedding package: $e');
      rethrow;
    }
  }

  // ==================== VENDOR PROFILE ==================== //
  static Future<VendorProfile> getVendorProfile() async {
    try {
      final response = await _get('$baseUrl/crm/vendor');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final profile = VendorProfile.fromJson(data['data']);
          vendorProfileNotifier.value = profile; // Update the global notifier
          return profile;
        } else {
          throw Exception(
            'Failed to load vendor profile: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load vendor profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching vendor profile: $e');
      rethrow;
    }
  }

  static Future<VendorProfile> updateVendorProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _put('$baseUrl/crm/vendor', profileData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return VendorProfile.fromJson(data['data']);
        } else {
          throw Exception(
            'Failed to update vendor profile: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to update vendor profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating vendor profile: $e');
      rethrow;
    }
  }

  // ==================== EXPENSES ==================== //

  static Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final response = await _get('$baseUrl/crm/expenses');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
        if (decoded is Map && decoded['data'] != null) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
        return [];
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      rethrow;
    }
  }

  static Future<bool> addExpense(Map<String, dynamic> data) async {
    try {
      final response = await _post('$baseUrl/crm/expenses', data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to add expense: ${response.body}');
      }
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  static Future<bool> updateExpense(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _put('$baseUrl/crm/expenses?id=$id', {
        ...data,
        'id': id,
      });
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update expense: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // ==================== SUBSCRIPTION ==================== //

  // ==================== SUBSCRIPTION ==================== //

  static Future<List<Plan>> getSubscriptionPlans() async {
    try {
      final response = await _get('$baseUrl/crm/subscription/plans');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = (data is List) ? data : (data['data'] ?? []);
        return list.map((i) => Plan.fromJson(i)).toList();
      } else {
        throw Exception(
          'Failed to load subscription plans: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching subscription plans: $e');
      rethrow;
    }
  }

  static Future<bool> renewSubscription({
    required String planId,
    required String userType,
    required int amount,
    String? paymentId,
  }) async {
    try {
      final response = await _post('$baseUrl/crm/subscription/renew', {
        'planId': planId,
        'userType': userType,
        'amount': amount,
        if (paymentId != null) 'paymentId': paymentId,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(
          data['message'] ?? 'Failed to renew subscription: ${response.body}',
        );
      }
    } catch (e) {
      print('Error renewing subscription: $e');
      rethrow;
    }
  }

  static Future<bool> deleteExpense(String id) async {
    try {
      final response = await _delete('$baseUrl/crm/expenses', body: {'id': id});
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete expense: ${response.body}');
      }
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  static Future<List<OfferModel>> getOffers() async {
    try {
      print('🔍 Fetching all offers...');

      final response = await _get('$baseUrl/crm/offers');

      print('📥 Offers Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => OfferModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load offers: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching offers: $e');
      rethrow;
    }
  }

  static Future<http.Response> createOffer(Map<String, dynamic> data) async {
    try {
      print('🚀 Creating new offer...');
      final response = await _post('$baseUrl/crm/offers', data);
      print(
        '📥 Create Offer Response [${response.statusCode}]: ${response.body}',
      );
      return response;
    } catch (e) {
      print('❌ Error creating offer: $e');
      rethrow;
    }
  }

  static Future<http.Response> updateOffer(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      print('🔄 Updating offer with ID: $id...');
      // Merge ID into data as requested
      final Map<String, dynamic> payload = {...data, 'id': id};

      final response = await _put('$baseUrl/crm/offers', payload);
      print(
        '📥 Update Offer Response [${response.statusCode}]: ${response.body}',
      );
      return response;
    } catch (e) {
      print('❌ Error updating offer: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _get('$baseUrl/crm/categories');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> categoryData;
        if (data is List) {
          categoryData = data;
        } else {
          categoryData = data['data'] ?? data['categories'] ?? [];
        }
        return categoryData.map((c) => c as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  static Future<bool> deleteOffer(String id) async {
    try {
      print('🗑️ Deleting offer with ID: $id');

      final response = await _delete('$baseUrl/crm/offers?id=$id');

      print(
        '📥 Delete Offer Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to delete offer: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error deleting offer: $e');
      rethrow;
    }
  }

  // ==================== WORKING HOURS ==================== //
  static Future<Map<String, dynamic>> getWorkingHours() async {
    try {
      print('🔍 Fetching working hours...');

      final response = await _get('$baseUrl/crm/workinghours');

      print(
        '📥 Working Hours Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load working hours: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching working hours: $e');
      rethrow;
    }
  }

  static Future<bool> updateWorkingHours(
    Map<String, dynamic> workingHoursData,
  ) async {
    try {
      print('🔄 Updating working hours...');
      print('📤 Data: ${json.encode(workingHoursData)}');

      final response = await _put(
        '$baseUrl/crm/workinghours',
        workingHoursData,
      );

      print(
        '📥 Update Working Hours Response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true ||
            data['message']?.toString().contains('successfully') == true ||
            data['message']?.toString().contains('updated') == true;
      } else {
        throw Exception(
          'Failed to update working hours: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error updating working hours: $e');
      rethrow;
    }
  }

  // Get all invoices
  static Future<List<BillingInvoice>> getInvoices() async {
    try {
      final response = await _get('$baseUrl/crm/billing');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> invoicesData = data['data'];
          return invoicesData
              .map((json) => BillingInvoice.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'Failed to load invoices: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load invoices: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching invoices: $e');
      rethrow;
    }
  }

  // Create a new bill
  static Future<Map<String, dynamic>> createBilling(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _post('$baseUrl/crm/billing', payload);
      print(
        '📥 Create Billing Response [${response.statusCode}]: ${response.body}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final data = json.decode(response.body);
        throw Exception(
          'Failed to create bill: ${data['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error creating bill: $e');
      rethrow;
    }
  }

  // ==================== REVIEWS ==================== //

  static Future<List<Map<String, dynamic>>> getReviews() async {
    try {
      final response = await _get('$baseUrl/crm/reviews');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['reviews'] != null) {
          return List<Map<String, dynamic>>.from(data['reviews']);
        }
        return [];
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      rethrow;
    }
  }

  static Future<bool> updateReviewStatus(
    String reviewId,
    bool isApproved,
  ) async {
    try {
      print('📤 Updating review $reviewId status to isApproved: $isApproved');
      final response = await _patch('$baseUrl/crm/reviews/$reviewId', {
        'isApproved': isApproved,
      });

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Review Status Updated: ${data['message']}');
        return data['success'] == true;
      } else {
        throw Exception(
          'Failed to update review status [${response.statusCode}]: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error updating review status: $e');
      rethrow;
    }
  }

  static Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await _delete('$baseUrl/crm/reviews/$reviewId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Many APIs return success in a field if 200
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        }
        return true;
      } else {
        throw Exception('Failed to delete review: ${response.body}');
      }
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════
  // SETTLEMENTS METHODS
  // ══════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSettlements() async {
    try {
      final response = await _get('$baseUrl/crm/settlements');

      debugPrint('Get Settlements - Status: ${response.statusCode}');
      debugPrint('Get Settlements - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'data': data['data'] ?? [], 'summary': data['summary'] ?? {}};
      } else {
        throw Exception('Failed to load settlements');
      }
    } catch (e) {
      debugPrint('Error fetching settlements: $e');
      rethrow;
    }
  }

  static Future<bool> recordSettlementPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await _post('$baseUrl/crm/settlements', paymentData);

      debugPrint('Record Payment - Status: ${response.statusCode}');
      debugPrint('Record Payment - Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to record payment');
      }
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  // ─── Vendor Reports ────────────────────────────────────────────────────────

  /// Fetches all appointments report from
  /// GET /api/crm/vendor/reports/all-appointments
  ///
  /// Optional filters (passed as query params):
  ///   [period]      – e.g. 'all', 'today', 'week', 'month', 'custom'
  ///   [startDate]   – ISO-8601 date string for custom range start
  ///   [endDate]     – ISO-8601 date string for custom range end
  ///   [client]      – client id / name filter
  ///   [service]     – service id / name filter
  ///   [staff]       – staff id / name filter
  ///   [status]      – appointment status filter
  ///   [bookingType] – 'online' | 'offline'
  static Future<Map<String, dynamic>> getAllAppointmentsReport({
    String? period,
    String? startDate,
    String? endDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/all-appointments',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load appointments report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load completed appointments report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching completed appointments report: $e');
      rethrow;
    }
  }

  /// Fetches sales by product report from
  /// GET /api/crm/vendor/reports/sales-by-product
  static Future<Map<String, dynamic>> getSalesByProductReport({
    String? period,
    String? startDate,
    String? endDate,
    String? product,
    String? category,
    String? brand,
    String? status,
    String? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (product != null) queryParams['product'] = product;
      if (category != null) queryParams['category'] = category;
      if (brand != null) queryParams['brand'] = brand;
      if (status != null) queryParams['status'] = status;
      if (isActive != null) queryParams['isActive'] = isActive;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/sales-by-product',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load sales by product report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load sales by product report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching sales by product report: $e');
      rethrow;
    }
  }

  /// Fetches completed appointments report from
  /// GET /api/crm/vendor/reports/completed-appointments
  ///
  /// Returns the full decoded response map which contains:
  ///   data.complete.total, data.complete.appointments[],
  ///   data.complete.totalRevenue, data.complete.totalDuration
  static Future<Map<String, dynamic>> getCompletedAppointmentsReport({
    String? period,
    String? startDate,
    String? endDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/completed-appointments',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load completed appointments report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load completed appointments report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching completed appointments report: $e');
      rethrow;
    }
  }

  /// Fetches cancelled appointments report from
  /// GET /api/crm/vendor/reports/cancelled-appointments
  ///
  /// Returns the full decoded response map which contains:
  ///   data.cancellations.totalCancelled, data.cancellations.cancellations[],
  ///   data.cancellations.revenueLoss
  static Future<Map<String, dynamic>> getCancelledAppointmentsReport({
    String? period,
    String? startDate,
    String? endDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/cancelled-appointments',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load cancelled appointments report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load cancelled appointments report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching cancelled appointments report: $e');
      rethrow;
    }
  }

  /// Fetches summary by service report from
  /// GET /api/crm/vendor/reports/summary-by-service
  ///
  /// Returns the full decoded response map which contains:
  ///   data.summaryByService[] (serviceName, count, totalAmount, totalDuration, averageAmount, averageDuration)
  static Future<Map<String, dynamic>> getSummaryByServiceReport({
    String? period,
    String? startDate,
    String? endDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/summary-by-service',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load summary by service report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load summary by service report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching summary by service report: $e');
      rethrow;
    }
  }

  /// Fetches settlement summary report from
  /// GET /api/crm/vendor/reports/settlement-summary
  ///
  /// Returns the full decoded response map which contains:
  ///   data.settlementSummary.appointments[]
  ///   data.settlementSummary.transfers[]
  ///   data.settlementSummary.totals{}
  static Future<Map<String, dynamic>> getSettlementSummaryReport({
    String? period,
    String? startDate,
    String? endDate,
    String? settlementFromDate,
    String? settlementToDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (settlementFromDate != null)
        queryParams['settlementFromDate'] = settlementFromDate;
      if (settlementToDate != null)
        queryParams['settlementToDate'] = settlementToDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/settlement-summary',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load settlement summary report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load settlement summary report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching settlement summary report: $e');
      rethrow;
    }
  }

  /// Fetches product summary report
  static Future<Map<String, dynamic>> getProductSummaryReport({
    String? startDate,
    String? endDate,
    String? product,
    String? category,
    String? brand,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (product != null) queryParams['product'] = product;
      if (category != null) queryParams['category'] = category;
      if (brand != null) queryParams['brand'] = brand;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/product-summary',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load product summary report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load product summary report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching product summary report: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getInventoryStockReport({
    String? startDate,
    String? endDate,
    String? product,
    String? category,
    String? brand,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (product != null) queryParams['product'] = product;
      if (category != null) queryParams['category'] = category;
      if (brand != null) queryParams['brand'] = brand;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/inventory-stock',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load inventory stock report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load inventory stock report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching inventory stock report: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCategoryWiseProductReport({
    String? startDate,
    String? endDate,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/category-wise-product',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data;
        } else {
          throw Exception(
            'Failed to load category-wise product report: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load category-wise product report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching category-wise product report: $e');
      rethrow;
    }
  }

  /// Fetches sales by customer report
  static Future<Map<String, dynamic>> getSalesByCustomerReport({
    String? period,
    String? startDate,
    String? endDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/sales-by-customer',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) return data;
        throw Exception(data['message'] ?? 'Unknown error');
      } else {
        throw Exception(
          'Failed to load sales by customer: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching sales by customer: $e');
      rethrow;
    }
  }

  /// Fetches sales by service report
  static Future<Map<String, dynamic>> getSalesByServiceReport({
    String? period,
    String? startDate,
    String? endDate,
    String? client,
    String? service,
    String? staff,
    String? status,
    String? bookingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (client != null) queryParams['client'] = client;
      if (service != null) queryParams['service'] = service;
      if (staff != null) queryParams['staff'] = staff;
      if (status != null) queryParams['status'] = status;
      if (bookingType != null) queryParams['bookingType'] = bookingType;

      final uri = Uri.parse(
        '$baseUrl/crm/vendor/reports/sales-by-service',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) return data;
        throw Exception(data['message'] ?? 'Unknown error');
      } else {
        throw Exception(
          'Failed to load sales by service: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching sales by service: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getStaffCommissionReport({
    String? startDate,
    String? endDate,
    String? staffId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (staffId != null) queryParams['staffId'] = staffId;

      final uri = Uri.parse(
        '$baseUrl/crm/reports/vendor/staff-commission',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _get(uri.toString());

      debugPrint('Staff Commission Report - Status: ${response.statusCode}');
      debugPrint('Staff Commission Report - Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['data'] is List) return decoded['data'];
        throw Exception(
          'Unexpected response format for staff commission report',
        );
      } else {
        throw Exception(
          'Failed to load staff commission report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching staff commission report: $e');
      rethrow;
    }
  }

  // === SHIPPING SETTINGS ===

  // Get shipping settings
  static Future<ShippingSettings?> getShippingSettings() async {
    try {
      final response = await _get('$baseUrl$shippingEndpoint');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ShippingSettings.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting shipping settings: $e');
      return null;
    }
  }

  // Create shipping settings
  static Future<bool> createShippingSettings(ShippingSettings settings) async {
    try {
      final response = await _post(
        '$baseUrl$shippingEndpoint',
        settings.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating shipping settings: $e');
      return false;
    }
  }

  // Update shipping settings
  static Future<bool> updateShippingSettings(ShippingSettings settings) async {
    try {
      final response = await _put(
        '$baseUrl$shippingEndpoint',
        settings.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating shipping settings: $e');
      return false;
    }
  }
}

class Service {
  String? id;
  String? name;
  String? category;
  String? categoryId; // Added to store category ID
  int? price;
  int? discountedPrice;
  int? duration;
  String? gender;
  int? bookingInterval;
  bool? commission;
  bool? homeService;
  bool? eventService;
  bool? isActive;
  String? status;
  bool? onlineBooking;
  dynamic tax;
  String? createdAt;
  String? updatedAt;
  int? prepTime;
  int? setupCleanupTime;
  String? description;
  String? image;
  List<dynamic>? staff; // Added staff field
  double? homeServiceCharges; // Added
  double? weddingServiceCharges; // Added
  List<String>? addOns; // Added: list of AddOn IDs mapped to this service

  Service({
    this.id,
    this.name,
    this.category,
    this.categoryId,
    this.price,
    this.discountedPrice,
    this.duration,
    this.gender,
    this.bookingInterval,
    this.commission,
    this.prepTime,
    this.setupCleanupTime,
    this.description,
    this.image,
    this.homeService,
    this.eventService,
    this.isActive,
    this.status,
    this.onlineBooking,
    this.tax,
    this.createdAt,
    this.updatedAt,
    this.staff, // Added staff
    this.homeServiceCharges, // Added
    this.weddingServiceCharges, // Added
    this.addOns, // Added
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'],
      name: json['name'],
      category: json['category'] is Map
          ? (json['category']['name'] ?? json['categoryName'])
          : json['categoryName'] ?? json['category'] ?? 'Uncategorized',
      categoryId: json['category'] is Map
          ? json['category']['_id']
          : (json['category'] is String ? json['category'] : null),
      price: (json['price'] as num?)?.toInt(),
      discountedPrice: (json['discountedPrice'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      gender: json['gender'] ?? 'unisex',
      bookingInterval: (json['bookingInterval'] as num?)?.toInt(),
      commission: json['commission'] ?? false,
      prepTime: json['prepTime']?.toInt(),
      setupCleanupTime: json['setupCleanupTime']?.toInt(),
      description: json['description'],
      image: json['image'],

      // === FIXED: Handle both {available: true} and plain true/false ===
      homeService: () {
        final hs = json['homeService'];
        if (hs is Map<String, dynamic>) {
          return hs['available'] as bool? ?? false;
        }
        return hs as bool? ?? false;
      }(),
      homeServiceCharges: (json['homeService'] is Map)
          ? (json['homeService']['charges'] as num?)?.toDouble()
          : null,

      eventService: () {
        final ws = json['weddingService'] ?? json['eventService'];
        if (ws is Map<String, dynamic>) {
          return ws['available'] as bool? ?? false;
        }
        return ws as bool? ?? false;
      }(),
      weddingServiceCharges: (json['weddingService'] is Map)
          ? (json['weddingService']['charges'] as num?)?.toDouble()
          : (json['eventService'] is Map
                ? (json['eventService']['charges'] as num?)?.toDouble()
                : null),

      // === END FIX ===
      isActive: json['status'] == 'approved',
      status: json['status'],
      onlineBooking: json['onlineBooking'] ?? false,
      tax: json['tax'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      staff: json['staff'] is List
          ? (json['staff'] as List).map((s) {
              if (s is Map)
                return s['_id']?.toString() ?? s['fullName']?.toString() ?? '';
              return s.toString();
            }).toList()
          : null,
      addOns: json['addOns'] is List
          ? (json['addOns'] as List).map((a) {
              if (a is Map) return a['_id']?.toString() ?? '';
              return a.toString();
            }).toList()
          : (json['addons'] is List
                ? (json['addons'] as List).map((a) => a.toString()).toList()
                : (json['mappedAddons'] is List
                      ? (json['mappedAddons'] as List)
                            .map((a) => a.toString())
                            .toList()
                      : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'discountedPrice': discountedPrice,
      'duration': duration,
      'gender': gender,
      'bookingInterval': bookingInterval,
      'commission': commission,
      'prepTime': prepTime,
      'setupCleanupTime': setupCleanupTime,
      'description': description,
      'image': image,
      'weddingService': {
        'available': eventService,
        'charges': weddingServiceCharges,
      },
      'homeService': {'available': homeService, 'charges': homeServiceCharges},
      'status': status,
      'onlineBooking': onlineBooking,
      'tax': tax,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'staff': staff, // Include staff
      'addOns': addOns, // Include addons
    };
  }
}

// Product model class
class Product {
  String? id;
  String? vendorId;
  String? productName;
  String? description;
  String? category;
  String? categoryDescription;
  int? price;
  int? salePrice;
  int? stock;
  List<String>? productImages;
  String? size;
  String? sizeMetric;
  List<String>? keyIngredients;
  String? forBodyPart;
  String? bodyPartType;
  String? productForm;
  String? brand;
  bool? isActive;
  String? status;
  String? origin;
  String? createdBy;
  String? updatedBy;
  String? createdAt;
  String? updatedAt;
  int? v;

  Product({
    this.id,
    this.vendorId,
    this.productName,
    this.description,
    this.category,
    this.categoryDescription,
    this.price,
    this.salePrice,
    this.stock,
    this.productImages,
    this.size,
    this.sizeMetric,
    this.keyIngredients,
    this.forBodyPart,
    this.bodyPartType,
    this.productForm,
    this.brand,
    this.isActive,
    this.status,
    this.origin,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      vendorId: (json['vendorId'] is Map)
          ? json['vendorId']['_id']
          : (json['vendorId']?.toString()),
      productName: json['productName'] ?? json['name'],
      description: json['description'],
      category: json['category'] is Map
          ? (json['category']['name'] ?? json['categoryName'])
          : json['categoryName'] ?? json['category'] ?? 'Uncategorized',
      categoryDescription: json['categoryDescription'],
      price: (json['price'] as num?)?.toInt(),
      salePrice: (json['salePrice'] as num?)?.toInt(),
      stock: (json['stock'] as num?)?.toInt(),
      productImages: (json['productImages'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      size: json['size'],
      sizeMetric: json['sizeMetric'],
      keyIngredients: (json['keyIngredients'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      forBodyPart: json['forBodyPart'],
      bodyPartType: json['bodyPartType'],
      productForm: json['productForm'],
      brand: json['brand'],
      isActive: json['isActive'],
      status: json['status'],
      origin: json['origin'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vendorId': vendorId,
      'productName': productName,
      'description': description,
      'category': category,
      'categoryDescription': categoryDescription,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'productImages': productImages,
      'size': size,
      'sizeMetric': sizeMetric,
      'keyIngredients': keyIngredients,
      'forBodyPart': forBodyPart,
      'bodyPartType': bodyPartType,
      'productForm': productForm,
      'brand': brand,
      'isActive': isActive,
      'status': status,
      'origin': origin,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

class WeddingPackage {
  final String? id;
  final String? name;
  final String? description;
  final List<dynamic>? services;
  final double? totalPrice;
  final double? discountedPrice;
  final int? duration;
  final int? staffCount;
  final List<dynamic>? assignedStaff;
  final String? image;
  final String? status;
  final bool? isActive;

  WeddingPackage({
    this.id,
    this.name,
    this.description,
    this.services,
    this.totalPrice,
    this.discountedPrice,
    this.duration,
    this.staffCount,
    this.assignedStaff,
    this.image,
    this.status,
    this.isActive,
  });

  factory WeddingPackage.fromJson(Map<String, dynamic> json) {
    return WeddingPackage(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      services: json['services'] is List ? json['services'] : null,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
      staffCount: (json['staffCount'] as num?)?.toInt(),
      assignedStaff: json['assignedStaff'] is List
          ? json['assignedStaff']
          : null,
      image: json['image'],
      status: json['status'],
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }
}

class OfferModel {
  final String? id;
  final String? code;
  final String? type;
  final num? value;
  final String? status;
  final DateTime? startDate;
  final DateTime? expires;
  final int? redeemed;
  final num? totalDiscount;
  final List<dynamic>? applicableSpecialties;
  final List<dynamic>? applicableCategories;
  final List<dynamic>? applicableServices;
  final List<dynamic>? applicableServiceCategories;
  final String? offerImage;
  final bool? isCustomCode;
  final num? minOrderAmount;
  final String? businessType;
  final String? businessId;
  final String? regionId;

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  OfferModel({
    this.id,
    this.code,
    this.type,
    this.value,
    this.status,
    this.startDate,
    this.expires,
    this.redeemed,
    this.totalDiscount,
    this.applicableSpecialties,
    this.applicableCategories,
    this.applicableServices,
    this.applicableServiceCategories,
    this.offerImage,
    this.isCustomCode,
    this.minOrderAmount,
    this.businessType,
    this.businessId,
    this.regionId,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['_id'],
      code: json['code'],
      type: json['type'],
      value: json['value'],
      status: json['status'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      expires: json['expires'] != null ? DateTime.parse(json['expires']) : null,
      redeemed: json['redeemed'],
      totalDiscount: json['totalDiscount'],
      applicableSpecialties: json['applicableSpecialties'],
      applicableCategories: json['applicableCategories'],
      applicableServices: json['applicableServices'],
      applicableServiceCategories: json['applicableServiceCategories'],
      offerImage: json['offerImage'],
      isCustomCode: _parseBool(json['isCustomCode']),
      minOrderAmount: json['minOrderAmount'],
      businessType: json['businessType'],
      businessId: json['businessId'],
      regionId: json['regionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'type': type,
      'value': value,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'expires': expires?.toIso8601String(),
      'redeemed': redeemed,
      'applicableSpecialties': applicableSpecialties,
      'applicableCategories': applicableCategories,
      'applicableServices': applicableServices,
      'applicableServiceCategories': applicableServiceCategories,
      'offerImage': offerImage,
      'isCustomCode': isCustomCode,
      'minOrderAmount': minOrderAmount,
      'businessType': businessType,
      'businessId': businessId,
      'regionId': regionId,
    };
  }
}

class InventoryTransaction {
  final String id;
  final TransactionProduct productId;
  final String? vendorId;
  final TransactionCategory? category;
  final String type; // IN or OUT
  final int quantity;
  final int previousStock;
  final int newStock;
  final String reason;
  final String? reference;
  final String? performedBy;
  final DateTime date;

  InventoryTransaction({
    required this.id,
    required this.productId,
    this.vendorId,
    this.category,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    this.reference,
    this.performedBy,
    required this.date,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['_id'] ?? '',
      productId: TransactionProduct.fromJson(json['productId'] ?? {}),
      vendorId: json['vendorId'],
      category: json['productCategory'] != null
          ? TransactionCategory.fromJson(json['productCategory'])
          : null,
      type: json['type'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      reason: json['reason'] ?? '',
      reference: json['reference'],
      performedBy: json['performedBy'],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }
}

class TransactionProduct {
  final String id;
  final String productName;
  final List<String> productImages;

  TransactionProduct({
    required this.id,
    required this.productName,
    required this.productImages,
  });

  factory TransactionProduct.fromJson(Map<String, dynamic> json) {
    return TransactionProduct(
      id: json['_id'] ?? '',
      productName: json['productName'] ?? '',
      productImages:
          (json['productImages'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}

class TransactionCategory {
  final String id;
  final String name;

  TransactionCategory({required this.id, required this.name});

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}
