import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';
import '../vendor_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
      final payload = {
        'bankDetails': {
          'accountHolder': _accountHolderController.text,
          'accountNumber': _accountNumberController.text,
          'bankName': _bankNameController.text,
          'ifscCode': _ifscCodeController.text,
          'upiId': _upiIdController.text,
        },
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
    super.dispose();
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
              _buildButton("Try Again", _fetchProfileData, width: 140.w),
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
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.black87,
                    indicatorWeight: 2.4,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    tabs: const [
                      Tab(text: "Profile"),
                      Tab(text: "Subscription"),
                      Tab(text: "Gallery"),
                      Tab(text: "Bank Details"),
                      Tab(text: "Documents"),
                      Tab(text: "SMS Package"),
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
                _buildSubscriptionTab(),
                _buildGalleryTab(),
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
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            _profile?.address ?? "Location not set",
                            style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Supplier ID • ${_profile?.id.substring(0, 8).toUpperCase() ?? "N/A"}",
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Personal Information"),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildField("First Name", _firstNameController)),
              SizedBox(width: 16.w),
              Expanded(child: _buildField("Last Name", _lastNameController)),
            ],
          ),
          _buildField(
            "Email",
            _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: false,
          ),
          _buildField(
            "Mobile",
            _mobileController,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24.h),
          _sectionTitle("Business Information"),
          SizedBox(height: 16.h),
          _buildField("Shop Name", _shopNameController),
          _buildField("Description", _descriptionController, maxLines: 3),
          _buildField(
            "Minimum Order Value",
            _minOrderValueController,
            keyboardType: TextInputType.number,
          ),
          _buildDropdownField("Supplier Type", [
            "Manufacturer",
            "Distributor",
            "Wholesaler",
          ], _supplierTypeController),
          _buildField("Business Registration No", _businessRegNoController),
          _buildField("GST Number", _gstNoController),
          SizedBox(height: 24.h),
          _sectionTitle("Address Details"),
          SizedBox(height: 16.h),
          _buildField("Street Address", _addressController, maxLines: 2),
          Row(
            children: [
              Expanded(child: _buildField("City", _cityController)),
              SizedBox(width: 16.w),
              Expanded(child: _buildField("State", _stateController)),
            ],
          ),
          _buildField(
            "Pincode",
            _pincodeController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 32.h),
          _buildButton("Save Profile Information", _saveProfile),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    if (_isLoading) return _buildLoading();
    final sub = _profile?.subscription;
    if (sub == null) return _buildNoData("No active subscription");

    final startDateStr = sub.startDate != null
        ? DateFormat('dd MMM yyyy').format(sub.startDate!)
        : "N/A";
    final endDateStr = sub.endDate != null
        ? DateFormat('dd MMM yyyy').format(sub.endDate!)
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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Subscription",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: sub.status.toLowerCase() == 'active'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  sub.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: sub.status.toLowerCase() == 'active'
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubDetailItem(
                      "Plan Name",
                      _getPlanName(sub.plan),
                      isBold: true,
                    ),
                    _buildSubDetailItem(
                      "Days Remaining",
                      "$daysRemaining days left",
                      isBold: true,
                      statusColor: Colors.purple.shade700,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubDetailItem("Start Date", startDateStr),
                    _buildSubDetailItem("End Date", endDateStr),
                  ],
                ),
                SizedBox(height: 20.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Subscription Progress",
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "$daysRemaining days left",
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6.h,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.8
                              ? Colors.orange
                              : const Color(0xFF432C39),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
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
                        icon: Icon(
                          Icons.sync_rounded,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        label: Text(
                          "Change Plan",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF432C39),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
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
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildGalleryTab() {
    final gallery = _profile?.gallery ?? [];
    final allGallery = [...gallery, ..._newGalleryBase64];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Photo Gallery"),
          SizedBox(height: 4.h),
          Text(
            "Manage your business and product showcase photos.",
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () => _pickImage(false),
            child: Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32.sp,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Add New Photo",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          if (allGallery.isEmpty)
            _buildNoData("Your gallery is empty")
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 1,
              ),
              itemCount: allGallery.length,
              itemBuilder: (context, index) {
                final img = allGallery[index];
                final bool isNew = index >= gallery.length;

                return GestureDetector(
                  onTap: () => _viewMedia(img, "Gallery Image"),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          image: DecorationImage(
                            image: isNew
                                ? MemoryImage(base64Decode(img.split(',').last))
                                : NetworkImage(img) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isNew) {
                                _newGalleryBase64.removeAt(
                                  index - gallery.length,
                                );
                              } else {
                                gallery.removeAt(index);
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14.sp,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      if (isNew)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              "New",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 8.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (_newGalleryBase64.isNotEmpty ||
              gallery.length != (_profile?.gallery.length ?? 0)) ...[
            SizedBox(height: 32.h),
            _buildButton("Update Gallery", _saveGallery),
          ],
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildBankDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Banking Information"),
          SizedBox(height: 16.h),
          _buildField("Account Holder Name", _accountHolderController),
          _buildField(
            "Account Number",
            _accountNumberController,
            keyboardType: TextInputType.number,
          ),
          _buildField("Bank Name", _bankNameController),
          _buildField("IFSC Code", _ifscCodeController),
          _buildField("UPI ID", _upiIdController),
          SizedBox(height: 32.h),
          _buildButton("Update Bank Details", _saveBankDetails),
          SizedBox(height: 32.h),
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
          _sectionTitle("Verification Documents"),
          SizedBox(height: 4.h),
          Text(
            "Manage your uploaded business documents.",
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 20.h),
          _buildDocRow("Aadhar Card", "aadharCard", docs?.aadharCard),
          _buildDocRow("PAN Card", "panCard", docs?.panCard),
          _buildDocRow("Shop Act", "shopAct", docs?.shopAct),
          _buildDocRow("Udyam Certificate", "udhayamCert", docs?.udhayamCert),
          _buildDocRow("Shop License", "shopLicense", docs?.shopLicense),
          SizedBox(height: 32.h),
          _buildButton("Save Documents", _saveDocuments),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSmsPackageTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("SMS Management"),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D2D), Color(0xFF4D4D4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Balance",
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${_profile?.currentSmsBalance ?? 0} SMS",
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.message_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          _sectionTitle("Transaction History"),
          SizedBox(height: 16.h),
          _buildNoData("No SMS recharge history found"),
          SizedBox(height: 32.h),
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
          _sectionTitle("Tax & Billing"),
          SizedBox(height: 16.h),
          _buildDropdownField(
            "Tax Type",
            ["percentage", "fixed value"],
            null, // Using custom logic for this field
            initialValue: _profile?.taxes?.taxType ?? "percentage",
            onChanged: (val) {
              final double value =
                  double.tryParse(_taxValueController.text) ?? 0.0;
              _updateTax(val!, value);
            },
          ),
          _buildField(
            "Tax Value",
            _taxValueController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 32.h),
          _buildButton("Update Tax Settings", () {
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
        const SnackBar(
          content: Text("Error: Update failed. Check console for details."),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveGallery() async {
    if (_profile == null) return;
    setState(() => _isSaving = true);
    try {
      final payload = {
        'gallery': [...(_profile!.gallery), ..._newGalleryBase64],
      };
      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery updated successfully")),
      );
      _newGalleryBase64.clear();
      _fetchProfileData();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Update failed. Check console for details."),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────
  //  Helper Widgets
  // ──────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: enabled,
            style: GoogleFonts.inter(fontSize: 11.5.sp),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: Colors.grey.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    TextEditingController? controller, {
    String? initialValue,
    Function(String?)? onChanged,
  }) {
    String? currentVal = initialValue ?? controller?.text;
    if (currentVal != null && !items.contains(currentVal)) {
      currentVal = items.first;
      if (controller != null) controller.text = items.first;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentVal,
                isExpanded: true,
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  color: Colors.black87,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                ),
                onChanged: (val) {
                  if (controller != null) controller.text = val!;
                  if (onChanged != null) onChanged(val);
                },
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed, {double? width}) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
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

    if (path.startsWith('data:image')) {
      _showImageViewer(path, title);
    } else if (path.startsWith('http')) {
      _showImageViewer(path, title);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot preview this file type directly")),
      );
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
  _SliverTabBarDelegate({required this.tabBar});
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
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
    final amount = (selectedPlan.discountedPrice > 0 &&
            selectedPlan.discountedPrice < selectedPlan.price)
        ? selectedPlan.discountedPrice
        : selectedPlan.price;

    setState(() => _isSaving = true);

    _razorpayService.onSuccess = (PaymentSuccessResponse response) async {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Verifying payment...")),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening checkout: $e")),
      );
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
