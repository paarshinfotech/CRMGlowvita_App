class SupplierProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String shopName;
  final String? country;
  final String? state;
  final String? city;
  final String? pincode;
  final String? address;
  final String? businessRegistrationNo;
  final String? supplierType;
  final List<dynamic> licenseFiles;
  final int smsBalance;
  final String status;
  final String referralCode;
  final String description;
  final List<String> gallery;
  final String? gstNo;
  final double minOrderValue;
  final String profileImage;
  final int currentSmsBalance;
  final SupplierBankDetails? bankDetails;
  final SupplierDocuments? documents;
  final SupplierSubscription? subscription;
  final SupplierTaxes? taxes;

  SupplierProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.shopName,
    this.country,
    this.state,
    this.city,
    this.pincode,
    this.address,
    this.businessRegistrationNo,
    this.supplierType,
    required this.licenseFiles,
    required this.smsBalance,
    required this.status,
    required this.referralCode,
    required this.description,
    required this.gallery,
    this.gstNo,
    required this.minOrderValue,
    required this.profileImage,
    required this.currentSmsBalance,
    this.bankDetails,
    this.documents,
    this.subscription,
    this.taxes,
  });

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    return SupplierProfile(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      shopName: json['shopName'] ?? '',
      country: json['country'],
      state: json['state'],
      city: json['city'],
      pincode: json['pincode'],
      address: json['address'],
      businessRegistrationNo: json['businessRegistrationNo'],
      supplierType: json['supplierType'],
      licenseFiles: json['licenseFiles'] ?? [],
      smsBalance: (json['smsBalance'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? '',
      referralCode: json['referralCode'] ?? '',
      description: json['description'] ?? '',
      gallery: List<String>.from(json['gallery'] ?? []),
      gstNo: json['gstNo'],
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      profileImage: json['profileImage'] ?? '',
      currentSmsBalance: (json['currentSmsBalance'] as num?)?.toInt() ?? 0,
      bankDetails: json['bankDetails'] != null
          ? SupplierBankDetails.fromJson(json['bankDetails'])
          : null,
      documents: json['documents'] != null
          ? SupplierDocuments.fromJson(json['documents'])
          : null,
      subscription: json['subscription'] != null
          ? SupplierSubscription.fromJson(json['subscription'])
          : null,
      taxes: json['taxes'] != null ? SupplierTaxes.fromJson(json['taxes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'shopName': shopName,
      'country': country,
      'state': state,
      'city': city,
      'pincode': pincode,
      'address': address,
      'businessRegistrationNo': businessRegistrationNo,
      'supplierType': supplierType,
      'licenseFiles': licenseFiles,
      'smsBalance': smsBalance,
      'status': status,
      'referralCode': referralCode,
      'description': description,
      'gallery': gallery,
      'gstNo': gstNo,
      'minOrderValue': minOrderValue,
      'profileImage': profileImage,
      'currentSmsBalance': currentSmsBalance,
      'bankDetails': bankDetails?.toJson(),
      'documents': documents?.toJson(),
      'subscription': subscription?.toJson(),
      'taxes': taxes?.toJson(),
    };
  }
}

class SupplierBankDetails {
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolder;
  final String? upiId;

  SupplierBankDetails({
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolder,
    this.upiId,
  });

  factory SupplierBankDetails.fromJson(Map<String, dynamic> json) {
    return SupplierBankDetails(
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      ifscCode: json['ifscCode'],
      accountHolder: json['accountHolder'],
      upiId: json['upiId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolder': accountHolder,
      'upiId': upiId,
    };
  }
}

class SupplierDocuments {
  String? shopAct;
  String? shopActRejectionReason;
  String? shopActAdminRejectionReason;
  String? aadharCard;
  String? udyogAadhar;
  String? udhayamCert;
  String? shopLicense;
  String? panCard;
  String? aadharCardRejectionReason;
  String? udyogAadharRejectionReason;
  String? udhayamCertRejectionReason;
  String? shopLicenseRejectionReason;
  String? panCardRejectionReason;
  String? aadharCardAdminRejectionReason;
  String? udyogAadharAdminRejectionReason;
  String? udhayamCertAdminRejectionReason;
  String? shopLicenseAdminRejectionReason;
  String? panCardAdminRejectionReason;
  String? aadharCardStatus;
  List<String> otherDocs;
  String? panCardStatus;
  String? shopLicenseStatus;
  String? udhayamCertStatus;
  String? udyogAadharStatus;
  String? shopActStatus;

  SupplierDocuments({
    this.shopAct,
    this.shopActRejectionReason,
    this.shopActAdminRejectionReason,
    this.aadharCard,
    this.udyogAadhar,
    this.udhayamCert,
    this.shopLicense,
    this.panCard,
    this.aadharCardRejectionReason,
    this.udyogAadharRejectionReason,
    this.udhayamCertRejectionReason,
    this.shopLicenseRejectionReason,
    this.panCardRejectionReason,
    this.aadharCardAdminRejectionReason,
    this.udyogAadharAdminRejectionReason,
    this.udhayamCertAdminRejectionReason,
    this.shopLicenseAdminRejectionReason,
    this.panCardAdminRejectionReason,
    this.aadharCardStatus,
    required this.otherDocs,
    this.panCardStatus,
    this.shopLicenseStatus,
    this.udhayamCertStatus,
    this.udyogAadharStatus,
    this.shopActStatus,
  });

  factory SupplierDocuments.fromJson(Map<String, dynamic> json) {
    return SupplierDocuments(
      shopAct: json['shopAct'],
      shopActRejectionReason: json['shopActRejectionReason'],
      shopActAdminRejectionReason: json['shopActAdminRejectionReason'],
      aadharCard: json['aadharCard'],
      udyogAadhar: json['udyogAadhar'],
      udhayamCert: json['udhayamCert'],
      shopLicense: json['shopLicense'],
      panCard: json['panCard'],
      aadharCardRejectionReason: json['aadharCardRejectionReason'],
      udyogAadharRejectionReason: json['udyogAadharRejectionReason'],
      udhayamCertRejectionReason: json['udhayamCertRejectionReason'],
      shopLicenseRejectionReason: json['shopLicenseRejectionReason'],
      panCardRejectionReason: json['panCardRejectionReason'],
      aadharCardAdminRejectionReason: json['aadharCardAdminRejectionReason'],
      udyogAadharAdminRejectionReason: json['udyogAadharAdminRejectionReason'],
      udhayamCertAdminRejectionReason: json['udhayamCertAdminRejectionReason'],
      shopLicenseAdminRejectionReason: json['shopLicenseAdminRejectionReason'],
      panCardAdminRejectionReason: json['panCardAdminRejectionReason'],
      aadharCardStatus: json['aadharCardStatus'],
      otherDocs: List<String>.from(json['otherDocs'] ?? []),
      panCardStatus: json['panCardStatus'],
      shopLicenseStatus: json['shopLicenseStatus'],
      udhayamCertStatus: json['udhayamCertStatus'],
      udyogAadharStatus: json['udyogAadharStatus'],
      shopActStatus: json['shopActStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopAct': shopAct,
      'aadharCard': aadharCard,
      'udyogAadhar': udyogAadhar,
      'udhayamCert': udhayamCert,
      'shopLicense': shopLicense,
      'panCard': panCard,
      'otherDocs': otherDocs,
      'aadharCardStatus': aadharCardStatus,
      'panCardStatus': panCardStatus,
      'shopLicenseStatus': shopLicenseStatus,
      'udhayamCertStatus': udhayamCertStatus,
      'udyogAadharStatus': udyogAadharStatus,
      'shopActStatus': shopActStatus,
    };
  }
}

class SupplierSubscription {
  final String? plan;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SupplierSubscriptionHistory> history;

  SupplierSubscription({
    this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    required this.history,
  });

  factory SupplierSubscription.fromJson(Map<String, dynamic> json) {
    return SupplierSubscription(
      plan: json['plan'],
      status: json['status'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      history: (json['history'] as List? ?? [])
          .map((i) => SupplierSubscriptionHistory.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }
}

class SupplierSubscriptionHistory {
  final String plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String id;

  SupplierSubscriptionHistory({
    required this.plan,
    this.startDate,
    this.endDate,
    required this.status,
    required this.id,
  });

  factory SupplierSubscriptionHistory.fromJson(Map<String, dynamic> json) {
    return SupplierSubscriptionHistory(
      plan: json['plan'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      '_id': id,
    };
  }
}

class SupplierTaxes {
  final double taxValue;
  final String taxType;

  SupplierTaxes({required this.taxValue, required this.taxType});

  factory SupplierTaxes.fromJson(Map<String, dynamic> json) {
    return SupplierTaxes(
      taxValue: (json['taxValue'] as num?)?.toDouble() ?? 0.0,
      taxType: json['taxType'] ?? 'percentage',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxValue': taxValue,
      'taxType': taxType,
    };
  }
}
