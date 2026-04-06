import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer' as developer;
import '../services/api_service.dart';

class SupplierRegisterPage extends StatefulWidget {
  const SupplierRegisterPage({super.key});

  @override
  State<SupplierRegisterPage> createState() => _SupplierRegisterPageState();
}

class _SupplierRegisterPageState extends State<SupplierRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int currentStep = 0;

  // Controllers - keeping exactly your current fields
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController shopNameCtrl = TextEditingController();
  final TextEditingController registrationNumberCtrl = TextEditingController();
  final TextEditingController categoryCtrl =
      TextEditingController(text: "general");
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController referralCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController pincodeCtrl = TextEditingController();
  final TextEditingController emailOtpCtrl = TextEditingController();
  final TextEditingController phoneOtpCtrl = TextEditingController();

  bool isEmailOtpSent = false;
  bool isEmailVerified = false;
  bool isPhoneOtpSent = false;
  bool isPhoneVerified = false;
  bool isSendingEmailOtp = false;
  bool isSendingPhoneOtp = false;
  bool isVerifyingEmailOtp = false;
  bool isVerifyingPhoneOtp = false;

  double? selectedLat;
  double? selectedLng;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    shopNameCtrl.dispose();
    registrationNumberCtrl.dispose();
    categoryCtrl.dispose();
    referralCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    addressCtrl.dispose();
    stateCtrl.dispose();
    cityCtrl.dispose();
    pincodeCtrl.dispose();
    descriptionCtrl.dispose();
    emailOtpCtrl.dispose();
    phoneOtpCtrl.dispose();
    super.dispose();
  }

  // Updated to match your latest API exactly
  Future<void> _registerSupplier() async {
    developer.log("SUPPLIER REGISTRATION STARTED");

    if (!_formKey.currentState!.validate()) {
      developer.log("FORM VALIDATION FAILED");
      return;
    }

    if (!isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify your email first")),
      );
      return;
    }

    if (!isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify your mobile number first")),
      );
      return;
    }

    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (selectedLat == null || selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location on the map.")),
      );
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No internet connection.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      developer.log("PREPARING PAYLOAD FOR SUPPLIER REGISTRATION");

      final Map<String, dynamic> payload = {
        "firstName": firstNameCtrl.text.trim(),
        "lastName": lastNameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "mobile": phoneCtrl.text.trim(),
        "shopName": shopNameCtrl.text.trim(),
        "description": descriptionCtrl.text.trim(),
        "country": "India",
        "state": stateCtrl.text.trim(),
        "city": cityCtrl.text.trim(),
        "pincode": pincodeCtrl.text.trim(),
        "location": {
          "lat": selectedLat,
          "lng": selectedLng,
        },
        "address": addressCtrl.text.trim(),
        "businessRegistrationNo": registrationNumberCtrl.text.trim(),
        "supplierType": categoryCtrl.text.trim(),
        "profileImage": null, // No profile image upload in current UI
        "licenseFiles": [], // No license upload in current UI
        "password": passwordCtrl.text,
        "referredByCode":
            referralCtrl.text.trim().isEmpty ? null : referralCtrl.text.trim(),
      };

      developer.log("FINAL PAYLOAD: ${jsonEncode(payload)}");
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http
          .post(
            Uri.parse("https://admin.v2winonline.com/api/admin/suppliers"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              'Cookie': 'crm_access_token=$token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      developer.log("RESPONSE STATUS: ${response.statusCode}");
      developer.log("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {};
        }

        final message = data is Map && data["message"] != null
            ? data["message"]
            : "Supplier registered successfully!";

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        String errorMessage = "Registration failed";

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData["message"] ?? errorMessage;
        } catch (_) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }

        if (response.statusCode == 409) {
          errorMessage = "Email or mobile already registered.";
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log("REGISTRATION ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash.png'),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (currentStep + 1) / 3,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => currentStep = index),
                      children: [
                        _buildPersonalDetailsPage(),
                        _buildBusinessDetailsPage(),
                        _buildLocationSetupPage(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Your existing UI methods remain 100% unchanged
  Widget _buildPersonalDetailsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).primaryColor, size: 20.sp),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(height: 10.h),
          Text("Personal Details",
              style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor)),
          SizedBox(height: 6.h),
          Text("Tell us about yourself",
              style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black)),
          SizedBox(height: 30.h),
          Row(children: [
            Expanded(
                child: _buildOutlinedField(
                    label: "First Name *",
                    controller: firstNameCtrl,
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Required' : null)),
            SizedBox(width: 16.w),
            Expanded(
                child: _buildOutlinedField(
                    label: "Last Name *",
                    controller: lastNameCtrl,
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Required' : null)),
          ]),
          SizedBox(height: 16.h),
          // Email with Verification
          _buildVerificationField(
            label: "Email",
            controller: emailCtrl,
            otpController: emailOtpCtrl,
            isOtpSent: isEmailOtpSent,
            isVerified: isEmailVerified,
            isSending: isSendingEmailOtp,
            isVerifying: isVerifyingEmailOtp,
            keyboardType: TextInputType.emailAddress,
            onSendOtp: () => _handleEmailOtp(),
            onVerify: () => _handleEmailVerify(),
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(v!.trim())) return 'Invalid email';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          // Mobile Number with Verification
          _buildVerificationField(
            label: "Mobile Number",
            controller: phoneCtrl,
            otpController: phoneOtpCtrl,
            isOtpSent: isPhoneOtpSent,
            isVerified: isPhoneVerified,
            isSending: isSendingPhoneOtp,
            isVerifying: isVerifyingPhoneOtp,
            keyboardType: TextInputType.phone,
            onSendOtp: () => _handlePhoneOtp(),
            onVerify: () => _handlePhoneVerify(),
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Required';
              if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(v!.trim()))
                return 'Invalid phone';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildOutlinedField(
              label: "Password *",
              controller: passwordCtrl,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 16.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              validator: (v) =>
                  (v?.length ?? 0) < 6 ? 'Minimum 6 characters' : null),
          SizedBox(height: 16.h),
          _buildOutlinedField(
            label: "Confirm Password *",
            controller: confirmPasswordCtrl,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: 16.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Confirm Password required';
              if (v != passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildOutlinedField(
              label: "Referral Code (optional)", controller: referralCtrl),
          SizedBox(height: 48.h),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (!isEmailVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please verify your email.")),
                    );
                    return;
                  }
                  if (!isPhoneVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please verify your phone number.")),
                    );
                    return;
                  }
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(200.w, 40.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r))),
              child: Text('Continue',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).primaryColor, size: 20.sp),
                  onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease))),
          SizedBox(height: 10.h),
          Text("Business Details",
              style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor)),
          SizedBox(height: 6.h),
          Text("Provide your business information",
              style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black)),
          SizedBox(height: 30.h),
          _buildOutlinedField(
              label: "Shop Name *",
              controller: shopNameCtrl,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Shop name required' : null),
          SizedBox(height: 16.h),
          _buildOutlinedField(
              label: "Registration Number *",
              controller: registrationNumberCtrl,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
          SizedBox(height: 16.h),
          _buildOutlinedField(
              label: "Business Description *",
              controller: descriptionCtrl,
              maxLines: 3,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Description required' : null),
          SizedBox(height: 16.h),
          _buildOutlinedField(
              label: "Category *",
              controller: categoryCtrl,
              hint: "general",
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Category required' : null),
          SizedBox(height: 48.h),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(200.w, 40.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r))),
              child: Text('Continue',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildLocationSetupPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).primaryColor, size: 20.sp),
                  onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease))),
          SizedBox(height: 10.h),
          Text("Business Location",
              style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor)),
          SizedBox(height: 6.h),
          Text("Set your business location",
              style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black)),
          SizedBox(height: 30.h),
          GestureDetector(
            onTap: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => const LocationPickerDialog(),
              );
              if (result != null && mounted) {
                setState(() {
                  selectedLat = result['lat'] as double?;
                  selectedLng = result['lng'] as double?;
                  addressCtrl.text = (result['address'] ?? '').toString();
                });

                // Auto-fill state, city, pincode
                if (selectedLat != null && selectedLng != null) {
                  try {
                    List<Placemark> placemarks = await placemarkFromCoordinates(
                        selectedLat!, selectedLng!);
                    if (placemarks.isNotEmpty) {
                      Placemark place = placemarks[0];
                      setState(() {
                        stateCtrl.text = place.administrativeArea ?? '';
                        cityCtrl.text = place.locality ??
                            place.subLocality ??
                            place.subAdministrativeArea ??
                            '';
                        pincodeCtrl.text = place.postalCode ?? '';
                      });
                    }
                  } catch (e) {
                    developer.log("Error fetching placemarks: $e");
                  }
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).primaryColor, size: 18.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            addressCtrl.text.isEmpty
                                ? "Tap to select location"
                                : addressCtrl.text,
                            style: GoogleFonts.poppins(
                                fontSize: 9.sp, color: Colors.grey.shade600),
                            softWrap: true),
                        if (selectedLat != null)
                          Text(
                              "Lat: ${selectedLat!.toStringAsFixed(6)}, Lng: ${selectedLng!.toStringAsFixed(6)}",
                              style: GoogleFonts.poppins(
                                  fontSize: 9.sp,
                                  color: Theme.of(context).primaryColor)),
                      ]),
                ),
              ]),
            ),
          ),
          SizedBox(height: 16.h),
          _buildOutlinedField(
              label: "Full Address *",
              controller: addressCtrl,
              maxLines: 2,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Address required' : null),
          SizedBox(height: 16.h),
          Row(children: [
            Expanded(
                child: _buildOutlinedField(
                    label: "State *",
                    controller: stateCtrl,
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'State required' : null)),
            SizedBox(width: 12.w),
            Expanded(
                child: _buildOutlinedField(
                    label: "City *",
                    controller: cityCtrl,
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'City required' : null)),
            SizedBox(width: 12.w),
            Expanded(
                child: _buildOutlinedField(
                    label: "Pincode *",
                    controller: pincodeCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Pincode required';
                      if (!RegExp(r'^[0-9]{6}$').hasMatch(v!.trim()))
                        return 'Enter valid 6-digit pincode';
                      return null;
                    })),
          ]),
          SizedBox(height: 60.h),
          Center(
            child: ElevatedButton(
              onPressed: isLoading ? null : _registerSupplier,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(280.w, 45.h),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                  elevation: 3),
              child: isLoading
                  ? SizedBox(
                      height: 18.h,
                      width: 18.w,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.w))
                  : Text('Complete Registration',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildOutlinedField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? hint,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 10.sp),
        decoration: InputDecoration(
          label: Text(label,
              style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 8.sp)),
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // --- OTP HELPERS ---

  Widget _buildVerificationField({
    required String label,
    required TextEditingController controller,
    required TextEditingController otpController,
    required bool isOtpSent,
    required bool isVerified,
    required bool isSending,
    required bool isVerifying,
    required VoidCallback onSendOtp,
    required VoidCallback onVerify,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: isVerified ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border:
                isVerified ? Border.all(color: Colors.green.shade200) : null,
            boxShadow: [
              if (!isVerified)
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(" *",
                                style: GoogleFonts.poppins(
                                    color: Colors.red, fontSize: 8.sp)),
                            const Spacer(),
                            if (isVerified)
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green, size: 12.sp),
                                  SizedBox(width: 4.w),
                                  Text("Verified",
                                      style: GoogleFonts.poppins(
                                          color: Colors.green,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        TextFormField(
                          controller: controller,
                          enabled: !isVerified,
                          keyboardType: keyboardType,
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: isVerified ? Colors.grey : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                            filled: isVerified,
                            fillColor: isVerified
                                ? Colors.blue.withOpacity(0.05)
                                : Colors.white,
                          ),
                          validator: validator,
                        ),
                      ],
                    ),
                  ),
                  if (!isVerified) ...[
                    SizedBox(width: 12.w),
                    SizedBox(
                      height: 40.h,
                      child: ElevatedButton(
                        onPressed: isSending ? null : onSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: isSending
                            ? SizedBox(
                                height: 12.h,
                                width: 12.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                            : Text(
                                isOtpSent ? "Resend" : "Send OTP",
                                style: GoogleFonts.poppins(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isOtpSent && !isVerified) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4),
                        decoration: InputDecoration(
                          hintText: "OTP",
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              letterSpacing: 0,
                              color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      height: 40.h,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.6),
                              Theme.of(context).primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ElevatedButton(
                          onPressed: isVerifying ? null : onVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: isVerifying
                              ? SizedBox(
                                  height: 12.h,
                                  width: 12.w,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 1.5, color: Colors.white))
                              : Text(
                                  "Verify",
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleEmailOtp() async {
    if (emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email first")),
      );
      return;
    }
    if (firstNameCtrl.text.isEmpty || lastNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name first")),
      );
      return;
    }
    setState(() => isSendingEmailOtp = true);
    try {
      final response = await ApiService.sendOtp(
        emailCtrl.text.trim(),
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        role: 'supplier',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => isEmailOtpSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "OTP sent successfully")),
          );
        } else {
          throw data['message'] ?? "Failed to send OTP";
        }
      } else {
        String msg = "Server error: ${response.statusCode}";
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) msg = data['message'];
        } catch (_) {}
        throw msg;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isSendingEmailOtp = false);
    }
  }

  Future<void> _handleEmailVerify() async {
    if (emailOtpCtrl.text.isEmpty) return;
    setState(() => isVerifyingEmailOtp = true);
    try {
      final response = await ApiService.verifyOtp(
          emailCtrl.text.trim(), emailOtpCtrl.text.trim(),
          role: 'supplier');
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => isEmailVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Email verified successfully"),
              backgroundColor: Colors.green),
        );
      } else {
        String msg = "Verification failed";
        try {
          final data = jsonDecode(response.body);
          msg = data['message'] ?? msg;
        } catch (_) {}
        throw msg;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isVerifyingEmailOtp = false);
    }
  }

  Future<void> _handlePhoneOtp() async {
    if (phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter mobile number first")),
      );
      return;
    }
    setState(() => isSendingPhoneOtp = true);
    // Static mobile OTP as requested
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isPhoneOtpSent = true;
      isSendingPhoneOtp = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("OTP sent to your mobile number (Use 123456)")),
    );
  }

  Future<void> _handlePhoneVerify() async {
    if (phoneOtpCtrl.text == "123456") {
      setState(() => isPhoneVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Mobile number verified successfully"),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid mobile OTP")),
      );
    }
  }
}

