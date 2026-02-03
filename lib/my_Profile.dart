import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class My_Profile extends StatefulWidget {
  const My_Profile({super.key});

  @override
  State<My_Profile> createState() => _My_ProfileState();
}

class _My_ProfileState extends State<My_Profile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VendorProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _showProfileOptions = false;

  // Profile tab controllers
  final _salonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _profileImageController = TextEditingController();

  // Bank details controllers
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderController = TextEditingController();

  String _selectedCategory = "unisex";
  bool _atSalon = true;
  bool _atHome = true;
  bool _customLocation = false;

  // Travel settings
  String _vendorType = "Shop Only (No travel)";
  final _radiusController = TextEditingController();
  final _speedController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // Opening hours
  Map<String, bool> openDays = {};
  Map<String, String> openTimes = {};
  Map<String, String> closeTimes = {};

  // Upload states
  String? _newProfileImageBase64;
  List<String> _newGalleryBase64 = [];
  Map<String, String?> _newDocumentsBase64 = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final profile = await ApiService.getVendorProfile();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_profile == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Map subCategories
      List<String> subCategories = [];
      if (_atSalon) subCategories.add('at-salon');
      if (_atHome) subCategories.add('at-home');

      // 2. Map vendorType back to API value
      String vendorTypeApi = 'shop-only';
      switch (_vendorType) {
        case "Shop Only (No travel)":
          vendorTypeApi = 'shop-only';
          break;
        case "Home Only":
          vendorTypeApi = 'home-only';
          break;
        case "Onsite Only":
          vendorTypeApi = 'onsite-only';
          break;
        case "Hybrid (Shop + Home Service)":
          vendorTypeApi = 'hybrid';
          break;
        case "Vendor Home Service":
          vendorTypeApi = 'vendor-home-service';
          break;
      }

      // 3. Update opening hours in the profile object before sending
      final updatedOpeningHours = openDays.keys.map((day) {
        return OpeningHour(
          day: day,
          open: openTimes[day] ?? "09:00",
          close: closeTimes[day] ?? "18:30",
          isOpen: openDays[day] ?? false,
        );
      }).toList();

      // 4. Construct payload
      final payload = _profile!.toJson();

      // Handle gallery (preserved URLs + new base64)
      payload['gallery'] = [...(_profile?.gallery ?? []), ..._newGalleryBase64];

      // Handle Profile Image (new base64 if picked)
      if (_newProfileImageBase64 != null) {
        payload['profileImage'] = _newProfileImageBase64;
      }

      // Handle Documents (new base64 if picked)
      Map<String, dynamic> docsJson = _profile?.documents?.toJson() ?? {};
      _newDocumentsBase64.forEach((key, base64) {
        if (base64 != null) docsJson[key] = base64;
      });
      payload['documents'] = docsJson;

      payload.addAll({
        'businessName': _salonNameController.text,
        'description': _descriptionController.text,
        'password': _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        'category': _selectedCategory.toLowerCase(),
        'subCategories': subCategories,
        'vendorType': vendorTypeApi,
        'travelRadius': int.tryParse(_radiusController.text) ?? 0,
        'travelSpeed': int.tryParse(_speedController.text) ?? 30,
        'openingHours': updatedOpeningHours.map((e) => e.toJson()).toList(),
        'bankDetails': {
          'bankName': _bankNameController.text,
          'accountNumber': _accountNumberController.text,
          'ifscCode': _ifscCodeController.text,
          'accountHolder': _accountHolderController.text,
        },
      });

      // Update base location if latitude/longitude are changed
      if (_latController.text.isNotEmpty && _lngController.text.isNotEmpty) {
        payload['baseLocation'] = {
          'lat': double.tryParse(_latController.text) ?? 0.0,
          'lng': double.tryParse(_lngController.text) ?? 0.0,
        };
      }

      final updatedProfile = await ApiService.updateVendorProfile(payload);

      setState(() {
        _profile = updatedProfile;
        _isSaving = false;
        _newProfileImageBase64 = null;
        _newGalleryBase64 = [];
        _newDocumentsBase64 = {};
        _updateControllers(updatedProfile);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  void _updateControllers(VendorProfile profile) {
    _salonNameController.text = profile.businessName;
    _descriptionController.text = profile.description;
    _profileImageController.text = profile.profileImage;
    _selectedCategory = profile.category;

    if (profile.bankDetails != null) {
      _bankNameController.text = profile.bankDetails!.bankName ?? "";
      _accountNumberController.text = profile.bankDetails!.accountNumber ?? "";
      _ifscCodeController.text = profile.bankDetails!.ifscCode ?? "";
      _accountHolderController.text = profile.bankDetails!.accountHolder ?? "";
    }

    _atSalon = profile.subCategories.contains('at-salon');
    _atHome = profile.subCategories.contains('at-home');

    _radiusController.text = profile.travelRadius.toString();
    _speedController.text = profile.travelSpeed.toString();
    if (profile.baseLocation != null) {
      _latController.text = profile.baseLocation!.lat.toString();
      _lngController.text = profile.baseLocation!.lng.toString();
    }
    _vendorType = _mapVendorType(profile.vendorType);

    // Update opening hours maps
    for (var hour in profile.openingHours) {
      openDays[hour.day] = hour.isOpen;
      openTimes[hour.day] = hour.open;
      closeTimes[hour.day] = hour.close;
    }
  }

  Future<void> _viewMedia(String? path, String title) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media not available')),
      );
      return;
    }

    if (path.startsWith('http') || path.startsWith('data:image')) {
      _showImageViewer(path, title);
    } else if (path.startsWith('data:application/pdf')) {
      // For base64 PDFs, we might need a separate viewer or download it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Viewing base64 PDFs is not supported directly yet')),
      );
    } else {
      // Attempt to launch other URLs
      final uri = Uri.parse(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open media')),
        );
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
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: path.startsWith('data:image')
                  ? Image.memory(base64Decode(path.split(',').last),
                      fit: BoxFit.contain)
                  : Image.network(path,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.broken_image,
                              size: 50.sp, color: Colors.grey))),
            ),
            SizedBox(height: 12.h),
            Text(title,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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
      if (file.bytes != null || file.path != null) {
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        final base64 =
            "data:${file.extension == 'pdf' ? 'application/pdf' : 'image/${file.extension}'};base64,${base64Encode(bytes)}";
        setState(() {
          _newDocumentsBase64[key] = base64;
        });
      }
    }
  }

  void _applyMondayToAll() {
    final monOpen = openTimes['Monday'] ?? "09:00";
    final monClose = closeTimes['Monday'] ?? "18:30";
    setState(() {
      for (var day in openDays.keys) {
        if (day != 'Monday' && (openDays[day] ?? false)) {
          openTimes[day] = monOpen;
          closeTimes[day] = monClose;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monday times applied to all open days')),
    );
  }

  String _mapVendorType(String type) {
    switch (type) {
      case 'shop-only':
        return "Shop Only (No travel)";
      case 'home-only':
        return "Home Only";
      case 'onsite-only':
        return "Onsite Only";
      case 'hybrid':
        return "Hybrid (Shop + Home Service)";
      case 'vendor-home-service':
        return "Vendor Home Service";
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _salonNameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    _profileImageController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderController.dispose();
    _radiusController.dispose();
    _speedController.dispose();
    _latController.dispose();
    _lngController.dispose();
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
      body: NestedScrollView(
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
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
                tabs: const [
                  Tab(text: "Profile"),
                  Tab(text: "Subscription"),
                  Tab(text: "Travel Settings"),
                  Tab(text: "Gallery"),
                  Tab(text: "Bank Details"),
                  Tab(text: "Documents"),
                  Tab(text: "Opening Hours"),
                  Tab(text: "SMS Packages"),
                  Tab(text: "Categories"),
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
            _buildTravelSettingsTab(),
            _buildGalleryTab(),
            _buildBankDetailsTab(),
            _buildDocumentsTab(),
            _buildOpeningHoursTab(),
            _buildSMSPackagesTab(),
            _buildCategoriesTab(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Header (same for all tabs)
  // ──────────────────────────────────────────────
  Widget _buildHeader() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: const CircularProgressIndicator(color: Colors.black87),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                          () => _showProfileOptions = !_showProfileOptions),
                      child: CircleAvatar(
                        radius: 40.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _newProfileImageBase64 != null
                            ? MemoryImage(base64Decode(
                                _newProfileImageBase64!.split(',').last))
                            : (_profile?.profileImage.isNotEmpty == true
                                ? NetworkImage(_profile!.profileImage)
                                : null),
                        child: (_newProfileImageBase64 == null &&
                                (_profile?.profileImage.isEmpty == true))
                            ? Icon(Icons.person,
                                size: 40.sp, color: Colors.grey)
                            : null,
                      ),
                    ),
                    if (_showProfileOptions)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showProfileOptions = false),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _circleButton(Icons.visibility_outlined, () {
                                  _viewMedia(
                                      _newProfileImageBase64 ??
                                          _profile?.profileImage,
                                      "Profile Image");
                                  setState(() => _showProfileOptions = false);
                                }),
                                SizedBox(width: 8.w),
                                _circleButton(Icons.cloud_upload_outlined, () {
                                  _pickImage(true);
                                  setState(() => _showProfileOptions = false);
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_profile?.businessName ?? "GlowVita Salon & Spa",
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14.sp, color: Colors.grey.shade600),
                        SizedBox(width: 4.w),
                        Text(_profile?.address ?? "Baner Road, Pune",
                            style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                color: Colors.grey.shade600)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text("Vendor ID • ${_profile?.id.substring(0, 8) ?? "N/A"}",
                        style: GoogleFonts.inter(
                            fontSize: 9.5.sp, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            children: [
              _smallOutlineButton(Icons.language, "Website"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallOutlineButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 12.sp, color: Colors.grey.shade700),
      label: Text(label, style: GoogleFonts.inter(fontSize: 10.sp)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  1. Profile
  // ──────────────────────────────────────────────
  Widget _buildProfileTab() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: $_errorMessage",
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.red)),
            SizedBox(height: 16.h),
            ElevatedButton(
                onPressed: _fetchProfileData, child: const Text("Retry")),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Business Profile",
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Update your salon's public information.",
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp, color: Colors.grey.shade600)),
          SizedBox(height: 28.h),
          _label("Salon Name"),
          SizedBox(height: 6.h),
          _textField(controller: _salonNameController),
          SizedBox(height: 20.h),
          _label("Description"),
          SizedBox(height: 6.h),
          _textField(controller: _descriptionController, maxLines: 4),
          SizedBox(height: 20.h),
          _label("Salon Category"),
          SizedBox(height: 6.h),
          _dropdown(
              ["unisex", "male", "female"],
              _selectedCategory.toLowerCase(),
              (v) => setState(() => _selectedCategory = v!)),
          SizedBox(height: 20.h),
          _label("Sub Categories"),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 24.w,
            runSpacing: 12.h,
            children: [
              _checkbox(
                  "At Salon", _atSalon, (v) => setState(() => _atSalon = v!)),
              _checkbox(
                  "At Home", _atHome, (v) => setState(() => _atHome = v!)),
              _checkbox("Custom Location", _customLocation,
                  (v) => setState(() => _customLocation = v!)),
            ],
          ),
          SizedBox(height: 28.h),
          _saveButton(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  2. Subscription
  // ──────────────────────────────────────────────
  Widget _buildSubscriptionTab() {
    if (_isLoading) return _buildLoading();
    final sub = _profile?.subscription;
    if (sub == null) return _buildNoData("No subscription information");

    final startDateStr = sub.startDate != null
        ? DateFormat('dd MMM yyyy').format(sub.startDate!)
        : "N/A";
    final endDateStr = sub.endDate != null
        ? DateFormat('dd MMM yyyy').format(sub.endDate!)
        : "N/A";
    final daysRemaining = sub.endDate != null
        ? sub.endDate!.difference(DateTime.now()).inDays
        : 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My Subscription",
              style: GoogleFonts.inter(
                  fontSize: 13.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSubItem("Status", sub.status,
                    color: sub.status.toLowerCase() == 'active'
                        ? Colors.green
                        : Colors.red),
                _buildSubItem("Plan", sub.plan?.name ?? "N/A"),
                _buildSubItem("Days Remaining", "$daysRemaining Days"),
                _buildSubItem("Start Date", startDateStr),
                _buildSubItem("End Date", endDateStr),
                SizedBox(height: 16.h),
                LinearProgressIndicator(
                  value:
                      daysRemaining > 0 ? (daysRemaining / 365).clamp(0, 1) : 0,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green.shade400,
                  minHeight: 6.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () {
                            if (_profile?.subscription != null) {
                              showDialog(
                                context: context,
                                builder: (context) => _ChangePlanDialog(
                                  currentPlan: _profile!.subscription!.plan,
                                ),
                              );
                            }
                          },
                          child: Text("Change Plan",
                              style: GoogleFonts.inter(fontSize: 10.sp))),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () {
                            if (_profile?.subscription != null) {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    _SubscriptionHistoryDialog(
                                  history: _profile!.subscription!.history,
                                ),
                              );
                            }
                          },
                          child: Text("View History",
                              style: GoogleFonts.inter(fontSize: 10.sp))),
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

  Widget _buildLoading() => Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: const CircularProgressIndicator(color: Colors.black87),
        ),
      );

  Widget _buildNoData(String message) => Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Text(message, style: GoogleFonts.inter(fontSize: 11.sp)),
        ),
      );

  // ──────────────────────────────────────────────
  //  3. Travel Settings
  // ──────────────────────────────────────────────
  Widget _buildTravelSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Travel Settings",
              style: GoogleFonts.inter(
                  fontSize: 17.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Configure travel time calculation.",
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp, color: Colors.grey.shade600)),
          SizedBox(height: 28.h),
          _CollapsibleInfoSection(),
          SizedBox(height: 24.h),
          _labelWithInfo(
              "Vendor Type", "Select how you provide services to customers"),
          SizedBox(height: 6.h),
          _dropdown([
            "Shop Only (No travel)",
            "Home Only",
            "Onsite Only",
            "Hybrid (Shop + Home Service)",
            "Vendor Home Service"
          ], _vendorType, (v) => setState(() => _vendorType = v!)),
          SizedBox(height: 20.h),
          _labelWithInfo("Travel Radius (km)",
              "Maximum distance you can travel for home services"),
          SizedBox(height: 6.h),
          _textField(
              controller: _radiusController,
              keyboardType: TextInputType.number),
          SizedBox(height: 20.h),
          _labelWithInfo("Average Travel Speed (km/h)",
              "Your average travel speed for time estimation (default: 30 km/h)"),
          SizedBox(height: 6.h),
          _textField(
              controller: _speedController, keyboardType: TextInputType.number),
          SizedBox(height: 20.h),
          _labelWithInfo("Base Location (Latitude/Longitude)",
              "Your starting location for travel calculations (shop/home address)"),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                  child:
                      _textField(controller: _latController, hint: "Latitude")),
              SizedBox(width: 12.w),
              Expanded(
                  child: _textField(
                      controller: _lngController, hint: "Longitude")),
            ],
          ),
          SizedBox(height: 36.h),
          _saveButton(text: "Save Travel Settings"),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  4. Gallery
  // ──────────────────────────────────────────────
  Widget _buildGalleryTab() {
    if (_isLoading) return _buildLoading();
    final images = _profile?.gallery ?? [];
    final allImages = [...images, ..._newGalleryBase64];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salon Gallery",
              style: GoogleFonts.inter(
                  fontSize: 15.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () => _pickImage(false),
            child: Container(
              height: 160.h,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 40.sp, color: Colors.grey.shade500),
                    SizedBox(height: 8.h),
                    Text("Drag & drop images here or",
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: Colors.grey.shade600)),
                    Text("browse to upload",
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: Colors.grey.shade600)),
                    SizedBox(height: 8.h),
                    Text("Max 5MB • JPG, PNG, WEBP",
                        style: GoogleFonts.inter(
                            fontSize: 9.5.sp, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          allImages.isEmpty
              ? _buildNoData("No gallery images")
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.h,
                    childAspectRatio: 1,
                  ),
                  itemCount: allImages.length,
                  itemBuilder: (context, index) {
                    final isNew = index >= images.length;
                    final imgPath = allImages[index];
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _viewMedia(imgPath, "Gallery Image ${index + 1}"),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              color: Colors.grey.shade200,
                              image: DecorationImage(
                                image: isNew
                                    ? MemoryImage(
                                        base64Decode(imgPath.split(',').last))
                                    : NetworkImage(imgPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isNew) {
                                  _newGalleryBase64
                                      .removeAt(index - images.length);
                                } else {
                                  _profile?.gallery.removeAt(index);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4.sp),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.delete_outline,
                                  size: 16.sp, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          SizedBox(height: 24.h),
          _saveButton(text: "Save Gallery"),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.sp),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.sp, color: Colors.black87),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  5. Bank Details
  // ──────────────────────────────────────────────
  Widget _buildBankDetailsTab() {
    if (_isLoading) return _buildLoading();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bank Details",
              style: GoogleFonts.inter(
                  fontSize: 17.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Manage your bank account for payouts.",
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp, color: Colors.grey.shade600)),
          SizedBox(height: 28.h),
          _label("Account Holder Name"),
          SizedBox(height: 6.h),
          _textField(controller: _accountHolderController),
          SizedBox(height: 16.h),
          _label("Account Number"),
          SizedBox(height: 6.h),
          _textField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number),
          SizedBox(height: 16.h),
          _label("Bank Name"),
          SizedBox(height: 6.h),
          _textField(controller: _bankNameController),
          SizedBox(height: 16.h),
          _label("IFSC Code"),
          SizedBox(height: 6.h),
          _textField(controller: _ifscCodeController),
          SizedBox(height: 36.h),
          _saveButton(text: "Update Bank Details"),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  6. Documents
  // ──────────────────────────────────────────────
  Widget _buildDocumentsTab() {
    if (_isLoading) return _buildLoading();
    final docs = _profile?.documents;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Business Documents",
              style: GoogleFonts.inter(
                  fontSize: 17.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Upload verification documents (JPG, PDF • max 5MB)",
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp, color: Colors.grey.shade600)),
          SizedBox(height: 24.h),
          ...[
            {
              "label": "Aadhar Card",
              "key": "aadharCard",
              "url": docs?.aadharCard
            },
            {"label": "PAN Card", "key": "panCard", "url": docs?.panCard},
            {
              "label": "Udyog Aadhar",
              "key": "udyogAadhar",
              "url": docs?.udyogAadhar
            },
            {
              "label": "Udhayam Cert",
              "key": "udhayamCert",
              "url": docs?.udhayamCert
            },
            {
              "label": "Shop License",
              "key": "shopLicense",
              "url": docs?.shopLicense
            },
          ].map((doc) {
            final key = doc['key'] as String;
            final isNew = _newDocumentsBase64.containsKey(key);
            final url = doc['url'] as String?;
            final label = doc['label'] as String;
            final hasDoc = isNew || (url != null && url.isNotEmpty);

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 18.sp, color: Colors.grey.shade600),
                  SizedBox(width: 8.w),
                  Expanded(
                    child:
                        Text(label, style: GoogleFonts.inter(fontSize: 11.sp)),
                  ),
                  if (hasDoc) ...[
                    IconButton(
                      icon: Icon(Icons.visibility_outlined,
                          size: 16.sp, color: Colors.blue),
                      onPressed: () => _viewMedia(
                          isNew ? _newDocumentsBase64[key] : url, label),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 16.sp, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          if (isNew) {
                            _newDocumentsBase64.remove(key);
                          } else {
                            // Clear URL in profile model
                            switch (key) {
                              case 'aadharCard':
                                _profile?.documents?.aadharCard = null;
                                break;
                              case 'panCard':
                                _profile?.documents?.panCard = null;
                                break;
                              case 'udyogAadhar':
                                _profile?.documents?.udyogAadhar = null;
                                break;
                              case 'udhayamCert':
                                _profile?.documents?.udhayamCert = null;
                                break;
                              case 'shopLicense':
                                _profile?.documents?.shopLicense = null;
                                break;
                            }
                          }
                        });
                      },
                    ),
                  ] else
                    TextButton(
                        onPressed: () => _pickDocument(key),
                        child: Text("Upload",
                            style: GoogleFonts.inter(fontSize: 10.sp))),
                ],
              ),
            );
          }),
          SizedBox(height: 24.h),
          _saveButton(text: "Save Documents"),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  7. Opening Hours
  // ──────────────────────────────────────────────
  Widget _buildOpeningHoursTab() {
    if (_isLoading) return _buildLoading();
    final days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Opening Hours",
              style: GoogleFonts.inter(
                  fontSize: 17.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 4.h),
          Text("Set your weekly business hours",
              style: GoogleFonts.inter(
                  fontSize: 10.5.sp, color: Colors.grey.shade600)),
          SizedBox(height: 24.h),
          ...days.map((day) {
            final isOpen = openDays[day] ?? false;
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                children: [
                  SizedBox(
                      width: 70.w,
                      child: Row(
                        children: [
                          Text(day,
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600)),
                          if (day == "Monday") ...[
                            SizedBox(width: 4.w),
                            InkWell(
                              onTap: _applyMondayToAll,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text("Apply to All",
                                    style: GoogleFonts.inter(
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ],
                        ],
                      )),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Row(
                      children: [
                        if (isOpen) ...[
                          Expanded(child: _timePicker(day, true)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(Icons.access_time,
                                size: 14.sp, color: Colors.grey.shade400),
                          ),
                          Expanded(child: _timePicker(day, false)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Icon(Icons.access_time,
                                size: 14.sp, color: Colors.grey.shade400),
                          ),
                        ] else
                          Expanded(
                            child: Container(
                              height: 36.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text("-- : --",
                                  style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade400)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                            radius: 3.r,
                            backgroundColor:
                                isOpen ? Colors.green : Colors.red),
                        SizedBox(width: 4.w),
                        Text(isOpen ? "Open" : "Closed",
                            style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: isOpen ? Colors.green : Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Switch(
                    value: isOpen,
                    onChanged: (v) => setState(() => openDays[day] = v),
                    activeColor: Colors.black87,
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 24.h),
          _saveButton(text: "Save Hours"),
        ],
      ),
    );
  }

  Widget _timePicker(String day, bool isOpenTime) {
    final time =
        isOpenTime ? (openTimes[day] ?? "09:00") : (closeTimes[day] ?? "18:30");
    return GestureDetector(
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: _parseTime(time),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.black,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedTime != null) {
          final formattedTime =
              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
          setState(() {
            if (isOpenTime) {
              openTimes[day] = formattedTime;
            } else {
              closeTimes[day] = formattedTime;
            }
          });
        }
      },
      child: Container(
        height: 36.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6.r)),
        child: Text(time, style: GoogleFonts.inter(fontSize: 11.sp)),
      ),
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Widget _buildSubItem(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.sp, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _labelWithInfo(String text, String info) {
    return Row(
      children: [
        _label(text),
        SizedBox(width: 6.w),
        Tooltip(
          message: info,
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline, size: 14.sp, color: Colors.grey),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  8. SMS Packages
  // ──────────────────────────────────────────────
  Widget _buildSMSPackagesTab() {
    if (_isLoading) return _buildLoading();
    final balance = _profile?.currentSmsBalance ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Icon(Icons.sms_outlined, size: 64.sp, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Text("Balance: $balance SMS",
              style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          SizedBox(height: 8.h),
          Text(
              balance > 0
                  ? "You have $balance SMS remaining."
                  : "You haven't purchased any SMS packages yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11.sp, color: Colors.grey.shade600)),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, foregroundColor: Colors.white),
            child: Text("Buy SMS Packages",
                style: GoogleFonts.inter(fontSize: 11.sp)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  9. Categories
  // ──────────────────────────────────────────────
  Widget _buildCategoriesTab() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                size: 56.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text("Category management functionality coming soon.",
                style: GoogleFonts.inter(
                    fontSize: 11.5.sp, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Reusable minimalist widgets
  // ──────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800));

  Widget _textField({
    TextEditingController? controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 11.sp),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: const BorderSide(color: Colors.black54)),
      ),
    );
  }

  Widget _dropdown(
      List<String> items, String value, void Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6.r)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.inter(fontSize: 11.sp))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _checkbox(String label, bool value, void Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
            scale: 0.9,
            child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.black87)),
        SizedBox(width: 6.w),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5.sp, color: Colors.grey.shade800)),
      ],
    );
  }

  Widget _saveButton({String text = "Save Changes"}) {
    return SizedBox(
      width: 140.w,
      height: 42.h,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: _isSaving
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(text,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CollapsibleInfoSection extends StatefulWidget {
  @override
  _CollapsibleInfoSectionState createState() => _CollapsibleInfoSectionState();
}

class _CollapsibleInfoSectionState extends State<_CollapsibleInfoSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
            leading: Icon(Icons.location_on_outlined,
                color: Colors.blue.shade700, size: 20.sp),
            title: Text("Why are these settings important?",
                style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900)),
            trailing: IconButton(
              icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.blue.shade700),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bulletPoint(
                      "Travel radius determines which customers you can serve"),
                  _bulletPoint(
                      "Travel speed helps estimate accurate arrival times"),
                  _bulletPoint(
                      "Base location is used to calculate distances to customers"),
                  _bulletPoint(
                      "These settings enable real-time travel time calculation via Google Maps"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ",
              style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: Colors.blue.shade900)),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

// ──────────────────────────────────────────────
//  Subscription History Dialog (Internal)
// ──────────────────────────────────────────────
class _SubscriptionHistoryDialog extends StatelessWidget {
  final List<History> history;

  const _SubscriptionHistoryDialog({required this.history});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                        'Subscription History',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Your complete subscription payment history',
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

          // Table Header
          Container(
            color: Colors.grey.shade50,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(flex: 3, child: _headerCell("Date")),
                Expanded(flex: 2, child: _headerCell("Plan")),
                Expanded(flex: 2, child: _headerCell("Payment Mode")),
                Expanded(flex: 2, child: _headerCell("Duration")),
                Expanded(
                    flex: 2,
                    child: _headerCell("Status", align: TextAlign.right)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Data List
          Flexible(
            child: history.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(40.w),
                    child: Center(
                      child: Text(
                        "No history found",
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: Colors.grey),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: history.map((item) {
                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 14.h),
                              child: Row(
                                children: [
                                  // Date
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.startDate != null
                                              ? DateFormat('MMM dd, yyyy')
                                                  .format(item.startDate!)
                                              : "N/A",
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (item.startDate != null)
                                          Text(
                                            DateFormat('hh:mm a')
                                                .format(item.startDate!),
                                            style: GoogleFonts.inter(
                                              fontSize: 8.5.sp,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Plan
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.plan,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "Paid Plan",
                                          style: GoogleFonts.inter(
                                            fontSize: 8.5.sp,
                                            color: Colors.grey.shade500,
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
                                        fontSize: 10.5.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),

                                  // Duration
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _calculateDuration(
                                          item.startDate, item.endDate),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),

                                  // Status
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _statusBadge(item.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),

          // Footer
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(
                  "Close",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    Color bgColor = Colors.grey.shade100;

    if (status.toLowerCase().contains('active')) {
      color = Colors.green.shade700;
      bgColor = Colors.green.shade50;
    } else if (status.toLowerCase().contains('expired')) {
      color = Colors.red.shade700;
      bgColor = Colors.red.shade50;
    } else if (status.toLowerCase().contains('pending')) {
      color = Colors.orange.shade700;
      bgColor = Colors.orange.shade50;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "N/A";
    final diff = end.difference(start).inDays;
    return "$diff days";
  }
}

// ──────────────────────────────────────────────
//  Change Plan Dialog (Internal)
// ──────────────────────────────────────────────
class _ChangePlanDialog extends StatefulWidget {
  final Plan? currentPlan;

  const _ChangePlanDialog({this.currentPlan});

  @override
  State<_ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<_ChangePlanDialog> {
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.currentPlan?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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

          // Plan Selection Area
          Container(
            color: Colors.grey.shade50,
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                // Plan Card
                GestureDetector(
                  onTap: () => setState(() => _selectedPlanId = '6-month-mock'),
                  child: Container(
                    width: 160.w,
                    padding:
                        EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _selectedPlanId == '6-month-mock'
                            ? const Color(0xFF9E8DA5)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "6month",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "₹",
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "450",
                              style: GoogleFonts.inter(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "₹500",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "per 6 months",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Footer
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton.icon(
                  onPressed: _selectedPlanId == null
                      ? null
                      : () {
                          // Navigate to payment or confirm change
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Plan selection confirmed")),
                          );
                        },
                  icon: Icon(Icons.sync, size: 16.sp),
                  label: Text(
                    "Confirm Change",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E8DA5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
