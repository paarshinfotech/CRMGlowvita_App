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
  static const String staffEndpoint = '/crm/staff'; // Add staff endpoint

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

    // Only show warning if we expect the token to exist
    if (token.isEmpty) {
      print('Warning: No authentication token found. API calls may fail.');
    }

    return token;
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
      throw Exception('Error fetching clients: $e');
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
      throw Exception('Error fetching staff: $e');
    }
  }

  // Add a new client
  static Future<Customer> addClient(Customer customer) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          "Cookie": "crm_access_token=$token",
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
      throw Exception('Error adding client: $e');
    }
  }

  // Update an existing client
  static Future<Customer> updateClient(Customer customer) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      if (customer.id == null) {
        throw Exception('Customer ID is required for update');
      }

      final response = await http.put(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          "Cookie": "crm_access_token=$token",
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
      throw Exception('Error updating client: $e');
    }
  }

  // Delete a client
  static Future<bool> deleteClient(String clientId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl$clientsEndpoint'),
        headers: {
          'Cookie': 'crm_access_token=$token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': clientId,
        }),
      );

      if ([200, 201, 204].contains(response.statusCode)) {
        final data = json.decode(response.body);
        // Check if the response has a success field, otherwise assume success for 204
        bool success = response.statusCode == 204 ? true : (data['success'] == true);
        return success;
      } else {
        throw Exception('Failed to delete client: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting client: $e');
      print('Error details: ${e.runtimeType}');
      throw Exception('Error deleting client: $e');
    }
  }
}