// LocationPickerDialog remains exactly the same
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});
  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  LatLng selectedLocation = const LatLng(18.5362, 73.8939);
  String address = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _updateAddress(selectedLocation);
  }

  Future<void> _updateAddress(LatLng point) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          // Robust full address construction with Plus Code filtering
          final parts = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country
          ];

          List<String> filteredParts = [];
          for (var part in parts) {
            if (part == null || part.isEmpty) continue;

            // Simple Plus Code detection: contains '+' and is relatively short
            if (part.contains('+') && part.length < 15) continue;

            // Avoid adding same text twice consecutively
            if (filteredParts.isNotEmpty && filteredParts.last == part)
              continue;

            filteredParts.add(part);
          }

          // Special check: sometimes 'name' is just a redundant street number or the street itself
          if (filteredParts.length > 1 &&
              filteredParts[1].contains(filteredParts[0])) {
            filteredParts.removeAt(0);
          }

          address = filteredParts.join(', ').trim();

          // Handle common formatting issues
          address = address.replaceAll(RegExp(r',\s*,'), ',').trim();
          if (address.startsWith(',')) address = address.substring(1).trim();
          if (address.endsWith(',')) {
            address = address.substring(0, address.length - 1).trim();
          }

          _searchController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        setState(() {
          address =
              '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
          _searchController.text = address;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          bool? openSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                  'Please enable location services to find your current location.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Geolocator.openLocationSettings();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OPEN SETTINGS'),
                ),
              ],
            ),
          );
          if (openSettings != true) return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          bool? openSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.pop(context, true);
                  },
                  child: const Text('OPEN SETTINGS'),
                ),
              ],
            ),
          );
          if (openSettings == true) {
            await Future.delayed(const Duration(seconds: 1));
            _getCurrentLocation();
          }
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 15));
      final newLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() => selectedLocation = newLocation);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 16.0),
        );
        // Small delay to let map animation start
        await Future.delayed(const Duration(milliseconds: 500));
        await _updateAddress(newLocation);
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Business Location',
                style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center),
            SizedBox(height: 20.h),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Theme.of(context).primaryColor),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.w),
                ),
                onChanged: (value) => setState(() {}),
                onSubmitted: (value) async {
                  if (value.isEmpty) return;

                  setState(() => _isLoading = true);

                  try {
                    List<Location> locations = await locationFromAddress(value)
                        .timeout(const Duration(seconds: 10));

                    if (locations.isEmpty) {
                      throw Exception('No matching locations found');
                    }

                    final location = locations.first;
                    final newLocation =
                        LatLng(location.latitude, location.longitude);

                    setState(() {
                      selectedLocation = newLocation;
                    });

                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(newLocation, 16.0),
                    );

                    await Future.delayed(const Duration(milliseconds: 300));
                    await _updateAddress(newLocation);
                  } catch (e) {
                    debugPrint('Search error: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Could not find the location. Please try again.')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: _isLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.my_location, size: 18.sp),
              label: Text('Use My Location',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r))),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade300)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation,
                      zoom: 16.0,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (point) {
                      setState(() => selectedLocation = point);
                      _updateAddress(point);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('selectedLocation'),
                        position: selectedLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected:',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    Text(address.isEmpty ? 'Tap map to select' : address),
                    Text(
                        '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11.sp, color: Colors.grey.shade700)),
                  ]),
            ),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(
                  child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('CANCEL',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600)))),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'lat': selectedLocation.latitude,
                  'lng': selectedLocation.longitude,
                  'address': address.isNotEmpty
                      ? address
                      : '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                }),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(120.w, 44.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r))),
                child: Text('CONFIRM',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
