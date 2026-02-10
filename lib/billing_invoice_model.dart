import 'dart:convert';

class BillingInvoiceResponse {
  final bool success;
  final List<BillingInvoice> data;
  final Pagination? pagination;

  BillingInvoiceResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory BillingInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return BillingInvoiceResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List?)
              ?.map((invoice) => BillingInvoice.fromJson(invoice))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class BillingInvoice {
  final String id;
  final ClientInfo clientInfo;
  final String vendorId;
  final String invoiceNumber;
  final String clientId;
  final List<BillingItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double platformFee;
  final double totalAmount;
  final double balance;
  final String paymentMethod;
  final String paymentStatus;
  final String billingType;
  final DateTime createdAt;
  final DateTime updatedAt;

  BillingInvoice({
    required this.id,
    required this.clientInfo,
    required this.vendorId,
    required this.invoiceNumber,
    required this.clientId,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.platformFee,
    required this.totalAmount,
    required this.balance,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.billingType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillingInvoice.fromJson(Map<String, dynamic> json) {
    return BillingInvoice(
      id: json['_id'] ?? '',
      clientInfo: ClientInfo.fromJson(json['clientInfo'] ?? {}),
      vendorId: json['vendorId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      clientId: json['clientId'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => BillingItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      billingType: json['billingType'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class ClientInfo {
  final String fullName;
  final String email;
  final String phone;
  final String profilePicture;
  final String address;

  ClientInfo({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.profilePicture,
    required this.address,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class BillingItem {
  final String itemId;
  final String itemType;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final double totalPrice;
  final int duration;
  final List<AddOnItem> addOns;
  final double discount;
  final String discountType;

  BillingItem({
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.totalPrice,
    required this.duration,
    required this.addOns,
    required this.discount,
    required this.discountType,
  });

  factory BillingItem.fromJson(Map<String, dynamic> json) {
    return BillingItem(
      itemId: json['itemId'] ?? '',
      itemType: json['itemType'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 0,
      addOns: (json['addOns'] as List?)
              ?.map((addOn) => AddOnItem.fromJson(addOn))
              .toList() ??
          [],
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType'] ?? 'flat',
    );
  }
}

class AddOnItem {
  final String id;
  final String name;
  final double price;
  final int duration;

  AddOnItem({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  factory AddOnItem.fromJson(Map<String, dynamic> json) {
    return AddOnItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] ?? 0,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
