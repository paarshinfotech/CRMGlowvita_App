import 'dart:convert';
import 'dart:io' show HttpClient, X509Certificate;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:shared_preferences/shared_preferences.dart';
import '../customer_model.dart';
import '../appointment_model.dart';
import '../addon_model.dart';
import '../vendor_model.dart';
import '../billing_invoice_model.dart';

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
  });

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
        'sunday'
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
      vendorId: json['vendorId'],
      fullName: json['fullName'] ?? json['name'],
      email: json['emailAddress'] ?? json['email'],
      mobile: json['mobileNo'] ?? json['mobile'],
      position: json['position'],
      photo: json['photo'],
      status: json['status'] ?? 'Active',
      permissions: json['permissions']?.cast<dynamic>() ?? [],
      availability: availabilityMap,
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vendorId': vendorId,
      'fullName': fullName,
      'emailAddress': email,
      'mobileNo': mobile,
      'position': position,
      'photo': photo,
      'status': status,
      'permissions': permissions,
      'availability': availability,
      'blockedTimes': blockedTimes,
      'bankDetails': bankDetails,
      'salary': salary,
      'yearOfExperience': yearOfExperience,
      'clientsServed': clientsServed,
      'commission': commission,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'description': description,
    };
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
      'sunday'
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

class ApiService {
  static const String baseUrl = 'https://partners.v2winonline.com/api';
  static const String clientsEndpoint = '/crm/clients';
  static const String staffEndpoint = '/crm/staff';
  static const String servicesEndpoint = '/crm/services';
  static const String adminBaseUrl = 'https://admin.v2winonline.com/api';
  static const String productCategoriesEndpoint = '/admin/product-categories';

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

