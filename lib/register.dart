import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  String selectedCategory = 'unisex'; // default
  List<String> subCategories = []; // Shop, Shop At Home, Onsite

  double? selectedLat;
  double? selectedLng;

  bool isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLat == null || selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final payload = {
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
        "category": selectedCategory,
        "location": {"lat": selectedLat, "lng": selectedLng},
        "baseLocation": {"lat": selectedLat, "lng": selectedLng},
      };

      // Add optional fields if not empty
      if (businessDescCtrl.text.trim().isNotEmpty) {
        payload["description"] = businessDescCtrl.text.trim();
      }
      if (websiteCtrl.text.trim().isNotEmpty) {
        payload["website"] = websiteCtrl.text.trim();
      }
      if (referralCtrl.text.trim().isNotEmpty) {
        payload["referralCode"] = referralCtrl.text.trim();
      }

      // Map subCategories based on checkboxes (adjust strings to match API expectation)
      if (subCategories.isNotEmpty) {
        payload["subCategories"] = subCategories.map((cat) {
          if (cat == "home") return "shop at home";
          if (cat == "onsite") return "onsite";
          return "shop";
        }).toList();
      } else {
        payload["subCategories"] = ["shop"]; // Default as per response example
      }

      final response = await http.post(
        Uri.parse("https://partners.v2winonline.com/api/crm/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data["message"] == "Account created successfully. Proceed to onboarding.") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"])),
          );
          // Navigate to onboarding or dashboard
          // Example: Navigator.pushReplacementNamed(context, '/onboarding');
          Navigator.pop(context); // Or handle navigation as needed
        } else {
          throw Exception(data["message"] ?? "Registration failed");
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["message"] ?? "Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (currentStep + 1) / 2,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
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
                    onPageChanged: (index) => setState(() => currentStep = index),
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
                icon: Icon(Icons.arrow_back, color: Colors.blue.shade700, size: 24.sp),
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
              color: Colors.blue.shade700,
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
                  color: Colors.blue.shade100.withOpacity(0.2),
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
          _buildOutlinedField(
                          label: "Phone", 
                          controller: phoneCtrl, 
                          keyboardType: TextInputType.phone,
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
          _buildOutlinedField(
                          label: "Email", 
                          controller: emailCtrl, 
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                          const SizedBox(height: 16),
                          _buildOutlinedField(
                          label: "Password", 
                          controller: passwordCtrl, 
                          obscureText: true,
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
                backgroundColor: Colors.blue.shade700,
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
                icon: Icon(Icons.arrow_back, color: Colors.blue.shade700, size: 24.sp),
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
                color: Colors.blue.shade700,
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
            const Text("Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    Text(
                      addressCtrl.text.isEmpty ? "Choose from Map" : addressCtrl.text,
                      style: TextStyle(color: addressCtrl.text.isEmpty ? Colors.grey.shade600 : Colors.black),
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
                  backgroundColor: Colors.blue.shade700,
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
            color: Colors.blue.shade100.withOpacity(0.2),
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
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.blue.shade700,
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
          color: checked ? Colors.blue.shade100 : Colors.transparent,
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
              activeColor: Colors.blue.shade700,
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
}

// Keep your existing LocationPickerDialog (unchanged)
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});
  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  LatLng selectedLocation = LatLng(28.598392, 77.163469);
  String address = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final MapController _mapController = MapController();

  Future<void> _updateAddress(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          address = '${p.street ?? ''} ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'.replaceAll('  ', ' ').trim();
          if (address.endsWith(',')) {
            address = address.substring(0, address.length - 1).trim();
          }
          _searchController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        address = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
        _searchController.text = address;
      });
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
              content: const Text('Please enable location services to find your current location.'),
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
              content: Text('Error checking location services. Please try again.'),
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
                content: Text('Location permission is required to find your current location.'),
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
          _mapController.move(newLocation, 15.0);
          
          // Update address after a short delay to ensure map has moved
          await Future.delayed(const Duration(milliseconds: 300));
          await _updateAddress(newLocation);
        }
      } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Getting location is taking longer than expected. Please check your connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
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
                  color: Colors.blue.shade700,
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
                      color: Colors.blue.shade100.withOpacity(0.2),
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
                    prefixIcon: Icon(Icons.search, size: 18.sp, color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18.sp, color: Colors.blue.shade700),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) async {
                    if (value.isEmpty) return;
                  
                  setState(() => _isLoading = true);
                  
                  try {
                    List<Location> locations = await locationFromAddress(value).timeout(
                      const Duration(seconds: 10),
                      onTimeout: () {
                        throw TimeoutException('Location search timed out');
                      },
                    );
                    
                    if (locations.isEmpty) {
                      throw Exception('No matching locations found');
                    }
                    
                    final location = locations.first;
                    final newLocation = LatLng(location.latitude, location.longitude);
                    
                    setState(() {
                      selectedLocation = newLocation;
                    });
                    
                    // Animate map to the new location
                    _mapController.move(newLocation, 15.0);
                    
                    // Update address after a short delay to ensure map has moved
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _updateAddress(newLocation);
                    
                  } on TimeoutException {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Search is taking too long. Please try again.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error searching location: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e is TimeoutException 
                              ? 'Search timed out. Please check your connection.'
                              : 'Could not find the location. Please try a different search term.'
                          ),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.my_location, size: 20.sp),
                label: Text('Use Current Location', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
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
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: selectedLocation,
                      zoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() => selectedLocation = point);
                        _updateAddress(point);
                      },
                      onMapReady: () {
                        // Ensure map is properly centered on the selected location
                        if (_mapController.camera.center != selectedLocation) {
                          _mapController.move(selectedLocation, _mapController.camera.zoom);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.glowvita.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: selectedLocation,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
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
                      address.isNotEmpty ? address : 'Tap on the map to select a location',
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
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'lat': selectedLocation.latitude,
                        'lng': selectedLocation.longitude,
                        'address': address.isNotEmpty ? address : '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
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