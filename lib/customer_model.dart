
class Customer {
  final String? id;
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
  final DateTime createdAt;
  final bool isOnline;

  Customer({
    this.id,
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
    DateTime? createdAt,
    this.isOnline = false,
  }) : createdAt = createdAt ?? DateTime.now();
}