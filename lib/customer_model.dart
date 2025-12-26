import 'package:intl/intl.dart';

class Customer {
  final String? id;
  final String? vendorId;
  final String fullName;
  final String mobile;
  final String? email;
  final String? dateOfBirth;
  final String? gender;
  final String? country;
  final String? occupation;
  final String? address;
  final String? note;
  final String? imagePath;
  final String? lastVisit;
  final int totalBookings;
  final double totalSpent;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOnline;
  final String? source;

  Customer({
    this.id,
    this.vendorId,
    required this.fullName,
    required this.mobile,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.country,
    this.occupation,
    this.address,
    this.note,
    this.imagePath,
    this.lastVisit,
    this.totalBookings = 0,
    this.totalSpent = 0.0,
    this.status = 'Active',
    this.createdAt,
    this.updatedAt,
    this.isOnline = false,
    this.source = 'offline',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Customer(
      id: json['_id'],
      vendorId: json['vendorId'],
      fullName: json['fullName'] ?? '',
      mobile: json['phone'] ?? '',
      email: json['email'],
      dateOfBirth: json['birthdayDate'] != null 
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(json['birthdayDate'].toString().split('T')[0])) 
          : null,
      gender: json['gender'],
      country: json['country'],
      occupation: json['occupation'],
      address: json['address'],
      note: json['note'],
      imagePath: json['profilePicture'],
      lastVisit: json['lastVisit'] != null 
          ? dateFormat.format(DateTime.parse(json['lastVisit'])) 
          : null,
      totalBookings: json['totalBookings']?.toInt() ?? 0,
      totalSpent: (json['totalSpent']?.toDouble()) ?? 0.0,
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isOnline: json['source'] == 'online', 
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    String? birthDateIso;
    if (dateOfBirth != null) {
      // Parse the dd/MM/yyyy format and convert to yyyy-MM-dd
      final dt = DateFormat('dd/MM/yyyy').parse(dateOfBirth!);
      birthDateIso = DateFormat('yyyy-MM-dd').format(dt);
    }

    String? lastVisitIso;
    if (lastVisit != null) {
      final dt = DateFormat('dd/MM/yyyy').parse(lastVisit!);
      lastVisitIso = dt.toUtc().toIso8601String();
    }

    return {
      '_id': id,
      'vendorId': vendorId,
      'fullName': fullName,
      'phone': mobile,
      'email': email,
      'birthdayDate': birthDateIso,
      'gender': gender,
      'country': country,
      'occupation': occupation,
      'address': address,
      'note': note,
      'profilePicture': imagePath,
      'lastVisit': lastVisitIso,
      'totalBookings': totalBookings,
      'totalSpent': totalSpent,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'source': source,
    };
  }
}