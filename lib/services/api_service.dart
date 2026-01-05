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
      availability: json['availability'] != null ? Map<String, dynamic>.from(json['availability']) : null,
      blockedTimes: json['blockedTimes']?.cast<dynamic>() ?? [],
      bankDetails: json['bankDetails'] != null ? Map<String, dynamic>.from(json['bankDetails']) : null,
      salary: json['salary'],
      yearOfExperience: json['yearOfExperience'],
      clientsServed: json['clientsServed'],
      commission: json['commission'] ?? false,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      description: json['description'],
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://partners.v2winonline.com/api';
  static const String clientsEndpoint = '/crm/clients';
  static const String staffEndpoint = '/crm/staff';
  static const String servicesEndpoint = '/crm/services'; // Confirmed correct from your test data

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      print('Warning: No authentication token found in SharedPreferences. API calls may fail.');
    }

    return token.isEmpty ? null : token;
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
          throw Exception('Failed to load clients: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load clients: ${response.statusCode} - ${response.body}');
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
          throw Exception('Failed to load staff: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load staff: ${response.statusCode} - ${response.body}');
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
          throw Exception('Failed to add client: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to add client: ${response.statusCode} - ${response.body}');
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
      if (customer.id == null) throw Exception('Customer ID is required for update');

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
          throw Exception('Failed to update client: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to update client: ${response.statusCode} - ${response.body}');
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
        throw Exception('Failed to delete client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting client: $e');
      rethrow;
    }
  }

  // ==================== IMPROVED GET SERVICES ====================
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

      // Critical debug log — check this in console!
      print('Services API Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if services exist in the response (regardless of success field)
        if (data['services'] != null) {
          final List<dynamic> servicesList = data['services'];
          return servicesList.map((json) => Service.fromJson(json)).toList();
        } else {
          // If no services field, check for success field and message
          if (data['success'] == false) {
            final msg = data['message'] ??
                data['error'] ??
                data['msg'] ??
                'No services found';
            throw Exception(msg);
          } else {
            // If there's no services field and no explicit failure, return empty list
            return [];
          }
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Your session may have expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You do not have permission to view services.');
      } else if (response.statusCode == 404) {
        throw Exception('Services endpoint not found. Check API version or permissions.');
      } else {
        throw Exception('Server error ${response.statusCode}: ${response.body}');
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server. Please try again later.');
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Unexpected error in getServices: $e');
      rethrow;
    }
  }
  // ============================================================

  // You can add addService, updateService, deleteService later
}

class Service {
  String? id;
  String? name;
  String? category;
  int? price;
  int? discountedPrice;
  int? duration;
  int? prepTime;
  int? setupCleanupTime;
  String? description;
  String? image;
  bool? homeService;
  bool? eventService;
  bool? isActive;
  String? status;
  bool? onlineBooking;

  Service({
    this.id,
    this.name,
    this.category,
    this.price,
    this.discountedPrice,
    this.duration,
    this.prepTime,
    this.setupCleanupTime,
    this.description,
    this.image,
    this.homeService,
    this.eventService,
    this.isActive,
    this.status,
    this.onlineBooking,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'],
      name: json['name'],
      category: json['category'] is Map
          ? (json['category']['name'] ?? json['categoryName'])
          : json['categoryName'] ?? json['category'] ?? 'Uncategorized',
      price: (json['price'] as num?)?.toInt(),
      discountedPrice: (json['discountedPrice'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      prepTime: json['prepTime']?.toInt(),
      setupCleanupTime: json['setupCleanupTime']?.toInt(),
      description: json['description'],
      image: json['image'],
      homeService: json['homeService']?['available'] ?? false,
      eventService: json['weddingService']?['available'] ?? false,
      isActive: json['status'] == 'approved',
      status: json['status'],
      onlineBooking: json['onlineBooking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'price': price,
      'discountedPrice': discountedPrice,
      'duration': duration,
      'prepTime': prepTime,
      'setupCleanupTime': setupCleanupTime,
      'description': description,
      'image': image,
      'homeService': {'available': homeService},
      'weddingService': {'available': eventService},
      'status': status,
      'onlineBooking': onlineBooking,
    };
  }
}