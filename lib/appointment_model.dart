class AppointmentModel {
  final String id;
  final String? vendorId;
  final String? staffName;
  final String? serviceName;
  final DateTime? date;
  final String? clientName;
  final String? startTime;
  final String? endTime;
  final int? duration;
  final double? amount;
  final String? paymentStatus;
  final String? status;
  final bool? isMultiService;
  final bool? isHomeService;
  final bool? isWeddingService;
  final String? mode;
  final AppointmentClient? client;
  final AppointmentStaff? staff;

  AppointmentModel({
    required this.id,
    this.vendorId,
    this.staffName,
    this.serviceName,
    this.date,
    this.clientName,
    this.startTime,
    this.endTime,
    this.duration,
    this.amount,
    this.paymentStatus,
    this.status,
    this.isMultiService,
    this.isHomeService,
    this.isWeddingService,
    this.mode,
    this.client,
    this.staff,
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
      duration: json['duration'],
      amount: (json['amount'] as num?)?.toDouble(),
      paymentStatus: json['paymentStatus'],
      status: json['status'],
      isMultiService: json['isMultiService'],
      isHomeService: json['isHomeService'],
      isWeddingService: json['isWeddingService'],
      mode: json['mode'],
      client: json['client'] != null
          ? AppointmentClient.fromJson(json['client'])
          : null,
      staff: json['staff'] != null
          ? AppointmentStaff.fromJson(json['staff'])
          : null,
    );
  }
}

class AppointmentClient {
  final String id;
  final String? email;
  final String? phone;

  AppointmentClient({
    required this.id,
    this.email,
    this.phone,
  });

  factory AppointmentClient.fromJson(Map<String, dynamic> json) {
    return AppointmentClient(
      id: json['_id'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class AppointmentStaff {
  final String id;
  final String? fullName;
  final String? position;

  AppointmentStaff({
    required this.id,
    this.fullName,
    this.position,
  });

  factory AppointmentStaff.fromJson(Map<String, dynamic> json) {
    return AppointmentStaff(
      id: json['_id'],
      fullName: json['fullName'],
      position: json['position'],
    );
  }
}
