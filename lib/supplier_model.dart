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
    String? s(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) {
        if (v.containsKey('url')) return v['url']?.toString();
        if (v.containsKey('path')) return v['path']?.toString();
        if (v.containsKey('formattedAddress')) return v['formattedAddress']?.toString();
        return v.toString();
      }
      return v.toString();
    }

    return SupplierProfile(
      id: s(json['_id']) ?? '',
      firstName: s(json['firstName']) ?? '',
      lastName: s(json['lastName']) ?? '',
      email: s(json['email']) ?? '',
      mobile: s(json['mobile']) ?? '',
      shopName: s(json['shopName']) ?? '',
      country: s(json['country']),
      state: s(json['state']),
      city: s(json['city']),
      pincode: s(json['pincode']),
      address: s(json['address']),
      businessRegistrationNo: s(json['businessRegistrationNo']),
      supplierType: s(json['supplierType']),
      licenseFiles: json['licenseFiles'] is List ? (json['licenseFiles'] as List) : [],
      smsBalance: (json['smsBalance'] as num?)?.toInt() ?? 0,
      status: s(json['status']) ?? '',
      referralCode: s(json['referralCode']) ?? '',
      description: s(json['description']) ?? '',
      gallery: json['gallery'] is List
          ? (json['gallery'] as List).map((e) => s(e) ?? '').toList()
          : (json['gallery'] != null ? [s(json['gallery']) ?? ''] : []),
      gstNo: s(json['gstNo']),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      profileImage: s(json['profileImage']) ?? '',
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
    String? s(dynamic v) => v?.toString();
    return SupplierBankDetails(
      bankName: s(json['bankName']),
      accountNumber: s(json['accountNumber']),
      ifscCode: s(json['ifscCode']),
      accountHolder: s(json['accountHolder']),
      upiId: s(json['upiId']),
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
    String? s(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) {
        if (v.containsKey('url')) return v['url']?.toString();
        if (v.containsKey('path')) return v['path']?.toString();
        return v.toString();
      }
      return v.toString();
    }

    return SupplierDocuments(
      shopAct: s(json['shopAct']),
      shopActRejectionReason: s(json['shopActRejectionReason']),
      shopActAdminRejectionReason: s(json['shopActAdminRejectionReason']),
      aadharCard: s(json['aadharCard']),
      udyogAadhar: s(json['udyogAadhar']),
      udhayamCert: s(json['udhayamCert']),
      shopLicense: s(json['shopLicense']),
      panCard: s(json['panCard']),
      aadharCardRejectionReason: s(json['aadharCardRejectionReason']),
      udyogAadharRejectionReason: s(json['udyogAadharRejectionReason']),
      udhayamCertRejectionReason: s(json['udhayamCertRejectionReason']),
      shopLicenseRejectionReason: s(json['shopLicenseRejectionReason']),
      panCardRejectionReason: s(json['panCardRejectionReason']),
      aadharCardAdminRejectionReason: s(json['aadharCardAdminRejectionReason']),
      udyogAadharAdminRejectionReason: s(json['udyogAadharAdminRejectionReason']),
      udhayamCertAdminRejectionReason: s(json['udhayamCertAdminRejectionReason']),
      shopLicenseAdminRejectionReason: s(json['shopLicenseAdminRejectionReason']),
      panCardAdminRejectionReason: s(json['panCardAdminRejectionReason']),
      aadharCardStatus: s(json['aadharCardStatus']),
      otherDocs: json['otherDocs'] is List
          ? (json['otherDocs'] as List).map((e) => s(e) ?? '').toList()
          : (json['otherDocs'] != null ? [s(json['otherDocs']) ?? ''] : []),
      panCardStatus: s(json['panCardStatus']),
      shopLicenseStatus: s(json['shopLicenseStatus']),
      udhayamCertStatus: s(json['udhayamCertStatus']),
      udyogAadharStatus: s(json['udyogAadharStatus']),
      shopActStatus: s(json['shopActStatus']),
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
    String? s(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) return v['name']?.toString() ?? v['title']?.toString() ?? v.toString();
      return v.toString();
    }
    return SupplierSubscription(
      plan: s(json['plan']),
      status: s(json['status']) ?? '',
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
    String s(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) return v['name']?.toString() ?? v['title']?.toString() ?? v.toString();
      return v.toString();
    }
    return SupplierSubscriptionHistory(
      plan: s(json['plan']),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: s(json['status']),
      id: s(json['_id']),
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
      taxType: json['taxType']?.toString() ?? 'percentage',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxValue': taxValue,
      'taxType': taxType,
    };
  }
}
