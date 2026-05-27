import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../marketing/message_blast.dart';
import '../supplier_model.dart';
import '../vendor_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'supp_wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuppProfilePage extends StatefulWidget {
  const SuppProfilePage({super.key});
  @override
  _SuppProfilePageState createState() => _SuppProfilePageState();
}

class _SuppProfilePageState extends State<SuppProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SupplierProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, String> _planIdToName = {};
  List<dynamic> _smsPackages = [];
  bool _isLoadingSMSPackages = true;

  // Profile tab controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minOrderValueController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _supplierTypeController = TextEditingController();
  final _businessRegNoController = TextEditingController();
  final _gstNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Bank details controllers
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _upiIdController = TextEditingController();

  // Upload states
  String? _newProfileImageBase64;
  List<String> _newGalleryBase64 = [];
  Map<String, String?> _newDocumentsBase64 = {};

  // Travel settings (local storage for supplier)
  String _travelType = "Shop Only (No travel)";
  final _radiusController = TextEditingController();
  final _speedController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // Opening hours (local storage for supplier)
  Map<String, bool> openDays = {};
  Map<String, String> openTimes = {};
  Map<String, String> closeTimes = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuppWalletPage()),
        ).then((_) {
          _tabController.animateTo(0);
        });
      }
    });
    _loadLocalSupplierSettings();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final profile = await ApiService.getSupplierProfile();

      try {
        final plans = await ApiService.getSubscriptionPlans();
        _planIdToName = {for (var p in plans) p.id: p.name};
      } catch (e) {
        debugPrint("Error fetching plans: $e");
      }

      try {
        final smsResponse = await ApiService.fetchSMSPackages();
        if (smsResponse['success'] == true) {
          _smsPackages = smsResponse['data'] ?? [];
        }
      } catch (e) {
        debugPrint("Error fetching SMS packages: $e");
      } finally {
        _isLoadingSMSPackages = false;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
        _updateControllers(profile);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _updateControllers(SupplierProfile profile) {
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _shopNameController.text = profile.shopName;
    _descriptionController.text = profile.description;
    _minOrderValueController.text = profile.minOrderValue.toString();
    _emailController.text = profile.email;
    _mobileController.text = profile.mobile;
    _supplierTypeController.text = profile.supplierType ?? "";
    _businessRegNoController.text = profile.businessRegistrationNo ?? "";
    _gstNoController.text = profile.gstNo ?? "";
    _addressController.text = profile.address ?? "";
    _cityController.text = profile.city ?? "";
    _stateController.text = profile.state ?? "";
    _pincodeController.text = profile.pincode ?? "";
    _taxValueController.text = profile.taxes?.taxValue.toString() ?? "0";

    if (profile.bankDetails != null) {
      _accountHolderController.text = profile.bankDetails!.accountHolder ?? "";
      _accountNumberController.text = profile.bankDetails!.accountNumber ?? "";
      _bankNameController.text = profile.bankDetails!.bankName ?? "";
      _ifscCodeController.text = profile.bankDetails!.ifscCode ?? "";
      _upiIdController.text = profile.bankDetails!.upiId ?? "";
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'shopName': _shopNameController.text,
        'description': _descriptionController.text,
        'minOrderValue': double.tryParse(_minOrderValueController.text) ?? 0,
        'email': _emailController.text,
        'mobile': _mobileController.text,
        'supplierType': _supplierTypeController.text,
        'businessRegistrationNo': _businessRegNoController.text,
        'gstNo': _gstNoController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
      };

      if (_newProfileImageBase64 != null) {
        payload['profileImage'] = _newProfileImageBase64!;
      }

      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      _newProfileImageBase64 = null;
      _fetchProfileData();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update failed. Check console for details.'),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveBankDetails() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);
    try {
      final payload = _profile!.toJson();
      payload['bankDetails'] = {
        'accountHolder': _accountHolderController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'ifscCode': _ifscCodeController.text.trim(),
        'upiId': _upiIdController.text.trim(),
      };

      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details updated successfully')),
      );
      _fetchProfileData();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update failed. Check console for details.'),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDocuments() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'documents': {
          ...(_profile!.documents?.toJson() ?? {}),
          ..._newDocumentsBase64,
        },
      };

      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents updated successfully')),
      );
      _newDocumentsBase64.clear();
      _fetchProfileData();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update failed. Check console for details.'),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(bool forProfile) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64 =
          "data:image/${image.path.split('.').last};base64,${base64Encode(bytes)}";
      setState(() {
        if (forProfile) {
          _newProfileImageBase64 = base64;
        } else {
          _newGalleryBase64.add(base64);
        }
      });
    }
  }

  Future<void> _pickDocument(String key) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png'],
    );

    if (result != null) {
      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final base64 =
          "data:${file.extension == 'pdf' ? 'application/pdf' : 'image/${file.extension}'};base64,${base64Encode(bytes)}";
      setState(() {
        _newDocumentsBase64[key] = base64;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _shopNameController.dispose();
    _descriptionController.dispose();
    _minOrderValueController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _supplierTypeController.dispose();
    _businessRegNoController.dispose();
    _gstNoController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    _taxValueController.dispose();
    _radiusController.dispose();
    _speedController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalSupplierSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _radiusController.text = prefs.getString('supp_travel_radius') ?? '10';
      _speedController.text = prefs.getString('supp_travel_speed') ?? '30';
      _latController.text = prefs.getString('supp_lat') ?? '';
      _lngController.text = prefs.getString('supp_lng') ?? '';
      _travelType =
          prefs.getString('supp_travel_type') ?? 'Shop Only (No travel)';

      // Opening hours
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      for (var day in days) {
        openDays[day] = prefs.getBool('supp_open_$day') ?? true;
        openTimes[day] = prefs.getString('supp_open_time_$day') ?? '09:00';
        closeTimes[day] = prefs.getString('supp_close_time_$day') ?? '18:30';
      }
    });
  }

  Future<void> _saveLocalSupplierTravelSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supp_travel_radius', _radiusController.text);
    await prefs.setString('supp_travel_speed', _speedController.text);
    await prefs.setString('supp_lat', _latController.text);
    await prefs.setString('supp_lng', _lngController.text);
    await prefs.setString('supp_travel_type', _travelType);
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Travel settings updated successfully')),
    );
  }

  Future<void> _saveLocalSupplierOpeningHours() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    for (var day in openDays.keys) {
      await prefs.setBool('supp_open_$day', openDays[day] ?? false);
      await prefs.setString('supp_open_time_$day', openTimes[day] ?? '09:00');
      await prefs.setString('supp_close_time_$day', closeTimes[day] ?? '18:30');
    }
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening hours updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.black87),
              SizedBox(height: 16.h),
              Text(
                "Loading profile...",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48.sp,
                color: Colors.red.shade300,
              ),
              SizedBox(height: 16.h),
              Text(
                "Error: $_errorMessage",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red),
              ),
              SizedBox(height: 24.h),
              _modernButton("Try Again", _fetchProfileData, width: 140.w),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Supplier Profile',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    isScrollable: true,

                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,

                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(Colors.transparent),

                    labelPadding: EdgeInsets.symmetric(horizontal: 10.w),

                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: const Color(0xFF5B3A4A),
                        width: 1,
                      ),
                    ),

                    labelColor: const Color(0xFF3F2A36),
                    unselectedLabelColor: Colors.grey.shade700,

                    labelStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                    ),

                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                    ),

                    tabs: const [
                      Tab(text: "Profile"),
                      Tab(text: "Wallet"),
                      Tab(text: "Subscription"),
                      Tab(text: "Bank Details"),
                      Tab(text: "Documents"),
                      Tab(text: "SMS Packages"),
                      Tab(text: "Taxes"),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                const SizedBox.shrink(), // Wallet navigation placeholder
                _buildSubscriptionTab(),
                _buildBankDetailsTab(),
                _buildDocumentsTab(),
                _buildSmsPackageTab(),
                _buildTaxesTab(),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF432C39),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF432C39).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(true);
                          },
                        ),
                        if (_profile?.profileImage.isNotEmpty == true ||
                            _newProfileImageBase64 != null)
                          ListTile(
                            leading: const Icon(Icons.visibility),
                            title: const Text('View Profile Image'),
                            onTap: () {
                              Navigator.pop(context);
                              _viewMedia(
                                _newProfileImageBase64 ??
                                    _profile?.profileImage,
                                "Profile Image",
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'profile_image',
                child: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: _newProfileImageBase64 != null
                          ? MemoryImage(
                              base64Decode(
                                _newProfileImageBase64!.split(',').last,
                              ),
                            )
                          : (_profile?.profileImage.isNotEmpty == true
                                    ? NetworkImage(_profile!.profileImage)
                                    : const AssetImage(
                                        'assets/images/user.png',
                                      ))
                                as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile?.shopName ?? "GlowVita Supplier",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12.sp,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          "Manage your supplier profile and settings",
                          style: GoogleFonts.inter(
                            fontSize: 9.5.sp,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Supplier ID : ${_profile?.id.substring(0, 8).toUpperCase() ?? "N/A"}",
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PERSONAL INFORMATION
          _modernSectionTitle(
            "Personal Information",
            "Manage your personal and contact details.",
          ),

          SizedBox(height: 18.h),

          Row(
            children: [
              Expanded(
                child: _modernField(
                  "First Name",
                  _firstNameController,
                  hint: "Enter First Name",
                ),
              ),

              SizedBox(width: 12.w),

              Expanded(
                child: _modernField(
                  "Last Name",
                  _lastNameController,
                  hint: "Enter Last Name",
                ),
              ),
            ],
          ),

          _modernField(
            "Email",
            _emailController,
            hint: "Enter Email",
            keyboardType: TextInputType.emailAddress,
            enabled: false,
          ),

          _modernField(
            "Mobile",
            _mobileController,
            hint: "Enter Mobile Number",
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 8.h),

          // BUSINESS INFORMATION
          _modernSectionTitle(
            "Business Information",
            "Manage your business and registration details.",
          ),

          SizedBox(height: 18.h),

          _modernField(
            "Shop Name",
            _shopNameController,
            hint: "Enter Shop Name",
          ),

          _modernField(
            "Description",
            _descriptionController,
            hint: "Enter Description",
            maxLines: 3,
          ),

          _modernField(
            "Minimum Order Value",
            _minOrderValueController,
            hint: "Enter Minimum Order Value",
            keyboardType: TextInputType.number,
          ),

          _modernDropdownField("Supplier Type", [
            "Manufacturer",
            "Distributor",
            "Wholesaler",
          ], _supplierTypeController),

          _modernField(
            "Business Registration No",
            _businessRegNoController,
            hint: "Enter Registration Number",
          ),

          _modernField(
            "GST Number",
            _gstNoController,
            hint: "Enter GST Number",
          ),

          SizedBox(height: 8.h),

          // ADDRESS DETAILS
          _modernSectionTitle(
            "Address Details",
            "Manage your business address information.",
          ),

          SizedBox(height: 18.h),

          _modernField(
            "Street Address",
            _addressController,
            hint: "Enter Street Address",
            maxLines: 2,
          ),

          Row(
            children: [
              Expanded(
                child: _modernField(
                  "City",
                  _cityController,
                  hint: "Enter City",
                ),
              ),

              SizedBox(width: 12.w),

              Expanded(
                child: _modernField(
                  "State",
                  _stateController,
                  hint: "Enter State",
                ),
              ),
            ],
          ),

          _modernField(
            "Pincode",
            _pincodeController,
            hint: "Enter Pincode",
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 22.h),

          Center(
            child: _modernButton(
              "Save Profile Information",
              _saveProfile,
              width: 190.w,
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    if (_isLoading) return _buildLoading();

    final sub = _profile?.subscription;

    if (sub == null) {
      return _buildNoData("No active subscription");
    }

    final startDateStr = sub.startDate != null
        ? DateFormat('MMMM dd, yyyy').format(sub.startDate!)
        : "N/A";

    final endDateStr = sub.endDate != null
        ? DateFormat('MMMM dd, yyyy').format(sub.endDate!)
        : "N/A";

    final totalDays =
        (sub.endDate?.difference(sub.startDate ?? DateTime.now()).inDays ??
            29) +
        1;

    final daysRemaining =
        (sub.endDate?.difference(DateTime.now()).inDays ?? 0) + 1;

    final progress = totalDays > 1
        ? (1 - (daysRemaining / totalDays)).clamp(0.0, 1.0)
        : 1.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subscription",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            "Details about your current plan and billing.",
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 12.h),

          // MAIN CARD
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE9F6),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPlanName(sub.plan),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        Text(
                          "Expires on $endDateStr",
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // STATUS BADGE
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6F5D6),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          Text(
                            sub.status,
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // DATE ROW
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "START DATE",
                            style: GoogleFonts.inter(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),

                          SizedBox(height: 3.h),

                          Text(
                            startDateStr,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "END DATE",
                            style: GoogleFonts.inter(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),

                          SizedBox(height: 3.h),

                          Text(
                            endDateStr,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // DAYS REMAINING
                Text(
                  "$daysRemaining Days Remaining",
                  style: GoogleFonts.inter(
                    fontSize: 7.sp,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 6.h),

                // PROGRESS BAR
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Stack(
                    children: [
                      Container(
                        height: 6.h,
                        width: double.infinity,
                        color: const Color(0xFFD7CFF8),
                      ),

                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B2637),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // CHANGE PLAN BUTTON
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ChangePlanDialog(
                    currentPlanName: sub.plan,
                    onPlanChanged: () {
                      _fetchProfileData();
                    },
                    email: _profile?.email,
                    phone: _profile?.mobile,
                  ),
                );
              },
              icon: Icon(Icons.sync_rounded, size: 14.sp, color: Colors.white),
              label: Text(
                "Change Plan",
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B2637),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // VIEW HISTORY BUTTON
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _fetchProfileData();

                if (mounted && _profile?.subscription != null) {
                  showDialog(
                    context: context,
                    builder: (context) => _SubscriptionHistoryDialog(
                      history: _profile?.subscription?.history ?? [],
                      planIdToName: _planIdToName,
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.history_rounded,
                size: 14.sp,
                color: Colors.black87,
              ),
              label: Text(
                "View History",
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanName(String? planId) {
    if (planId == null || planId.isEmpty) return "N/A";
    if (_planIdToName.containsKey(planId)) return _planIdToName[planId]!;
    return planId;
  }

  Widget _buildSubDetailItem(
    String title,
    String value, {
    bool isStatus = false,
    Color? statusColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 4.h),
        if (isStatus)
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: statusColor ?? Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() => Center(
    child: Padding(
      padding: EdgeInsets.all(40.w),
      child: const CircularProgressIndicator(color: Colors.black87),
    ),
  );

  Widget _buildBankDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modernSectionTitle(
            "Bank Details",
            "Manage your bank account for payouts.",
          ),

          SizedBox(height: 18.h),

          _modernField(
            "Account Holder Name",
            _accountHolderController,
            hint: "Enter Account Holder Name",
          ),

          _modernField(
            "Account Number",
            _accountNumberController,
            hint: "Enter Account Number",
            keyboardType: TextInputType.number,
          ),

          _modernField(
            "Bank Name",
            _bankNameController,
            hint: "Enter Bank Name",
          ),

          // ───────────────── IFSC CODE ─────────────────
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "IFSC Code",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 6.h),

                TextField(
                  controller: _ifscCodeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(11),
                  ],
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter IFSC Code",

                    hintStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.grey.shade500,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 11.h,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: Colors.grey.shade500,
                        width: 0.8,
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: Colors.grey.shade500,
                        width: 0.8,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF4B2D3B),
                        width: 1,
                      ),
                    ),

                    errorText:
                        _ifscCodeController.text.isNotEmpty &&
                            !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(
                              _ifscCodeController.text.trim().toUpperCase(),
                            )
                        ? "Enter valid IFSC Code"
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _ifscCodeController.text = value.toUpperCase();

                      _ifscCodeController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: _ifscCodeController.text.length),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // ───────────────── UPI ─────────────────
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "UPI ID",
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(width: 4.w),

                    Text(
                      "(Optional)",
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 6.h),

                _modernInput(
                  controller: _upiIdController,
                  hint: "Enter UPI ID (e.g., yourname@upi)",
                ),
              ],
            ),
          ),

          SizedBox(height: 22.h),

          Center(
            child: _modernButton("Update Bank Details", () {
              final accountHolder = _accountHolderController.text.trim();
              if (accountHolder.isEmpty ||
                  !RegExp(r'^[A-Za-z\s]+$').hasMatch(accountHolder)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Account holder name must contain only alphabets and spaces.',
                    ),
                  ),
                );
                return;
              }

              final bankName = _bankNameController.text.trim();
              if (bankName.isEmpty ||
                  !RegExp(r'^[A-Za-z\s]+$').hasMatch(bankName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bank name must contain only alphabets and spaces.',
                    ),
                  ),
                );
                return;
              }

              final ifsc = _ifscCodeController.text.trim().toUpperCase();

              final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

              if (!ifscRegex.hasMatch(ifsc)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please enter a valid IFSC Code",
                      style: GoogleFonts.inter(),
                    ),
                  ),
                );
                return;
              }

              _saveBankDetails();
            }, width: 170.w),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final docs = _profile?.documents;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modernSectionTitle(
            "Verification Documents",
            "Manage your uploaded business document",
          ),
          SizedBox(height: 20.h),
          _buildDocRow("Aadhar Card", "aadharCard", docs?.aadharCard),
          _buildDocRow("PAN Card", "panCard", docs?.panCard),
          _buildDocRow("Shop Act", "shopAct", docs?.shopAct),
          _buildDocRow("Udyam Certificate", "udhayamCert", docs?.udhayamCert),
          _buildDocRow("Shop License", "shopLicense", docs?.shopLicense),
          SizedBox(height: 32.h),
          _modernButton("Save Documents", _saveDocuments),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSmsPackageTab() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.black87),
      );
    final balance = _profile?.currentSmsBalance ?? 0;

    // Formatting currency and numbers
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final NumberFormat numberFormatter = NumberFormat.decimalPattern('en_IN');

    // Dynamic Package Mapping
    Map<String, dynamic>? matchingPackage;
    DateTime purchaseDate = DateTime.now().subtract(const Duration(days: 5));
    DateTime? expiryDate;

    if (balance > 0) {
      if (_smsPackages.isNotEmpty) {
        for (var package in _smsPackages) {
          if (package['smsCount'] == balance) {
            matchingPackage = Map<String, dynamic>.from(package);
            break;
          }
        }
        if (matchingPackage == null) {
          matchingPackage = {
            'name': 'Starter SMS Package',
            'smsCount': balance,
            'price': (balance * 0.5).toInt(),
            'validityDays': 30,
          };
        }
      } else {
        matchingPackage = {
          'name': 'Starter SMS Package',
          'smsCount': balance,
          'price': (balance * 0.5).toInt(),
          'validityDays': 30,
        };
      }
      int validity = matchingPackage['validityDays'] ?? 30;
      expiryDate = purchaseDate.add(Duration(days: validity));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Subtitle block
          Text(
            "SMS Packages",
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Manage your SMS credits and purchase history",
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20.h),

          // Active Package Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF2EFF4,
              ), // Premium light lavender/grey background
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active Package SMS Count",
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "${numberFormatter.format(balance)} SMS",
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Speech bubble icon container
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 26.sp,
                    color: const Color(
                      0xFF6B4B9C,
                    ), // Premium primary color theme
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // Purchase History Table Title
          Text(
            "Purchase History",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),

          // Horizontal scrollable table container
          balance > 0 && matchingPackage != null
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: DataTable(
                      horizontalMargin: 8.w,
                      columnSpacing: 24.w,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade50,
                      ),
                      headingRowHeight: 40.h,
                      dataRowHeight: 48.h,
                      columns: [
                        DataColumn(
                          label: Text(
                            "Package",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "SMS Count",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Price",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Purchase Date",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Expiry Date",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Status",
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                matchingPackage['name'] ?? 'N/A',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 11.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    numberFormatter.format(
                                      matchingPackage['smsCount'],
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                currencyFormatter.format(
                                  matchingPackage['price'],
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat('dd MMM yyyy').format(purchaseDate),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(expiryDate!),
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE8F5E9,
                                  ), // Premium light green background
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 10.sp,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      "Active",
                                      style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 36.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 32.sp,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "No purchases found",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Any purchases you make will show up here.",
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
          SizedBox(height: 36.h),
        ],
      ),
    );
  }

  Widget _buildTaxesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modernSectionTitle(
            "Tax & Billing",
            "Update your tax and billing information",
          ),
          SizedBox(height: 16.h),
          _modernDropdownField(
            "Tax Type",
            ["percentage", "fixed"],
            null, // Using custom logic for this field
            initialValue: _profile?.taxes?.taxType ?? "percentage",
            onChanged: (val) {
              final double value =
                  double.tryParse(_taxValueController.text) ?? 0.0;
              _updateTax(val!, value);
            },
          ),
          _modernField(
            "Tax Value",
            _taxValueController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 32.h),
          _modernButton("Update Tax Settings", () {
            final double value =
                double.tryParse(_taxValueController.text) ?? 0.0;
            final type = _profile?.taxes?.taxType ?? "percentage";
            _updateTax(type, value);
          }),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  final _taxValueController = TextEditingController();

  Future<void> _updateTax(String type, double value) async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        'taxes': {'taxType': type, 'taxValue': value},
      };
      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tax settings updated successfully")),
      );
      _fetchProfileData();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Update failed")), // Check console
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────
  //  Helper Widgets
  // ──────────────────────────────────────────────

  Widget _modernSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 2.h),

        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // MODERN FIELD
  // ──────────────────────────────────────────────
  Widget _modernField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 6.h),

          _modernInput(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: enabled,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MODERN INPUT
  // ──────────────────────────────────────────────
  Widget _modernInput({
    TextEditingController? controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 9.sp,
          color: Colors.grey.shade500,
        ),

        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,

        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 0.8),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 0.8),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF4B2D3B), width: 1),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MODERN DROPDOWN
  // ──────────────────────────────────────────────
  Widget _modernDropdownField(
    String label,
    List<String> items,
    TextEditingController? controller, {
    String? initialValue,
    Function(String?)? onChanged,
  }) {
    String? currentValue = initialValue ?? controller?.text;

    if (currentValue != null && !items.contains(currentValue)) {
      currentValue = items.first;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 6.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade500, width: 0.8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,

                hint: Text(
                  "Select Option",
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.grey.shade500,
                  ),
                ),

                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18.sp,
                  color: Colors.black87,
                ),

                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.black87,
                ),

                items: items.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),

                onChanged: (value) {
                  if (controller != null) {
                    controller.text = value ?? "";
                  }

                  if (onChanged != null) {
                    onChanged(value);
                  }

                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MODERN BUTTON
  // ──────────────────────────────────────────────
  Widget _modernButton(String text, VoidCallback onTap, {double? width}) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 36.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4B2D3B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDocRow(String label, String key, String? path) {
    final bool isUploaded = path != null && path.isNotEmpty;
    final bool isNew = _newDocumentsBase64.containsKey(key);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: (isUploaded || isNew)
                    ? Colors.blue.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                isUploaded || isNew ? Icons.description : Icons.upload_file,
                size: 20.sp,
                color: (isUploaded || isNew) ? Colors.blue : Colors.grey,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isNew
                        ? "New file selected"
                        : (isUploaded ? "Uploaded" : "No document uploaded"),
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: (isUploaded || isNew)
                          ? Colors.green
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploaded || isNew)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 18.sp,
                    color: Colors.blue,
                  ),
                  onPressed: () => _viewMedia(
                    isNew ? _newDocumentsBase64[key] : path,
                    label,
                  ),
                ),
              ),
            _circleButton(
              Icons.cloud_upload_outlined,
              () => _pickDocument(key),
              size: 32.w,
              iconSize: 16.sp,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    double? size,
    double? iconSize,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size ?? 28.w,
        height: size ?? 28.w,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize ?? 14.sp,
          color: color == Colors.black87 ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Future<void> _viewMedia(String? path, String title) async {
    if (path == null || path.isEmpty) return;

    String mediaPath = path.trim();
    if (mediaPath.startsWith('JVBER')) {
      mediaPath = 'data:application/pdf;base64,' + mediaPath;
    } else if (mediaPath.startsWith('iVBORw0KGgo')) {
      mediaPath = 'data:image/png;base64,' + mediaPath;
    } else if (mediaPath.startsWith('/9j/')) {
      mediaPath = 'data:image/jpeg;base64,' + mediaPath;
    }

    if (mediaPath.startsWith('data:image')) {
      _showImageViewer(mediaPath, title);
    } else if (mediaPath.startsWith('http')) {
      _showImageViewer(mediaPath, title);
    } else if (mediaPath.startsWith('data:application/pdf')) {
      try {
        final base64Str = mediaPath.split(',').last;
        final bytes = base64Decode(base64Str);
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(bytes);
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF file')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
      }
    } else {
      try {
        final uri = Uri.parse(mediaPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot preview this file type directly"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening media: $e')));
      }
    }
  }

  void _showImageViewer(String path, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: path.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(path.split(',').last),
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      path,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 32.sp, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => 58.h;

  @override
  double get maxExtent => 58.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E7EF),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300, width: 0.6),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// ──────────────────────────────────────────────
//  Change Plan Dialog (Internal)
// ──────────────────────────────────────────────
class ChangePlanDialog extends StatefulWidget {
  final String? currentPlanName;
  final VoidCallback onPlanChanged;
  final String? email;
  final String? phone;

  const ChangePlanDialog({
    this.currentPlanName,
    required this.onPlanChanged,
    this.email,
    this.phone,
  });

  @override
  State<ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<ChangePlanDialog> {
  List<Plan> _plans = [];
  bool _isLoading = true;
  String? _selectedPlanId;
  bool _isSaving = false;
  late RazorpayService _razorpayService;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _fetchPlans();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await ApiService.getSubscriptionPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
        if (widget.currentPlanName != null) {
          final match = _plans
              .where((p) => p.name == widget.currentPlanName)
              .toList();
          if (match.isNotEmpty) {
            _selectedPlanId = match.first.id;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching plans: $e")));
      }
    }
  }

  Future<void> _handleRenew() async {
    if (_selectedPlanId == null) return;

    final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);
    final amount =
        (selectedPlan.discountedPrice > 0 &&
            selectedPlan.discountedPrice < selectedPlan.price)
        ? selectedPlan.discountedPrice
        : selectedPlan.price;

    setState(() => _isSaving = true);

    _razorpayService.onSuccess = (PaymentSuccessResponse response) async {
      try {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Verifying payment...")));
        }

        final success = await ApiService.renewSubscription(
          planId: selectedPlan.id,
          userType: 'supplier',
          amount: amount.toInt(),
          paymentId: response.paymentId,
        );

        if (success && mounted) {
          widget.onPlanChanged();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription updated successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to verify payment: $e")),
          );
        }
      }
    };

    _razorpayService.onFailure = (PaymentFailureResponse response) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${response.message}")),
        );
      }
    };

    try {
      _razorpayService.openCheckout(
        amount: amount.toDouble(),
        contact: widget.phone ?? '',
        email: widget.email ?? '',
        description: 'Subscription for ${selectedPlan.name}',
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening checkout: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 12.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Plan',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Choose a plan that best suits your needs',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 18.sp, color: Colors.black87),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.grey.shade50,
            constraints: BoxConstraints(maxHeight: 380.h),
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black87),
                  )
                : _plans.isEmpty
                ? Center(
                    child: Text(
                      "No plans available",
                      style: GoogleFonts.inter(fontSize: 10.sp),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    itemCount: _plans.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final isSelected = _selectedPlanId == plan.id;
                      final hasDiscount =
                          plan.discountedPrice > 0 &&
                          plan.discountedPrice < plan.price;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedPlanId = plan.id),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFDF7FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF9E8DA5)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                plan.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "${plan.duration} ${plan.durationType}",
                                style: GoogleFonts.inter(
                                  fontSize: 8.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              if (hasDiscount)
                                Text(
                                  "₹${plan.price}",
                                  style: GoogleFonts.inter(
                                    fontSize: 8.sp,
                                    color: Colors.grey.shade400,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "₹",
                                    style: GoogleFonts.inter(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    (hasDiscount
                                            ? plan.discountedPrice
                                            : plan.price)
                                        .toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                width: 16.w,
                                height: 16.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF432C39)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF432C39)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 10.sp,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: ElevatedButton(
              onPressed: (_isSaving || _selectedPlanId == null)
                  ? null
                  : _handleRenew,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF432C39),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Update Plan",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Subscription History Dialog
// ──────────────────────────────────────────────
class _SubscriptionHistoryDialog extends StatelessWidget {
  final List<SupplierSubscriptionHistory> history;
  final Map<String, String> planIdToName;

  const _SubscriptionHistoryDialog({
    required this.history,
    required this.planIdToName,
  });

  @override
  Widget build(BuildContext context) {
    // Sort history to show latest first if not already sorted
    final sortedHistory = List<SupplierSubscriptionHistory>.from(history)
      ..sort(
        (a, b) =>
            (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)),
      );

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription History',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Your complete subscription payment history',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 18.sp, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(height: 1, color: Color(0xFFF2F2F2)),
            SizedBox(height: 16.h),

            // History Container (Table)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  // Table Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _headerCell("Date")),
                        Expanded(flex: 2, child: _headerCell("Plan")),
                        Expanded(flex: 2, child: _headerCell("Payment Mode")),
                        Expanded(flex: 2, child: _headerCell("Duration")),
                        Expanded(
                          flex: 2,
                          child: _headerCell("Status", align: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                  // Data List
                  Container(
                    color: Colors.white,
                    child: sortedHistory.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(40.w),
                            child: Center(
                              child: Text(
                                "No history records found",
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: sortedHistory.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final item = entry.value;
                              final isLast = index == sortedHistory.length - 1;
                              final isCurrent = index == 0; // Latest one

                              return Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 14.h,
                                    ),
                                    child: Row(
                                      children: [
                                        // Date Column
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.startDate != null
                                                    ? DateFormat(
                                                        'MMM d, yyyy',
                                                      ).format(item.startDate!)
                                                    : "N/A",
                                                style: GoogleFonts.inter(
                                                  fontSize: 8.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF2D2D2D,
                                                  ),
                                                ),
                                              ),
                                              if (item.startDate != null)
                                                Text(
                                                  DateFormat(
                                                    'hh:mm a',
                                                  ).format(item.startDate!),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8.sp,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Plan Column
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getPlanName(item.plan),
                                                style: GoogleFonts.inter(
                                                  fontSize: 8.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF2D2D2D,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Paid Plan",
                                                style: GoogleFonts.inter(
                                                  fontSize: 7.sp,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Payment Mode
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            item.paymentMode ?? "Online",
                                            style: GoogleFonts.inter(
                                              fontSize: 8.sp,
                                              color: const Color(0xFF4B4B4B),
                                            ),
                                          ),
                                        ),

                                        // Duration
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _calculateDuration(
                                              item.startDate,
                                              item.endDate,
                                            ),
                                            style: GoogleFonts.inter(
                                              fontSize: 8.sp,
                                              color: const Color(0xFF4B4B4B),
                                            ),
                                          ),
                                        ),

                                        // Status
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _statusBadge(
                                              item.status,
                                              isCurrent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFF2F2F2),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Footer Button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  "Close",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 7.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4B4B4B),
      ),
    );
  }

  Widget _statusBadge(String status, bool isLatest) {
    final String label = (isLatest && status.toLowerCase() == 'active')
        ? "Active • Current"
        : status;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 6.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF10B981),
        ),
      ),
    );
  }

  String _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "N/A";
    final diff = end.difference(start).inDays;
    return "$diff days";
  }

  String _getPlanName(String planId) {
    if (planId.isEmpty) return "N/A";
    if (planIdToName.containsKey(planId)) return planIdToName[planId]!;
    return planId;
  }
}
