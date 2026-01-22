class AddOn {
  final String? id;
  final String? name;
  final double? price;
  final int? duration; // in minutes
  final List<String>? mappedServices; // List of Service IDs
  final String? status;

  AddOn({
    this.id,
    this.name,
    this.price,
    this.duration,
    this.mappedServices,
    this.status,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) {
    return AddOn(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      price: (json['price'] as num?)?.toDouble(),
      duration: json['duration'],
      mappedServices: json['services'] != null
          ? List<String>.from(json['services'])
          : (json['mappedServices'] != null
              ? List<String>.from(json['mappedServices'])
              : []),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'services': mappedServices,
      'status': status,
    };
  }
}
