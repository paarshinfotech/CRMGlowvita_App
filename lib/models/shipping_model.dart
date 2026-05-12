class ShippingSettings {
  final String? id;
  final String? vendorId;
  final String chargeType;
  final double amount;
  final bool isEnabled;
  final DateTime? updatedAt;

  ShippingSettings({
    this.id,
    this.vendorId,
    required this.chargeType,
    required this.amount,
    required this.isEnabled,
    this.updatedAt,
  });

  factory ShippingSettings.fromJson(Map<String, dynamic> json) {
    return ShippingSettings(
      id: json['_id'],
      vendorId: json['vendorId'],
      chargeType: json['chargeType'] ?? 'fixed',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isEnabled: json['isEnabled'] ?? false,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chargeType': chargeType,
      'amount': amount,
      'isEnabled': isEnabled,
    };
  }
}
