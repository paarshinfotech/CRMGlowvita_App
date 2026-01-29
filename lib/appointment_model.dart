class AppointmentModel {
  final String? id;
  final String? vendorId;
  final String? staffName;
  final String? serviceName;
  final DateTime? date;
  final String? clientName;
  final String? startTime;
  final String? endTime;
  final int? duration;
  final double? amount;
  final String? paymentMethod;
  final String? status;
  final bool? isMultiService;
  final bool? isHomeService;
  final bool? isWeddingService;
  final String? mode;
  final AppointmentClient? client;
  final AppointmentStaff? staff;

  // New fields
  final String? notes;
  final double? amountRemaining;
  final double? discount;
  final double? totalAmount;
  final double? finalAmount;
  final double? amountPaid;
  final List<PaymentRecord>? paymentHistory;
  final List<ServiceItem>? serviceItems;
  final WeddingPackageDetails? weddingPackageDetails;
  final HomeServiceLocation? homeServiceLocation;

  AppointmentModel({
    this.id,
    this.vendorId,
    this.staffName,
    this.serviceName,
    this.date,
    this.clientName,
    this.startTime,
    this.endTime,
    this.duration,
    this.amount,
    this.paymentMethod,
    this.status,
    this.isMultiService,
    this.isHomeService,
    this.isWeddingService,
    this.mode,
    this.client,
    this.staff,
    this.notes,
    this.amountRemaining,
    this.discount,
    this.totalAmount,
    this.finalAmount,
    this.amountPaid,
    this.paymentHistory,
    this.serviceItems,
    this.weddingPackageDetails,
    this.homeServiceLocation,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'],
      vendorId: json['vendorId'],
      staffName: json['staffName'],
      serviceName: json['serviceName'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      clientName: json['clientName'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      duration: (json['duration'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
      status: json['status'],
      isMultiService: json['isMultiService'] ?? false,
      isHomeService: json['isHomeService'] ?? false,
      isWeddingService: json['isWeddingService'] ?? false,
      mode: json['mode'],
      client: json['client'] is Map<String, dynamic>
          ? AppointmentClient.fromJson(json['client'])
          : null,
      staff: json['staff'] is Map<String, dynamic>
          ? AppointmentStaff.fromJson(json['staff'])
          : null,
      notes: json['notes'],
      amountRemaining: (json['amountRemaining'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      finalAmount: (json['finalAmount'] as num?)?.toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paymentHistory: (json['paymentHistory'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => PaymentRecord.fromJson(e))
          .toList(),
      serviceItems: (json['serviceItems'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => ServiceItem.fromJson(e))
          .toList(),
      weddingPackageDetails:
          json['weddingPackageDetails'] is Map<String, dynamic>
              ? WeddingPackageDetails.fromJson(json['weddingPackageDetails'])
              : null,
      homeServiceLocation: json['homeServiceLocation'] is Map<String, dynamic>
          ? HomeServiceLocation.fromJson(json['homeServiceLocation'])
          : null,
    );
  }
}

class AppointmentClient {
  final String? id;
  final String? email;
  final String? phone;

  AppointmentClient({this.id, this.email, this.phone});

  factory AppointmentClient.fromJson(Map<String, dynamic> json) {
    return AppointmentClient(
      id: json['_id'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class AppointmentStaff {
  final String? id;
  final String? fullName;
  final String? position;

  AppointmentStaff({this.id, this.fullName, this.position});

  factory AppointmentStaff.fromJson(Map<String, dynamic> json) {
    return AppointmentStaff(
      id: json['_id'],
      fullName: json['fullName'],
      position: json['position'],
    );
  }
}

class PaymentRecord {
  final double? amount;
  final String? paymentMethod;
  final String? paymentDate;
  final String? notes;

  PaymentRecord({
    this.amount,
    this.paymentMethod,
    this.paymentDate,
    this.notes,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      amount: (json['amount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentDate: json['paymentDate'],
      notes: json['notes'],
    );
  }
}

class ServiceItem {
  final String? serviceName;
  final String? staffName;
  final String? startTime;
  final String? endTime;
  final int? duration;
  final double? amount;

  ServiceItem({
    this.serviceName,
    this.staffName,
    this.startTime,
    this.endTime,
    this.duration,
    this.amount,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceName: json['serviceName'],
      staffName: json['staffName'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      duration: (json['duration'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class WeddingPackageDetails {
  final String? packageName;
  final List<PackageService>? packageServices;

  WeddingPackageDetails({this.packageName, this.packageServices});

  factory WeddingPackageDetails.fromJson(Map<String, dynamic> json) {
    return WeddingPackageDetails(
      packageName: json['packageName'],
      packageServices: (json['packageServices'] as List?)
          ?.map((e) => PackageService.fromJson(e))
          .toList(),
    );
  }
}

class PackageService {
  final String? serviceName;

  PackageService({this.serviceName});

  factory PackageService.fromJson(Map<String, dynamic> json) {
    return PackageService(
      serviceName: json['serviceName'],
    );
  }
}

class HomeServiceLocation {
  final String? address;

  HomeServiceLocation({this.address});

  factory HomeServiceLocation.fromJson(Map<String, dynamic> json) {
    return HomeServiceLocation(
      address: json['address'],
    );
  }
}