  // Centralized HTTP client with SSL bypass
  static http.Client _getHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return http_io.IOClient(ioClient);
  }

  // Generic POST request helper
  static Future<http.Response> _post(String url, Map<String, dynamic> body,
      {Map<String, String>? headers, bool useAuth = true}) async {
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
        }
      }

      return await client
          .post(
            Uri.parse(url),
            headers: requestHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));
    } finally {
      client.close();
    }
  }

  // Generic GET request helper
  static Future<http.Response> _get(String url,
      {Map<String, String>? headers, bool useAuth = true}) async {
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
        }
      }

      return await client
          .get(
            Uri.parse(url),
            headers: requestHeaders,
          )
          .timeout(const Duration(seconds: 30));
    } finally {
      client.close();
    }
  }

  // Generic PUT request helper
  static Future<http.Response> _put(String url, Map<String, dynamic> body,
      {Map<String, String>? headers, bool useAuth = true}) async {
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
        }
      }

      return await client
          .put(
            Uri.parse(url),
            headers: requestHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));
    } finally {
      client.close();
    }
  }

  // Generic DELETE request helper
  static Future<http.Response> _delete(String url,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      bool useAuth = true}) async {
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
        }
      }

      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(requestHeaders);
      if (body != null) {
        request.body = json.encode(body);
      }

      final streamedResponse = await client.send(request);
      return await http.Response.fromStream(streamedResponse);
    } finally {
      client.close();
    }
  }

  // Generic PATCH request helper
  static Future<http.Response> _patch(String url, Map<String, dynamic> body,
      {Map<String, String>? headers, bool useAuth = true}) async {
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
        }
      }

      return await client
          .patch(
            Uri.parse(url),
            headers: requestHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));
    } finally {
      client.close();
    }
  }

  // Login
  static Future<http.Response> login(String email, String password) async {
    return await _post(
      '$baseUrl/crm/auth/login',
      {'email': email, 'password': password},
      useAuth: false,
    );
  }

  // Vendor Register
  static Future<http.Response> registerVendor(
      Map<String, dynamic> payload) async {
    return await _post(
      '$baseUrl/crm/auth/register',
      payload,
      useAuth: false,
    );
  }

  // Supplier Register
  static Future<http.Response> registerSupplier(
      Map<String, dynamic> payload) async {
    return await _post(
      '$adminBaseUrl/admin/suppliers',
      payload,
      useAuth: false,
    );
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

  // Get online clients
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
              'Failed to load online clients: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load online clients: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching online clients: $e');
      rethrow;
    }
  }

  // Get all staff members
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
              'Failed to load products: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load products: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  // Delete a product
  static Future<bool> deleteProduct(String productId) async {
    try {
      final response =
          await _delete('$baseUrl/crm/products', body: {'id': productId});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to delete product: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to delete product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Create a new product
  static Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _post('$baseUrl/crm/products', productData);

      print(
          'Create Product Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to create product: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to create product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Update an existing product
  static Future<bool> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      final response = await _put('$baseUrl/crm/products?id=$productId', {
        ...productData,
        'id': productId,
        '_id': productId, // Include both just in case
      });

      print(
          'Update Product Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to update product: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to update product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Get all product categories
  static Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final response =
          await _get('$adminBaseUrl$productCategoriesEndpoint', useAuth: false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(
              'Failed to load categories: ${data['message'] ?? 'Unknown error'}');
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
      String name, String description) async {
    try {
      final response = await _post(
        '$adminBaseUrl$productCategoriesEndpoint',
        {
          'name': name,
          'description': description,
        },
        useAuth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(
              'Failed to add category: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to add category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding category: $e');
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
            'Failed to load staff: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching staff: $e');
      rethrow;
    }
  }

  // Create a new staff member
  static Future<http.Response> createStaff(
      Map<String, dynamic> staffData) async {
    return await _post('$baseUrl$staffEndpoint', staffData);
  }

  // Update an existing staff member
  static Future<http.Response> updateStaff(
      String staffId, Map<String, dynamic> staffData) async {
    return await _put('$baseUrl$staffEndpoint?id=$staffId', staffData);
  }

  // Delete a staff member
  static Future<http.Response> deleteStaff(String staffId) async {
    return await _delete('$baseUrl$staffEndpoint?id=$staffId');
  }

  // Add a new client
  static Future<Customer> addClient(Customer customer) async {
    try {
      final response =
          await _post('$baseUrl$clientsEndpoint', customer.toJson());

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
      if (customer.id == null)
        throw Exception('Customer ID is required for update');

      final response =
          await _put('$baseUrl$clientsEndpoint', customer.toJson());

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
      final response =
          await _delete('$baseUrl$clientsEndpoint', body: {'id': clientId});

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
            'Failed to load services: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching services: $e');
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
        return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  static Future<http.Response> createServiceCategory(
      Map<String, dynamic> data) async {
    return await _post('$baseUrl/crm/categories', data);
  }

  // ==================== SERVICES BY CATEGORY ==================== //
  static Future<List<Map<String, dynamic>>> getServicesByCategory(
      String categoryName) async {
    try {
      final response =
          await _get('$baseUrl/crm/services?category=$categoryName');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
        return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
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
      Map<String, dynamic> data) async {
    return await _post('$adminBaseUrl/admin/categories', data);
  }

  static Future<http.Response> createMasterService(
      Map<String, dynamic> data) async {
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
            'Failed to load add-ons: ${response.statusCode} - ${response.body}');
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
            'Failed to create add-on: ${response.statusCode} - ${response.body}');
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
            'Failed to update add-on: ${response.statusCode} - ${response.body}');
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
            'Failed to delete add-on: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting add-on: $e');
      rethrow;
    }
  }
  // ============================================================

  static Future<bool> deleteService(String serviceId) async {
    try {
      final response = await _delete('$baseUrl$servicesEndpoint',
          body: {'serviceId': serviceId});

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
        'homeService': serviceData['home_service'] ?? false,
        'weddingService': serviceData['wedding_service'] ?? false,
        'bookingInterval':
            int.tryParse(serviceData['booking_interval'] ?? '0') ?? 0,
        'tax': serviceData['enable_tax'] ?? false,
        'onlineBooking': serviceData['online_booking'] ?? true,
        if (serviceData['image'] != null)
          'image': serviceData['image'], // base64 data URL
        'addOns': serviceData['addOns'] ?? [],
      };

      final response = await _post('$baseUrl$servicesEndpoint', {
        'services': [mappedServiceData]
      });

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
        'homeService': serviceData['home_service'] ?? false,
        'weddingService': serviceData['wedding_service'] ?? false,
        'tax': serviceData['enable_tax'] ?? false,
        'onlineBooking': serviceData['online_booking'] ?? true,
        'addOns': serviceData['addOns'] ?? [],
      };

      if (serviceData['image'] != null) {
        mappedServiceData['image'] = serviceData['image'];
      }

      final response = await _put('$baseUrl$servicesEndpoint', {
        'services': [mappedServiceData]
      });

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

  static Future<List<AppointmentModel>> getAppointments(
      {int? page, int? limit}) async {
    try {
      String url = '$baseUrl/crm/appointments';
      Map<String, String> queryParams = {};

      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      } else {
        queryParams['limit'] =
            '100'; // Increase default limit to fetch more for calendar
      }

      if (queryParams.isNotEmpty) {
        url += '?' + Uri(queryParameters: queryParams).query;
      }

      final response = await _get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => AppointmentModel.fromJson(json))
              .toList();
        } else if (data is Map && data['data'] != null) {
          List<dynamic> appointmentsData = data['data'];
          return appointmentsData
              .whereType<Map<String, dynamic>>()
              .map((json) => AppointmentModel.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format from appointments API');
        }
      } else {
        throw Exception(
            'Failed to load appointments: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow;
    }
  }

  // Update appointment status
  static Future<Map<String, dynamic>> updateAppointmentStatus(
      String id, String status,
      {String? cancellationReason}) async {
    try {
      final Map<String, dynamic> body = {
        '_id': id,
        'status': status,
      };

      if (status == 'cancelled' && cancellationReason != null) {
        body['cancellationReason'] = cancellationReason;
      }

      print('🔄 Updating status: $status for ID: $id');

      final response = await _patch('$baseUrl/crm/appointments', body);

      print(
          '📥 Update Status Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // Returns the full response including updated appointment
      } else {
        throw Exception(
            'Failed to update status: ${response.statusCode} - ${response.body}');
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
              'Unexpected response format from appointment detail API');
        }
      } else {
        throw Exception(
            'Failed to load appointment details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching appointment details: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createAppointment(
      Map<String, dynamic> appointmentData) async {
    try {
      final response =
          await _post('$baseUrl/crm/appointments', appointmentData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to create appointment: ${response.statusCode} - ${response.body}');
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
            'Failed to delete appointment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> collectPayment(
      Map<String, dynamic> paymentData) async {
    try {
      print(
          '🔄 Collecting payment for appointment ID: ${paymentData['appointmentId']}');

      final response =
          await _post('$baseUrl/crm/payments/collect', paymentData);

      print(
          '📥 Collect Payment Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to collect payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error collecting payment: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateAppointment(
      String id, Map<String, dynamic> appointmentData) async {
    try {
      print('🔄 Updating appointment with ID: $id');

      final response =
          await _put('$baseUrl/crm/appointments/$id', appointmentData);

      print(
          '📥 Update Appointment Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to update appointment: ${response.statusCode} - ${response.body}');
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
          'Wedding Packages Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['weddingPackages'] != null) {
          List<dynamic> packagesData = data['weddingPackages'];
          return packagesData
              .map((json) => WeddingPackage.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Failed to load wedding packages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching wedding packages: $e');
      rethrow;
    }
  }

  static Future<bool> toggleWeddingPackageStatus(
      String id, bool isActive) async {
    try {
      final response = await _patch(
          '$baseUrl/crm/wedding-packages/$id', {'isActive': isActive});

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
      Map<String, dynamic> packageData) async {
    try {
      final response =
          await _post('$baseUrl/crm/wedding-packages', packageData);

      print(
          'Create Wedding Package Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['message']?.toString().contains('successfully') == true) {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Failed to create wedding package: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating wedding package: $e');
      rethrow;
    }
  }

  static Future<bool> updateWeddingPackage(
      String? id, Map<String, dynamic> packageData) async {
    try {
      if (id == null) return false;

      final response = await _put('$baseUrl/crm/wedding-packages', {
        ...packageData,
        'packageId': id,
      });

      print(
          'Update Wedding Package Response [${response.statusCode}]: ${response.body}');

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
            'Failed to update wedding package: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating wedding package: $e');
      rethrow;
    }
  }

  static Future<bool> deleteWeddingPackage(String id) async {
    try {
      final response = await _delete('$baseUrl/crm/wedding-packages',
          body: {'packageId': id});

      print(
          'Delete Wedding Package Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true ||
            data['message']?.toString().contains('successfully') == true;
      } else {
        throw Exception(
            'Failed to delete wedding package: ${response.statusCode}');
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
          return VendorProfile.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to load vendor profile: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load vendor profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching vendor profile: $e');
      rethrow;
    }
  }

  static Future<VendorProfile> updateVendorProfile(
      Map<String, dynamic> profileData) async {
    try {
      final response = await _put('$baseUrl/crm/vendor', profileData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return VendorProfile.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to update vendor profile: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to update vendor profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating vendor profile: $e');
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
            'Failed to load offers: ${response.statusCode} - ${response.body}');
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
          '📥 Create Offer Response [${response.statusCode}]: ${response.body}');
      return response;
    } catch (e) {
      print('❌ Error creating offer: $e');
      rethrow;
    }
  }

  static Future<http.Response> updateOffer(
      String id, Map<String, dynamic> data) async {
    try {
      print('🔄 Updating offer with ID: $id...');
      // Merge ID into data as requested
      final Map<String, dynamic> payload = {
        ...data,
        'id': id,
      };

      final response = await _put('$baseUrl/crm/offers', payload);
      print(
          '📥 Update Offer Response [${response.statusCode}]: ${response.body}');
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
          '📥 Delete Offer Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
            'Failed to delete offer: ${response.statusCode} - ${response.body}');
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
          '📥 Working Hours Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load working hours: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching working hours: $e');
      rethrow;
    }
  }

  static Future<bool> updateWorkingHours(
      Map<String, dynamic> workingHoursData) async {
    try {
      print('🔄 Updating working hours...');
      print('📤 Data: ${json.encode(workingHoursData)}');

      final response =
          await _put('$baseUrl/crm/workinghours', workingHoursData);

      print(
          '📥 Update Working Hours Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true ||
            data['message']?.toString().contains('successfully') == true ||
            data['message']?.toString().contains('updated') == true;
      } else {
        throw Exception(
            'Failed to update working hours: ${response.statusCode} - ${response.body}');
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
              'Failed to load invoices: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load invoices: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching invoices: $e');
      rethrow;
    }
  }

  // Create a new bill
  static Future<Map<String, dynamic>> createBilling(
      Map<String, dynamic> payload) async {
    try {
      final response = await _post('$baseUrl/crm/billing', payload);

      print(
          '📥 Create Billing Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final data = json.decode(response.body);
        throw Exception(
            'Failed to create bill: ${data['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating bill: $e');
      rethrow;
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
        'charges': weddingServiceCharges
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
      vendorId: json['vendorId'],
      productName: json['productName'],
      description: json['description'],
      category: json['category'],
      categoryDescription: json['categoryDescription'],
      price: json['price'],
      salePrice: json['salePrice'],
      stock: json['stock'],
      productImages:
          (json['productImages'] as List?)?.map((e) => e.toString()).toList(),
      size: json['size'],
      sizeMetric: json['sizeMetric'],
      keyIngredients:
          (json['keyIngredients'] as List?)?.map((e) => e.toString()).toList(),
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
      services: json['services'],
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      duration: json['duration'],
      staffCount: json['staffCount'],
      assignedStaff: json['assignedStaff'],
      image: json['image'],
      status: json['status'],
      isActive: json['isActive'],
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
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      expires: json['expires'] != null ? DateTime.parse(json['expires']) : null,
      redeemed: json['redeemed'],
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
