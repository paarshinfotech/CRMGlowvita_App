import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:developer' as dev;

class RazorpayService {
  late Razorpay _razorpay;

  // Callbacks for success, failure and external wallet
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amount,
    String contact = '',
    String email = '',
    required String description,
    String businessName = 'GlowVita',
  }) {
    String razorpayKey = dotenv.env['RAZORPAY_KEY'] ?? '';

    if (razorpayKey.isEmpty) {
      dev.log("Razorpay Key is missing in .env file");
      return;
    }

    // Sanitize contact: remove all non-digit characters
    String sanitizedContact = contact.replaceAll(RegExp(r'\D'), '');
    if (sanitizedContact.length > 10) {
      sanitizedContact = sanitizedContact.substring(
        sanitizedContact.length - 10,
      );
    }

    // Sanitize Business Name and Description for UPI compatibility
    // UPI transaction notes (tn) only allow alphanumeric and spaces
    String sanitizedName = businessName.replaceAll(
      RegExp(r'[^a-zA-Z0-9 ]'),
      '',
    );

    String sanitizedDescription = description.replaceAll(
      RegExp(r'[^a-zA-Z0-9 ]'),
      '',
    );

    // Ensure they are not empty after sanitization
    if (sanitizedName.isEmpty) sanitizedName = 'GlowVita';
    if (sanitizedDescription.isEmpty)
      sanitizedDescription = 'Subscription Payment';

    // Limit description length for UPI (GPay usually caps at 80)
    if (sanitizedDescription.length > 80) {
      sanitizedDescription = sanitizedDescription.substring(0, 80);
    }

    var options = {
      'key': razorpayKey,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': sanitizedName,
      'description': sanitizedDescription,
      'currency': 'INR',
      'prefill': {'contact': sanitizedContact, 'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      dev.log("Opening Razorpay Checkout");
      dev.log("  - Name: $sanitizedName");
      dev.log("  - Description: $sanitizedDescription");
      dev.log("  - Amount (paise): ${(amount * 100).toInt()}");
      dev.log("  - Contact: $sanitizedContact");
      _razorpay.open(options);
    } catch (e) {
      dev.log("Error opening Razorpay checkout: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    dev.log("Razorpay Success: ${response.paymentId}");
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    dev.log("Razorpay Failure: ${response.code} - ${response.message}");
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    dev.log("Razorpay External Wallet: ${response.walletName}");
    onExternalWallet?.call(response);
  }

  void dispose() {
    dev.log("Disposing RazorpayService");
    _razorpay.clear();
  }
}
