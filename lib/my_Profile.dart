import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';
import 'package:intl/intl.dart';

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
  String? _errorMessage;

  // Profile tab controllers
  final _salonNameController =
      TextEditingController(text: "GlowVita Salon & Spa");
  final _descriptionController =
      TextEditingController(text: "Premium beauty & wellness salon");
  String _selectedCategory = "Unisex";
  bool _atSalon = true;
  bool _atHome = true;
  bool _customLocation = false;

  // Travel settings
  String _vendorType = "Shop Only (No travel)";
  final _radiusController = TextEditingController(text: "0");
  final _speedController = TextEditingController(text: "30");
  final _latController = TextEditingController(text: "19.987237");
  final _lngController = TextEditingController(text: "73.784313");

  // Opening hours (simple model – you can expand to full map/list)
  Map<String, bool> openDays = {
    "Monday": true,
    "Tuesday": true,
    "Wednesday": true,
    "Thursday": true,
    "Friday": true,
    "Saturday": true,
    "Sunday": false,
  };

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

  void _updateControllers(VendorProfile profile) {
    _salonNameController.text = profile.businessName;
    _descriptionController.text = profile.description;
    _selectedCategory = profile.category;
    _atSalon = profile.subCategories.contains('at-salon');
    _atHome = profile.subCategories.contains('at-home');

    _radiusController.text = profile.travelRadius.toString();
    _speedController.text = profile.travelSpeed.toString();
    if (profile.baseLocation != null) {
      _latController.text = profile.baseLocation!.lat.toString();
      _lngController.text = profile.baseLocation!.lng.toString();
    }
    _vendorType = _mapVendorType(profile.vendorType);

    // Update opening hours
    for (var hour in profile.openingHours) {
      if (openDays.containsKey(hour.day)) {
        openDays[hour.day] = hour.isOpen;
      }
    }
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
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  image: DecorationImage(
                    image: _profile?.profileImage != null &&
                            _profile!.profileImage.isNotEmpty
                        ? NetworkImage(_profile!.profileImage)
                        : const AssetImage('assets/images/salon.jpg')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
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
          SizedBox(height: 36.h),
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
                          onPressed: () {},
                          child: Text("Change Plan",
                              style: GoogleFonts.inter(fontSize: 10.sp))),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () {},
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salon Gallery",
              style: GoogleFonts.inter(
                  fontSize: 15.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          Container(
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
          SizedBox(height: 16.h),
          // Placeholder for uploaded images grid
          images.isEmpty
              ? _buildNoData("No gallery images")
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      color: Colors.grey.shade200,
                      image: DecorationImage(
                        image: NetworkImage(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
          SizedBox(height: 24.h),
          _saveButton(text: "Save Gallery"),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  5. Bank Details
  // ──────────────────────────────────────────────
  Widget _buildBankDetailsTab() {
    if (_isLoading) return _buildLoading();
    final bank = _profile?.bankDetails;

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
          _textField(
              controller:
                  TextEditingController(text: bank?.accountHolder ?? "")),
          SizedBox(height: 16.h),
          _label("Account Number"),
          SizedBox(height: 6.h),
          _textField(
              controller:
                  TextEditingController(text: bank?.accountNumber ?? ""),
              keyboardType: TextInputType.number),
          SizedBox(height: 16.h),
          _label("Bank Name"),
          SizedBox(height: 6.h),
          _textField(
              controller: TextEditingController(text: bank?.bankName ?? "")),
          SizedBox(height: 16.h),
          _label("IFSC Code"),
          SizedBox(height: 6.h),
          _textField(
              controller: TextEditingController(text: bank?.ifscCode ?? "")),
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
            {"label": "Aadhar Card", "status": docs?.aadharCardStatus},
            {"label": "PAN Card", "status": docs?.panCardStatus},
            {"label": "Udyog Aadhar", "status": "pending"},
            {"label": "Udhayam Certificate", "status": "pending"},
            {"label": "Shop License", "status": "pending"},
          ].map((doc) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 18.sp, color: Colors.grey.shade600),
                        SizedBox(width: 8.w),
                        Text(doc['label']!,
                            style: GoogleFonts.inter(fontSize: 11.sp)),
                      ],
                    ),
                    Text(doc['status'] ?? "Not uploaded",
                        style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: doc['status'] == 'Approved'
                                ? Colors.green
                                : Colors.grey.shade500)),
                    TextButton(
                        onPressed: () {},
                        child: Text("Upload",
                            style: GoogleFonts.inter(fontSize: 10.sp))),
                  ],
                ),
              )),
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
    final hoursList = _profile?.openingHours ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Opening Hours",
              style: GoogleFonts.inter(
                  fontSize: 17.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          ...hoursList.map((hour) {
            final day = hour.day;
            final isOpen = hour.isOpen;
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                children: [
                  SizedBox(
                      width: 80.w,
                      child: Text(day,
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, fontWeight: FontWeight.w500))),
                  if (isOpen) ...[
                    _timePicker(hour.open.isNotEmpty ? hour.open : "09:00"),
                    Text(" – ", style: GoogleFonts.inter(fontSize: 11.sp)),
                    _timePicker(hour.close.isNotEmpty ? hour.close : "18:30"),
                  ] else
                    Text("Closed",
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: Colors.red.shade400)),
                  const Spacer(),
                  Switch(
                    value: isOpen,
                    onChanged: (v) => setState(() => openDays[day] = v),
                    activeColor: Colors.black87,
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text("Apply to all", style: GoogleFonts.inter(fontSize: 10.5.sp)),
              const Spacer(),
              TextButton(
                  onPressed: () {},
                  child:
                      Text("Apply", style: GoogleFonts.inter(fontSize: 10.sp))),
            ],
          ),
          SizedBox(height: 24.h),
          _saveButton(text: "Save Hours"),
        ],
      ),
    );
  }

  Widget _timePicker(String time) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: _parseTime(time),
          builder: (context, child) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
              child: Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                  dialogBackgroundColor: Colors.white,
                ),
                child: child!,
              ),
            );
          },
        );
        if (pickedTime != null) {
          // In a real app, update the state here for the specific day/slot
          print("Picked time: ${pickedTime.format(context)}");
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
      width: 120.w,
      height: 42.h,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: Text(text,
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
