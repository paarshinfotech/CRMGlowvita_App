import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'services/api_service.dart';

class RegisterPage extends StatefulWidget {
  final String? initialRole;

  const RegisterPage({super.key, this.initialRole});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int currentStep = 0;

  // Controllers
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController businessNameCtrl = TextEditingController();
  final TextEditingController businessDescCtrl = TextEditingController();
  final TextEditingController websiteCtrl = TextEditingController();
  final TextEditingController referralCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
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

  String selectedCategory = 'unisex'; // default
  List<String> subCategories = []; // Shop, Shop At Home, Onsite

  double? selectedLat;
  double? selectedLng;

  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (selectedLat == null || selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final payload = <String, dynamic>{
        "firstName": firstNameCtrl.text.trim(),
        "lastName": lastNameCtrl.text.trim(),
        "businessName": businessNameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "password": passwordCtrl.text, 
        "state": stateCtrl.text.trim(),
        "city": cityCtrl.text.trim(),
        "pincode": pincodeCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        "category": selectedCategory == 'male'
            ? 'men'
            : (selectedCategory == 'female' ? 'women' : 'unisex'),

        // IMPORTANT: Ensure double
        "location": {
          "lat": selectedLat!.toDouble(),
          "lng": selectedLng!.toDouble(),
        },
        "baseLocation": {
          "lat": selectedLat!.toDouble(),
          "lng": selectedLng!.toDouble(),
        },
      };

      /// Optional fields
      if (businessDescCtrl.text.trim().isNotEmpty) {
        payload["description"] = businessDescCtrl.text.trim();
      }
      if (websiteCtrl.text.trim().isNotEmpty) {
        payload["website"] = websiteCtrl.text.trim();
      }
      if (referralCtrl.text.trim().isNotEmpty) {
        payload["referralCode"] = referralCtrl.text.trim();
      }

      /// ✅ Correct subCategories as per API response example
      /// API expects: ["at-salon"] not "shop", "onsite", etc.
      final List<String> mappedSubs = subCategories.isNotEmpty
          ? subCategories.map((cat) {
              if (cat == "home") return "at-home";
              if (cat == "onsite") return "at-home"; // treat onsite as at-home
              return "at-salon";
            }).toList()
          : ["at-salon"];

      payload["subCategories"] = mappedSubs;

      // Calculate vendorType
      String vType = "shop-only";
      bool hasSalon = mappedSubs.contains("at-salon");
      bool hasHome = mappedSubs.contains("at-home");
      if (hasSalon && hasHome) {
        vType = "hybrid";
      } else if (hasHome) {
        vType = "home-only";
      }
      payload["vendorType"] = vType;
      payload["travelRadius"] = 15;
      payload["travelSpeed"] = 30;

      debugPrint("REGISTER PAYLOAD: ${jsonEncode(payload)}");

      final response = await ApiService.registerVendor(payload);

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.body}");

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception("Invalid server response");
      }

      /// ✅ Accept ANY success code (200–299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final message = data["message"] ?? "Registration successful";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        /// Navigate forward
        Navigator.pop(context);
      } else {
        throw Exception(
            data["message"] ?? "Server error (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Registration error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash.png'),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Progress bar
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (currentStep + 1) / 2,
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
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => currentStep = index),
                    children: [
                      _buildBusinessSetupPage(),
                      _buildLocationSetupPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSetupPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          // Back button for first step
          if (currentStep == 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).primaryColor, size: 24.sp),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            SizedBox(height: 10.h),
          ],
          Text(
            "Tell us about your business",
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              shadows: [
                Shadow(
                  blurRadius: 3.0,
                  color: Colors.black.withOpacity(0.25),
                  offset: Offset(1.5, 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Provide your business information and services.",
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 30.h),

          // Business Name & Description
          Row(
            children: [
              Expanded(
                child: _buildOutlinedField(
                  label: "Enter business name",
                  controller: businessNameCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Business name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOutlinedField(
                  label: "Enter business description",
                  controller: businessDescCtrl,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category dropdown
          _buildOutlinedField(
            label: "Select salon category",
            controller: TextEditingController(text: selectedCategory),
            readOnly: true,
            suffixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                icon: Icon(Icons.arrow_drop_down, size: 18.sp),
                onChanged: (val) => setState(() => selectedCategory = val!),
                items: ['unisex', 'male', 'female']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: GoogleFonts.poppins(fontSize: 9.sp),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Service type checkboxes
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.all(12.w),
            child: Wrap(
              spacing: 16.w,
              runSpacing: 8.h,
              children: [
                _buildCheckbox("Shop", "shop"),
                _buildCheckbox("Shop At Home", "home"),
                _buildCheckbox("Onsite", "onsite"),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Personal info
          Row(
            children: [
              Expanded(
                child: _buildOutlinedField(
                  label: "First Name",
                  controller: firstNameCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOutlinedField(
                  label: "Last Name",
                  controller: lastNameCtrl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Phone Number with Verification
          _buildVerificationField(
            label: "Phone",
            controller: phoneCtrl,
            otpController: phoneOtpCtrl,
            isOtpSent: isPhoneOtpSent,
            isVerified: isPhoneVerified,
            isSending: isSendingPhoneOtp,
            isVerifying: isVerifyingPhoneOtp,
            keyboardType: TextInputType.phone,
            onSendOtp: () => _handlePhoneOtp(),
            onVerify: () => _handlePhoneVerify(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildOutlinedField(
            label: "Password",
            controller: passwordCtrl,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 16.sp,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Optional fields
          Row(
            children: [
              Expanded(
                child: _buildOutlinedField(
                  label: "https://example.com",
                  controller: websiteCtrl,
                  hint: "Website (optional)",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOutlinedField(
                  label: "Enter referral code if any",
                  controller: referralCtrl,
                  hint: "Referral code (optional)",
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Next button
          Center(
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 1,
                textStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                minimumSize: Size(200.w, 35.h),
              ),
              child: Text('Continue'),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            // Back button for second step
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).primaryColor, size: 24.sp),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "Where is your business located?",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                shadows: [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Set your business location and address details.",
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),
            // Map picker
            const Text("Location",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => const LocationPickerDialog(),
                );
                if (result != null) {
                  setState(() {
                    selectedLat = result['lat'];
                    selectedLng = result['lng'];
                    addressCtrl.text = result['address'];
                  });

                  // Auto-fill state, city, pincode
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
                    debugPrint("Error fetching placemarks: $e");
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        addressCtrl.text.isEmpty
                            ? "Choose from Map"
                            : addressCtrl.text,
                        style: TextStyle(
                            color: addressCtrl.text.isEmpty
                                ? Colors.grey.shade600
                                : Colors.black),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Full Address
            _buildOutlinedField(
              label: "Full Address",
              controller: addressCtrl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Full address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // State, City, Pincode
            Row(
              children: [
                Expanded(
                  child: _buildOutlinedField(
                    label: "State",
                    controller: stateCtrl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOutlinedField(
                    label: "City",
                    controller: cityCtrl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildOutlinedField(
                    label: "Pincode",
                    controller: pincodeCtrl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pincode is required';
                      }
                      if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                        return 'Enter a valid 6-digit pincode';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // Submit button
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 1,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  minimumSize: Size(200.w, 35.h),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 18.h,
                        width: 18.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      )
                    : const Text('Complete Registration'),
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    int maxLines = 1,
    String? hint,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 10.sp),
        decoration: InputDecoration(
          label: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Theme.of(context).primaryColor,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          suffixIcon: suffixIcon,
          hintText: hint,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, String value) {
    bool checked = subCategories.contains(value);
    return GestureDetector(
      onTap: () => setState(() {
        if (checked) {
          subCategories.remove(value);
        } else {
          subCategories.add(value);
        }
      }),
      child: Container(
        decoration: BoxDecoration(
          color: checked
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: checked,
              onChanged: (val) => setState(() {
                if (val == true) {
                  subCategories.add(value);
                } else {
                  subCategories.remove(value);
                }
              }),
              activeColor: Theme.of(context).primaryColor,
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          decoration: BoxDecoration(
            color: isVerified ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: isVerified ? Border.all(color: Colors.green.shade200) : null,
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
                                color: Colors.black87,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(" *",
                                style: GoogleFonts.poppins(
                                    color: Colors.red, fontSize: 10.sp)),
                            const Spacer(),
                            if (isVerified)
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green, size: 14.sp),
                                  SizedBox(width: 4.w),
                                  Text("Verified",
                                      style: GoogleFonts.poppins(
                                          color: Colors.green,
                                          fontSize: 10.sp,
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
                            fontSize: 11.sp,
                            color: isVerified ? Colors.grey : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: Colors.grey.shade300),
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
                                    fontSize: 10.sp, fontWeight: FontWeight.w600),
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
                              fontSize: 11.sp,
                              letterSpacing: 0,
                              color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
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
                                      fontSize: 11.sp,
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
        role: widget.initialRole ?? 'vendor',
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
          role: widget.initialRole ?? 'vendor');
      if (response.statusCode == 200) {
        setState(() => isEmailVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified successfully"), backgroundColor: Colors.green),
        );
      } else {
        final data = jsonDecode(response.body);
        throw data['message'] ?? "Invalid OTP";
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
        const SnackBar(content: Text("Please enter phone number first")),
      );
      return;
    }
    setState(() => isSendingPhoneOtp = true);
    // Static phone OTP as requested
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isPhoneOtpSent = true;
      isSendingPhoneOtp = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP sent to your phone number (Use 123456)")),
    );
  }

  Future<void> _handlePhoneVerify() async {
    if (phoneOtpCtrl.text == "123456") {
      setState(() => isPhoneVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone verified successfully"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid phone OTP")),
      );
    }
  }
}

// Keep your existing LocationPickerDialog (unchanged)
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});
  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  LatLng selectedLocation = const LatLng(28.598392, 77.163469);
  String address = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  GoogleMapController? _mapController;

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

          // 1. Filter out null/empty
          // 2. Filter out Plus Codes (alphabest/numbers with +)
          // 3. Filter out redundant parts (e.g. name same as street)
          List<String> filteredParts = [];
          for (var part in parts) {
            if (part == null || part.isEmpty) continue;

            // Simple Plus Code detection: contains '+' and is relatively short or looks like a code
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          bool? serviceEnabledRequested = await showDialog<bool>(
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

          if (serviceEnabledRequested != true) {
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking location service: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Error checking location services. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permission is required to find your current location.'),
                duration: Duration(seconds: 3),
              ),
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
            // Wait a moment for the user to return from settings
            await Future.delayed(const Duration(seconds: 1));
            // Retry getting location after returning from settings
            _getCurrentLocation();
          }
        }
        return;
      }

      // Get the current position with timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));

        final newLocation = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            selectedLocation = newLocation;
          });

          // Animate map to the new location
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newLocation, 15.0),
          );

          // Update address after a short delay to ensure map has moved
          await Future.delayed(const Duration(milliseconds: 300));
          await _updateAddress(newLocation);
        }
      } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Getting location is taking longer than expected. Please check your connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      elevation: 4,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Your Location',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.25),
                      offset: Offset(1.5, 1.5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(fontSize: 10.sp),
                  decoration: InputDecoration(
                    hintText: 'Search for a location',
                    hintStyle: GoogleFonts.poppins(fontSize: 10.sp),
                    prefixIcon: Icon(Icons.search,
                        size: 18.sp, color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                size: 18.sp,
                                color: Theme.of(context).primaryColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) async {
                    if (value.isEmpty) return;

                    setState(() => _isLoading = true);

                    try {
                      List<Location> locations =
                          await locationFromAddress(value).timeout(
                        const Duration(seconds: 10),
                        onTimeout: () {
                          throw TimeoutException('Location search timed out');
                        },
                      );

                      if (locations.isEmpty) {
                        throw Exception('No matching locations found');
                      }

                      final location = locations.first;
                      final newLocation =
                          LatLng(location.latitude, location.longitude);

                      setState(() {
                        selectedLocation = newLocation;
                      });

                      // Animate map to the new location
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(newLocation, 15.0),
                      );

                      // Update address after a short delay to ensure map has moved
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _updateAddress(newLocation);
                    } on TimeoutException {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Search is taking too long. Please try again.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error searching location: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e is TimeoutException
                                ? 'Search timed out. Please check your connection.'
                                : 'Could not find the location. Please try a different search term.'),
                            duration: const Duration(seconds: 3),
                          ),
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.my_location, size: 20.sp),
                label:
                    Text('Use Current Location', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation,
                      zoom: 15.0,
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      address.isNotEmpty
                          ? address
                          : 'Tap on the map to select a location',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      textStyle: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(
                      "CANCEL",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'lat': selectedLocation.latitude,
                        'lng': selectedLocation.longitude,
                        'address': address.isNotEmpty
                            ? address
                            : '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                      });
                    },
                    child: Text(
                      "CONFIRM LOCATION",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
