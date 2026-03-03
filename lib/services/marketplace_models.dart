class MarketplaceProduct {
  final String id;
  final String vendorId;
  final String productName;
  final String description;
  final String category;
  final String categoryDescription;
  final int price;
  final int salePrice;
  final int stock;
  final List<String> productImages;
  final String size;
  final String sizeMetric;
  final List<String> keyIngredients;
  final String forBodyPart;
  final String bodyPartType;
  final String productForm;
  final String brand;
  final bool isActive;
  final String status;
  final String origin;
  final String supplierName;
  final String supplierEmail;
  final String supplierCity;
  final String supplierState;
  final String supplierCountry;

  MarketplaceProduct({
    required this.id,
    required this.vendorId,
    required this.productName,
    required this.description,
    required this.category,
    required this.categoryDescription,
    required this.price,
    required this.salePrice,
    required this.stock,
    required this.productImages,
    required this.size,
    required this.sizeMetric,
    required this.keyIngredients,
    required this.forBodyPart,
    required this.bodyPartType,
    required this.productForm,
    required this.brand,
    required this.isActive,
    required this.status,
    required this.origin,
    required this.supplierName,
    required this.supplierEmail,
    required this.supplierCity,
    required this.supplierState,
    required this.supplierCountry,
  });

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    return MarketplaceProduct(
      id: json['_id'] ?? '',
      vendorId: (json['vendorId'] is Map)
          ? json['vendorId']['_id']
          : (json['vendorId'] ?? ''),
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      categoryDescription: json['categoryDescription'] ?? '',
      price: json['price'] ?? 0,
      salePrice: json['salePrice'] ?? 0,
      stock: json['stock'] ?? 0,
      productImages:
          (json['productImages'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      size: json['size'] ?? '',
      sizeMetric: json['sizeMetric'] ?? '',
      keyIngredients: (json['keyIngredients'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      forBodyPart: json['forBodyPart'] ?? '',
      bodyPartType: json['bodyPartType'] ?? '',
      productForm: json['productForm'] ?? '',
      brand: json['brand'] ?? '',
      isActive: json['isActive'] ?? false,
      status: json['status'] ?? '',
      origin: json['origin'] ?? '',
      supplierName: json['supplierName'] ?? '',
      supplierEmail: json['supplierEmail'] ?? '',
      supplierCity: json['supplierCity'] ?? '',
      supplierState: json['supplierState'] ?? '',
      supplierCountry: json['supplierCountry'] ?? '',
    );
  }
}

class MarketplaceSupplier {
  final String id;
  final String name;
  final String email;
  final String city;
  final String state;
  final String country;
  final String businessRegistrationNo;

  MarketplaceSupplier({
    required this.id,
    required this.name,
    required this.email,
    required this.city,
    required this.state,
    required this.country,
    required this.businessRegistrationNo,
  });

  factory MarketplaceSupplier.fromJson(Map<String, dynamic> json) {
    return MarketplaceSupplier(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      businessRegistrationNo: json['businessRegistrationNo'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceSupplier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
