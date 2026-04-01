import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../supplier_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
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
        }
      };

      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details updated successfully')),
      );
      _fetchProfileData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
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
        }
      };

      await ApiService.updateSupplierProfile(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents updated successfully')),
      );
      _newDocumentsBase64.clear();
      _fetchProfileData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style:
              GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black87))
          : Stack(
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
                              fontSize: 11.sp, fontWeight: FontWeight.w600),
                          unselectedLabelStyle:
                              GoogleFonts.inter(fontSize: 11.sp),
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
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.black)),
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
                onTap: () => _pickImage(true),
                child: CircleAvatar(
                  radius: 40.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _newProfileImageBase64 != null
                      ? MemoryImage(
                          base64Decode(_newProfileImageBase64!.split(',').last))
                      : (_profile?.profileImage.isNotEmpty == true
                          ? NetworkImage(_profile!.profileImage)
                          : null),
                  child: (_newProfileImageBase64 == null &&
                          (_profile?.profileImage.isEmpty == true))
                      ? Icon(Icons.person, size: 40.sp, color: Colors.grey)
                      : null,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_profile?.shopName ?? "N/A",
                        style: GoogleFonts.inter(
                            fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14.sp, color: Colors.grey.shade600),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(_profile?.address ?? "N/A",
                              style: GoogleFonts.inter(
                                  fontSize: 10.5.sp,
                                  color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                        "Supplier ID • ${_profile?.id.substring(0, 8) ?? "N/A"}",
                        style: GoogleFonts.inter(
                            fontSize: 9.5.sp, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            "Manage your supplier profile and settings",
            style:
                GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade500),
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
          Text("Basic Information",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(child: _buildField("First Name", _firstNameController)),
              SizedBox(width: 16.w),
              Expanded(child: _buildField("Last Name", _lastNameController)),
            ],
          ),
          _buildField("Shop Name", _shopNameController),
          _buildField("Description", _descriptionController, maxLines: 3),
          _buildField("Minimum Order Value", _minOrderValueController,
              keyboardType: TextInputType.number),
          _buildField("Email", _emailController,
              keyboardType: TextInputType.emailAddress),
          _buildField("Mobile", _mobileController,
              keyboardType: TextInputType.phone),
          _buildField("Supplier Type", _supplierTypeController),
          _buildField("Business Registration Number", _businessRegNoController),
          _buildField("GST Number", _gstNoController),
          _buildField("Full Address", _addressController, maxLines: 2),
          Row(
            children: [
              Expanded(child: _buildField("City", _cityController)),
              SizedBox(width: 16.w),
              Expanded(child: _buildField("State", _stateController)),
            ],
          ),
          _buildField("Pincode", _pincodeController,
              keyboardType: TextInputType.number),
          SizedBox(height: 24.h),
          _buildButton("Save Changes", _saveProfile),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    final sub = _profile?.subscription;
    if (sub == null) return _buildNoData("No subscription information");

    final startDateStr = sub.startDate != null
        ? DateFormat('dd MMM yyyy').format(sub.startDate!)
        : "N/A";
    final endDateStr = sub.endDate != null
        ? DateFormat('dd MMM yyyy').format(sub.endDate!)
        : "N/A";

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Subscription",
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, fontWeight: FontWeight.w700)),
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
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _buildInfoRow("Plan ID", sub.plan ?? "N/A"),
                _buildInfoRow("Start Date", startDateStr),
                _buildInfoRow("End Date", endDateStr),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text("Subscription History",
              style: GoogleFonts.inter(
                  fontSize: 11.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          if (sub.history.isEmpty)
            _buildNoData("No history records found")
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sub.history.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final h = sub.history[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.plan,
                                style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700)),
                            Text(
                              "${h.startDate != null ? DateFormat('dd MMM yyyy').format(h.startDate!) : ''} - ${h.endDate != null ? DateFormat('dd MMM yyyy').format(h.endDate!) : ''}",
                              style: GoogleFonts.inter(
                                  fontSize: 8.sp, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                            color: h.status.toLowerCase() == 'active'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4.r)),
                        child: Text(h.status,
                            style: GoogleFonts.inter(
                                fontSize: 8.sp,
                                color: h.status.toLowerCase() == 'active'
                                    ? Colors.green
                                    : Colors.red)),
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    final gallery = _profile?.gallery ?? [];
    final allGallery = [...gallery, ..._newGalleryBase64];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Photo Gallery",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Showcase your products and shop to vendors.",
              style: GoogleFonts.inter(
                  fontSize: 10.sp, color: Colors.grey.shade500)),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () => _pickImage(false),
            child: Container(
              height: 140.h,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 36.sp, color: Colors.grey),
                  SizedBox(height: 8.h),
                  Text("Upload images here",
                      style: GoogleFonts.inter(
                          fontSize: 10.sp, color: Colors.grey.shade600))
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          if (allGallery.isEmpty)
            _buildNoData("No gallery images yet")
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
                final isNew = index >= gallery.length;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: isNew
                              ? MemoryImage(base64Decode(img.split(',').last))
                              : NetworkImage(img) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isNew) {
                              _newGalleryBase64
                                  .removeAt(index - gallery.length);
                            } else {
                              gallery.removeAt(index);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.delete_outline,
                              size: 14.sp, color: Colors.red),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          if (_newGalleryBase64.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _buildButton("Save Gallery Changes", () async {
              // Implement gallery save if needed, for now just local update
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gallery saved successfully")));
              setState(() => _newGalleryBase64.clear());
            })
          ]
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
          Text("Banking Information",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          _buildField("Account Holder Name", _accountHolderController),
          _buildField("Account Number", _accountNumberController,
              keyboardType: TextInputType.number),
          _buildField("Bank Name", _bankNameController),
          _buildField("IFSC Code", _ifscCodeController),
          _buildField("UPI ID (Optional)", _upiIdController),
          SizedBox(height: 24.h),
          _buildButton("Update Bank Details", _saveBankDetails),
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
          Text("Verification Documents",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Upload documents for account verification.",
              style: GoogleFonts.inter(
                  fontSize: 10.sp, color: Colors.grey.shade500)),
          SizedBox(height: 24.h),
          _buildDocCard("Aadhar Card", "aadharCard", docs?.aadharCard),
          _buildDocCard("PAN Card", "panCard", docs?.panCard),
          _buildDocCard("Udyam Certificate", "udhayamCert", docs?.udhayamCert),
          _buildDocCard("Shop Act", "shopAct", docs?.shopAct),
          SizedBox(height: 24.h),
          _buildButton("Save Documents", _saveDocuments),
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
          Text("SMS Package Management",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6B4EE6), Color(0xFF9E8DA5)]),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Balance",
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: Colors.white70)),
                    Text("${_profile?.currentSmsBalance ?? 0} SMS",
                        style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const Icon(Icons.message_outlined,
                    color: Colors.white54, size: 40),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text("Recharge History",
              style: GoogleFonts.inter(
                  fontSize: 11.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          _buildNoData("No recharge history found"),
        ],
      ),
    );
  }

  Widget _buildTaxesTab() {
    final taxes = _profile?.taxes;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tax & Billing",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                    "Current Tax Type", taxes?.taxType ?? "Percentage"),
                const Divider(),
                _buildInfoRow("Current Tax Rate", "${taxes?.taxValue ?? 0}%"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          SizedBox(height: 6.h),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black87),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10.sp, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDocCard(String label, String key, String? url) {
    final isNew = _newDocumentsBase64.containsKey(key);
    final hasDoc = isNew || (url != null && url.isNotEmpty);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.file_present_outlined,
              color: Colors.grey.shade600, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10.5.sp, fontWeight: FontWeight.w500))),
          if (hasDoc) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            SizedBox(width: 8.w),
            TextButton(
              onPressed: () => _pickDocument(key),
              child: Text("Replace",
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
          ] else
            TextButton(
              onPressed: () => _pickDocument(key),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text("Upload",
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  Widget _buildNoData(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade300, size: 40.sp),
            SizedBox(height: 12.h),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 10.sp, color: Colors.grey.shade500)),
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
