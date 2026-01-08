import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../customer_model.dart';

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
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['_id'],
      vendorId: json['vendorId'],
      fullName: json['fullName'] ?? json['name'],
      email: json['emailAddress'] ?? json['email'],
      mobile: json['mobileNo'] ?? json['mobile'],
      position: json['position'],
      photo: json['photo'],
      status: json['status'] ?? 'Active',
      permissions: json['permissions']?.cast<dynamic>() ?? [],
      availability: json['availability'] != null
          ? Map<String, dynamic>.from(json['availability'])
          : null,
      blockedTimes: json['blockedTimes']?.cast<dynamic>() ?? [],
      bankDetails: json['bankDetails'] != null
          ? Map<String, dynamic>.from(json['bankDetails'])
          : null,
      salary: json['salary'],
      yearOfExperience: json['yearOfExperience'],
      clientsServed: json['clientsServed'],
      commission: json['commission'] ?? false,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      description: json['description'],
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://partners.v2winonline.com/api';
  static const String clientsEndpoint = '/crm/clients';
  static const String staffEndpoint = '/crm/staff';
  static const String servicesEndpoint = '/crm/services';

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      print(
          'Warning: No authentication token found in SharedPreferences. API calls may fail.');
    }

    return token.isEmpty ? null : token;
  }

  // Public method to get auth token
  static Future<String?> getAuthToken() async {
    return await _getAuthToken();
  }

  // Get all clients
  static Future<List<Customer>> getClients() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> clientsData = data['data'];
          return clientsData.map((json) => Customer.fromJson(json)).toList();
        } else {
          throw Exception(
              'Failed to load clients: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load clients: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching clients: $e');
      rethrow;
    }
  }

  // Get all staff members
  static Future<List<StaffMember>> getStaff() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$staffEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> staffData = data['data'];
          return staffData.map((json) => StaffMember.fromJson(json)).toList();
        } else {
          throw Exception(
              'Failed to load staff: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load staff: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching staff: $e');
      rethrow;
    }
  }

  // Add a new client
  static Future<Customer> addClient(Customer customer) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          'Cookie': 'crm_access_token=$token',
          'Content-Type': 'application/json',
        },
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Customer.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to add client: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to add client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding client: $e');
      rethrow;
    }
  }

  // Update an existing client
  static Future<Customer> updateClient(Customer customer) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No authentication token found');
      if (customer.id == null)
        throw Exception('Customer ID is required for update');

      final response = await http.put(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          'Cookie': 'crm_access_token=$token',
          'Content-Type': 'application/json',
        },
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Customer.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to update client: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to update client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating client: $e');
      rethrow;
    }
  }

  // Delete a client
  static Future<bool> deleteClient(String clientId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          'Cookie': 'crm_access_token=$token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': clientId}),
      );

      if ([200, 201, 204].contains(response.statusCode)) {
        return true;
      } else {
        throw Exception(
            'Failed to delete client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting client: $e');
      rethrow;
    }
  }

  // ==================== GET SERVICES ==================== //
  static Future<List<Service>> getServices() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$servicesEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
      );

      print('Services API Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> servicesData = data['services'] ?? [];
        return servicesData.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load services: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching services: $e');
      rethrow;
    }
  }
  // ============================================================

  static Future<bool> deleteService(String serviceId) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl$servicesEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
        body: json.encode({'serviceId': serviceId}),
      );

      print(
          'Delete Service Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message']?.contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Failed to delete service');
        }
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized. Your session may have expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Access denied. You do not have permission to delete this service.');
      } else if (response.statusCode == 404) {
        throw Exception('Service not found. It may have already been deleted.');
      } else {
        throw Exception(
            'Server error ${response.statusCode}: ${response.body}');
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
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      // IMPORTANT: category must be the MongoDB _id (String), not the name
      final String? categoryId =
          serviceData['category_id']; // will be passed from UI
      if (categoryId == null || categoryId.isEmpty) {
        throw Exception('Category ID is required');
      }

      // Staff must be list of staff IDs (from StaffMember.id), not names
      final List<String> staffIds = (serviceData['staff_ids'] as List<dynamic>?)
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
          'discountedPrice':
              (serviceData['discounted_price'] as num).toDouble().toInt(),
        'duration': durationMinutes,
        'description': serviceData['description']?.toString().trim() ?? '',
        'gender': serviceData['gender'] ?? 'unisex',
        'staff': staffIds,
        'commission': serviceData['allow_commission'] ?? false,
        'homeService': {
          'available': serviceData['homeService']?['available'] ?? false,
          'charges': serviceData['homeService']?['charges'],
        },
        'weddingService': {
          'available': serviceData['weddingService']?['available'] ?? false,
          'charges': serviceData['weddingService']?['charges'],
        },
        'bookingInterval':
            int.tryParse(serviceData['booking_interval'] ?? '0') ?? 0,
        'tax': {
          'enabled': serviceData['tax']?['enabled'] ?? false,
          'type': serviceData['tax']?['type'],
          'value': serviceData['tax']?['value'],
        },
        'onlineBooking': serviceData['online_booking'] ?? true,
        if (serviceData['image'] != null)
          'image': serviceData['image'], // base64 data URL
      };

      final response = await http.post(
        Uri.parse('$baseUrl$servicesEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
        body: json.encode({
          'services': [mappedServiceData]
        }),
      );

      print(
          'Create Service Response [${response.statusCode}]: ${response.body}');

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
            'Unauthorized. Your session may have expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Access denied. You do not have permission to create services.');
      } else {
        throw Exception(
            'Server error ${response.statusCode}: ${response.body}');
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
      String serviceId, Map<String, dynamic> serviceData) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing. Please login again.');
      }

      // Map the field names to match API expectations
      final mappedServiceData = {
        '_id': serviceId,
        'name': serviceData['name'],
        'category': serviceData['category_id'],
        'price': (serviceData['price'] as num).toInt(),
        'discountedPrice': serviceData['discounted_price'] != null
            ? (serviceData['discounted_price'] as num).toInt()
            : null,
        'duration': _parseDuration(serviceData['duration']),
        'description': serviceData['description'] ?? '',
        'gender': serviceData['gender'] ?? 'unisex',
        'staff': serviceData['staff'] ?? [],
        'commission': serviceData['allow_commission'] ?? false,
        'homeService': {
          'available': serviceData['homeService'] != null
              ? (serviceData['homeService']['available'] ?? false)
              : false,
          'charges': (serviceData['homeService'] != null)
              ? serviceData['homeService']['charges']
              : 0,
        },
        'weddingService': {
          'available': serviceData['weddingService'] != null
              ? (serviceData['weddingService']['available'] ?? false)
              : false,
          'charges': (serviceData['weddingService'] != null)
              ? serviceData['weddingService']['charges']
              : 0,
        },
        'onlineBooking': serviceData['online_booking'] ?? true,
      };

      if (serviceData['image'] != null) {
        mappedServiceData['image'] = serviceData['image'];
      }

      final response = await http.put(
        Uri.parse('$baseUrl$servicesEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
        body: json.encode({
          'services': [mappedServiceData]
        }),
      );

      print(
          'Update Service Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message']?.contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Failed to update service');
        }
      } else if (response.statusCode == 401) {
        throw Exception(
            'Unauthorized. Your session may have expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Access denied. You do not have permission to update this service.');
      } else {
        throw Exception(
            'Server error ${response.statusCode}: ${response.body}');
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

  // End of ApiService class
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
        'charges': weddingServiceCharges
      },
      'homeService': {'available': homeService, 'charges': homeServiceCharges},
      'status': status,
      'onlineBooking': onlineBooking,
      'tax': tax,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'staff': staff, // Include staff
    };
  }
}
