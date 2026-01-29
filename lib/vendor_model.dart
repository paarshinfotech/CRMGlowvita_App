class VendorProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String businessName;
  final String email;
  final String phone;
  final String state;
  final String city;
  final String pincode;
  final Location? location;
  final String address;
  final String category;
  final String regionId;
  final String vendorType;
  final int travelRadius;
  final int travelSpeed;
  final Location? baseLocation;
  final List<String> subCategories;
  final String status;
  final String website;
  final String description;
  final String profileImage;
  final List<dynamic> services;
  final Subscription? subscription;
  final List<String> gallery;
  final BankDetails? bankDetails;
  final Documents? documents;
  final String referralCode;
  final int smsBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentSmsBalance;
  final List<OpeningHour> openingHours;
  final String timezone;

  VendorProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.state,
    required this.city,
    required this.pincode,
    this.location,
    required this.address,
    required this.category,
    required this.regionId,
    required this.vendorType,
    required this.travelRadius,
    required this.travelSpeed,
    this.baseLocation,
    required this.subCategories,
    required this.status,
    required this.website,
    required this.description,
    required this.profileImage,
    required this.services,
    this.subscription,
    required this.gallery,
    this.bankDetails,
    this.documents,
    required this.referralCode,
    required this.smsBalance,
    required this.createdAt,
    required this.updatedAt,
    required this.currentSmsBalance,
    required this.openingHours,
    required this.timezone,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      businessName: json['businessName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      address: json['address'] ?? '',
      category: json['category'] ?? '',
      regionId: json['regionId'] ?? '',
      vendorType: json['vendorType'] ?? '',
      travelRadius: json['travelRadius'] ?? 0,
      travelSpeed: json['travelSpeed'] ?? 0,
      baseLocation: json['baseLocation'] != null
          ? Location.fromJson(json['baseLocation'])
          : null,
      subCategories: List<String>.from(json['subCategories'] ?? []),
      status: json['status'] ?? '',
      website: json['website'] ?? '',
      description: json['description'] ?? '',
      profileImage: json['profileImage'] ?? '',
      services: json['services'] ?? [],
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
      gallery: List<String>.from(json['gallery'] ?? []),
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
      documents: json['documents'] != null
          ? Documents.fromJson(json['documents'])
          : null,
      referralCode: json['referralCode'] ?? '',
      smsBalance: json['smsBalance'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      currentSmsBalance: json['currentSmsBalance'] ?? 0,
      openingHours: (json['openingHours'] as List? ?? [])
          .map((i) => OpeningHour.fromJson(i))
          .toList(),
      timezone: json['timezone'] ?? '',
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Subscription {
  final Plan? plan;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<History> history;

  Subscription({
    this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    required this.history,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      plan: json['plan'] != null ? Plan.fromJson(json['plan']) : null,
      status: json['status'] ?? '',
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      history: (json['history'] as List? ?? [])
          .map((i) => History.fromJson(i))
          .toList(),
    );
  }
}

class Plan {
  final String id;
  final String name;
  final int duration;
  final String durationType;
  final int price;
  final int discountedPrice;
  final bool isAvailableForPurchase;
  final String planType;
  final List<dynamic> userTypes;
  final String status;
  final List<dynamic> features;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.name,
    required this.duration,
    required this.durationType,
    required this.price,
    required this.discountedPrice,
    required this.isAvailableForPurchase,
    required this.planType,
    required this.userTypes,
    required this.status,
    required this.features,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      duration: json['duration'] ?? 0,
      durationType: json['durationType'] ?? '',
      price: json['price'] ?? 0,
      discountedPrice: json['discountedPrice'] ?? 0,
      isAvailableForPurchase: json['isAvailableForPurchase'] ?? false,
      planType: json['planType'] ?? '',
      userTypes: json['userTypes'] ?? [],
      status: json['status'] ?? '',
      features: json['features'] ?? [],
      isFeatured: json['isFeatured'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class History {
  final String plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String id;

  History({
    required this.plan,
    this.startDate,
    this.endDate,
    required this.status,
    required this.id,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      plan: json['plan'] ?? '',
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class BankDetails {
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolder;

  BankDetails({
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolder,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      ifscCode: json['ifscCode'],
      accountHolder: json['accountHolder'],
    );
  }
}

class Documents {
  final String? aadharCard;
  final String? panCard;
  final String? aadharCardStatus;
  final String? panCardStatus;

  Documents({
    this.aadharCard,
    this.panCard,
    this.aadharCardStatus,
    this.panCardStatus,
  });

  factory Documents.fromJson(Map<String, dynamic> json) {
    return Documents(
      aadharCard: json['aadharCard'],
      panCard: json['panCard'],
      aadharCardStatus: json['aadharCardStatus'],
      panCardStatus: json['panCardStatus'],
    );
  }
}

class OpeningHour {
  final String day;
  final String open;
  final String close;
  final bool isOpen;

  OpeningHour({
    required this.day,
    required this.open,
    required this.close,
    required this.isOpen,
  });

  factory OpeningHour.fromJson(Map<String, dynamic> json) {
    return OpeningHour(
      day: json['day'] ?? '',
      open: json['open'] ?? '',
      close: json['close'] ?? '',
      isOpen: json['isOpen'] ?? false,
    );
  }
}
