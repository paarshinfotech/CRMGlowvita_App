import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import 'services/api_service.dart';
import 'marketing/message_blast.dart';
import 'vendor_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'wallet.dart';
import 'package:path_provider/path_provider.dart';

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
  List<dynamic> _smsPackages = [];
  bool _isLoadingSMSPackages = true;

  // Profile tab controllers
  final _salonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _profileImageController = TextEditingController();
  final _taxRateController = TextEditingController();

  // Bank details controllers
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _accountHolderController = TextEditingController();

  String _selectedCategory = "unisex";
  bool _atSalon = true;
  bool _atHome = true;
  bool _customLocation = false;
  String _selectedTaxType = "percentage";

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
  final int maxFileSize = 5 * 1024 * 1024; // 5MB

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WalletPage()),
        ).then((_) {
          _tabController.animateTo(0);
        });
      }
    });
    _fetchProfileData();
  }

  // Validation logic moved into the save button widget; async method removed.

  Future<void> _fetchProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final profile = await ApiService.getVendorProfile();

      // Fetch working hours
      try {
        final workingHoursData = await ApiService.getWorkingHours();
        if (workingHoursData['workingHoursArray'] != null) {
          final List<dynamic> hoursArray =
              workingHoursData['workingHoursArray'];
          for (var dayData in hoursArray) {
            final String day = dayData['day'];
            final bool isOpen = dayData['isOpen'] ?? false;
            final String openTime = dayData['open'] ?? '';
            final String closeTime = dayData['close'] ?? '';

            openDays[day] = isOpen;
            if (isOpen && openTime.isNotEmpty) {
              openTimes[day] = openTime;
            }
            if (isOpen && closeTime.isNotEmpty) {
              closeTimes[day] = closeTime;
            }
          }
        }
      } catch (e) {
        print('Error fetching working hours: $e');
        // Continue even if working hours fail to load
      }

      try {
        final smsResponse = await ApiService.fetchSMSPackages();
        if (smsResponse['success'] == true) {
          _smsPackages = smsResponse['data'] ?? [];
        }
      } catch (e) {
        print('Error fetching SMS packages: $e');
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  // Convert 12-hour format (09:00AM) to 24-hour format (09:00)
  String _convert12To24Hour(String time12) {
    try {
      if (!time12.contains('AM') && !time12.contains('PM')) {
        return time12; // Already in 24-hour format
      }

      final isPM = time12.toUpperCase().contains('PM');
      final timeWithoutPeriod = time12.replaceAll(
        RegExp(r'[AP]M', caseSensitive: false),
        '',
      );
      final parts = timeWithoutPeriod.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];

      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      print('Error converting time: $e');
      return time12;
    }
  }

  // Convert 24-hour format (18:30) to 12-hour format (06:30PM)
  String _convert24To12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) {
        hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }

      return '${hour.toString().padLeft(2, '0')}:$minute$period';
    } catch (e) {
      print('Error converting time: $e');
      return time24;
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
        'category': _selectedCategory.toLowerCase() == "male"
            ? "men"
            : (_selectedCategory.toLowerCase() == "female"
                  ? "women"
                  : "unisex"),
        'subCategories': subCategories,
        'vendorType': vendorTypeApi,
        'travelRadius': int.tryParse(_radiusController.text) ?? 0,
        'travelSpeed': int.tryParse(_speedController.text) ?? 30,
        'taxRate': double.tryParse(_taxRateController.text) ?? 0.0,
        'openingHours': updatedOpeningHours.map((e) => e.toJson()).toList(),
        'bankDetails': {
          'bankName': _bankNameController.text,
          'accountNumber': _accountNumberController.text,
          'ifscCode': _ifscCodeController.text,
          'accountHolder': _accountHolderController.text,
        },
        'taxes': {
          'taxValue': double.tryParse(_taxRateController.text) ?? 0.0,
          'taxType': _selectedTaxType,
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

      // Update working hours separately
      try {
        final workingHoursPayload = {
          'workingHours': {
            'monday': {
              'isOpen': openDays['Monday'] ?? false,
              'hours': (openDays['Monday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Monday'] ?? '09:00',
                        'closeTime': closeTimes['Monday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
            'tuesday': {
              'isOpen': openDays['Tuesday'] ?? false,
              'hours': (openDays['Tuesday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Tuesday'] ?? '09:00',
                        'closeTime': closeTimes['Tuesday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
            'wednesday': {
              'isOpen': openDays['Wednesday'] ?? false,
              'hours': (openDays['Wednesday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Wednesday'] ?? '09:00',
                        'closeTime': closeTimes['Wednesday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
            'thursday': {
              'isOpen': openDays['Thursday'] ?? false,
              'hours': (openDays['Thursday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Thursday'] ?? '09:00',
                        'closeTime': closeTimes['Thursday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
            'friday': {
              'isOpen': openDays['Friday'] ?? false,
              'hours': (openDays['Friday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Friday'] ?? '09:00',
                        'closeTime': closeTimes['Friday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
            'saturday': {
              'isOpen': openDays['Saturday'] ?? false,
              'hours': (openDays['Saturday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Saturday'] ?? '09:00',
                        'closeTime': closeTimes['Saturday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
            'sunday': {
              'isOpen': openDays['Sunday'] ?? false,
              'hours': (openDays['Sunday'] ?? false)
                  ? [
                      {
                        'openTime': openTimes['Sunday'] ?? '09:00',
                        'closeTime': closeTimes['Sunday'] ?? '18:30',
                      },
                    ]
                  : [],
            },
          },
          'timezone': 'Asia/Kolkata',
        };

        await ApiService.updateWorkingHours(workingHoursPayload);
      } catch (e) {
        print('Error updating working hours: $e');
        // Continue even if working hours update fails
      }

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

      String errorMessage = e.toString();
      if (errorMessage.contains('413')) {
        errorMessage =
            "The total size of uploaded files is too large for the server. Please upload smaller files (max 5MB each) or fewer files at once.";
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection reset by peer')) {
        errorMessage =
            "Connection timed out or reset. This usually happens when uploading very large files. Please try with smaller images or documents.";
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Update Failed"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _updateControllers(VendorProfile profile) {
    _salonNameController.text = profile.businessName;
    _descriptionController.text = profile.description;
    _profileImageController.text = profile.profileImage;
    _selectedCategory = profile.category.toLowerCase();
    // Normalize category to match dropdown items if necessary
    if (_selectedCategory == "men") _selectedCategory = "male";
    if (_selectedCategory == "women") _selectedCategory = "female";
    if (!["unisex", "male", "female"].contains(_selectedCategory)) {
      _selectedCategory = "unisex"; // Fallback
    }
    _taxRateController.text = profile.taxes?.taxValue.toString() ?? "0.0";
    _selectedTaxType = profile.taxes?.taxType ?? "percentage";

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Media not available")));
      return;
    }

    try {
      String mediaPath = path.trim();

      // PDF BASE64
      if (mediaPath.contains("application/pdf")) {
        final base64Str = mediaPath.split(',').last;

        final bytes = base64Decode(base64Str);

        final dir = await getTemporaryDirectory();

        final file = File(
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        await file.writeAsBytes(bytes);

        await OpenFile.open(file.path);

        return;
      }

      // IMAGE BASE64
      if (mediaPath.startsWith('data:image')) {
        _showImageViewer(mediaPath, title);
        return;
      }

      // NETWORK IMAGE
      if (mediaPath.startsWith("http")) {
        if (mediaPath.endsWith(".pdf")) {
          final uri = Uri.parse(mediaPath);

          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showImageViewer(mediaPath, title);
        }

        return;
      }
    } catch (e) {
      debugPrint("VIEW MEDIA ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to open document")));
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
                  ? Image.memory(
                      base64Decode(path.split(',').last),
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      path,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50.sp,
                          color: Colors.grey,
                        ),
                      ),
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

  Future<void> _pickImage(bool forProfile) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      final size = await image.length();
      if (size > maxFileSize) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("File Too Large"),
            content: Text(
              "The selected image is ${(size / (1024 * 1024)).toStringAsFixed(2)}MB, which exceeds the 5MB limit.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }
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
      if (file.size > maxFileSize) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("File Too Large"),
            content: Text(
              "The selected document is ${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB, which exceeds the 5MB limit.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }
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

  /*void _applyMondayToAll() {
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
  }*/

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
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired =
        _profile?.subscription?.status.toLowerCase() == 'expired';

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
          'Profile',
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
                      Tab(text: "Gallery"),
                      Tab(text: "Bank Details"),
                      Tab(text: "Travel Settings"),
                      Tab(text: "Documents"),
                      Tab(text: "Opening Hours"),
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
                const SizedBox.shrink(),
                _buildSubscriptionTab(),
                _buildGalleryTab(),
                _buildBankDetailsTab(),
                _buildTravelSettingsTab(),
                _buildDocumentsTab(),
                _buildOpeningHoursTab(),
                _buildSMSPackagesTab(),
                _buildTaxesTab(),
              ],
            ),
          ),
        ],
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
            SizedBox(
              width: 70.w,
              height: 70.w,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => _showProfileOptions = !_showProfileOptions,
                    ),
                    child: CircleAvatar(
                      radius: 35.r,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _newProfileImageBase64 != null
                          ? MemoryImage(
                              base64Decode(
                                _newProfileImageBase64!.split(',').last,
                              ),
                            )
                          : (_profile?.profileImage.isNotEmpty == true
                                ? NetworkImage(_profile!.profileImage)
                                : null),
                      child:
                          (_newProfileImageBase64 == null &&
                              (_profile?.profileImage.isEmpty == true))
                          ? Icon(Icons.person, size: 35.sp, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _showProfileOptions = !_showProfileOptions,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(4.sp),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 12.sp,
                          color: const Color(0xFF432C39),
                        ),
                      ),
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
                                  "Profile Image",
                                );
                                setState(() => _showProfileOptions = false);
                              }),
                              SizedBox(width: 4.w),
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
                  Text(
                    _profile?.businessName ?? "GlowVita Salon & Spa",
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
                          "Manage your salon profile and settings",
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
                    "Vendor ID : ${_profile?.id.substring(0, 8) ?? "N/A"}",
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
            Text(
              "Error: $_errorMessage",
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.red),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchProfileData,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Business Profile",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Update your salon's public information.",
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: Colors.grey.shade600,
            ),
          ),
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
            [
                  "unisex",
                  "male",
                  "female",
                ].contains(_selectedCategory.toLowerCase())
                ? _selectedCategory.toLowerCase()
                : "unisex",
            (v) => setState(() => _selectedCategory = v!),
          ),
          SizedBox(height: 20.h),
          _label("Sub Categories"),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 24.w,
            runSpacing: 12.h,
            children: [
              _checkbox(
                "At Salon",
                _atSalon,
                (v) => setState(() => _atSalon = v!),
              ),
              _checkbox(
                "At Home",
                _atHome,
                (v) => setState(() => _atHome = v!),
              ),
              _checkbox(
                "Custom Location",
                _customLocation,
                (v) => setState(() => _customLocation = v!),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Tax Information Card (Read-only as per design)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E7EF),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300, width: 0.6),
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2F7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "₹",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4B3A4A),
                    ),
                  ),
                ),

                SizedBox(width: 10.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Active Tax Rate",
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${_profile?.taxes?.taxValue ?? 0}%",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),

                            TextSpan(
                              text:
                                  " (${_profile?.taxes?.taxType ?? 'Percentage'})",
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    if (sub == null) {
      return _buildNoData("No subscription information");
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

          // Main Card
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
                // Top Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.plan?.name ?? "6 Month",
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        Text(
                          "Expires on ${DateFormat('MMMM dd, yyyy').format(sub.endDate ?? DateTime.now())}",
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Active Badge
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

                // Dates Row
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

                // Days Remaining
                Text(
                  "$daysRemaining Days Remaining",
                  style: GoogleFonts.inter(
                    fontSize: 7.sp,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 6.h),

                // Progress Bar
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

          // Change Plan Button
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ChangePlanDialog(
                    currentPlan: sub.plan,
                    onPlanChanged: () {
                      _fetchProfileData();
                    },
                    email: _profile?.email,
                    phone: _profile?.phone,
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

          // View History Button
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

  Widget _buildNoData(String message) => Center(
    child: Padding(
      padding: EdgeInsets.all(40.w),
      child: Text(message, style: GoogleFonts.inter(fontSize: 11.sp)),
    ),
  );

  bool _isIfscInvalid = false;

  Widget _buildBankDetailsTab() {
    if (_isLoading) return _buildLoading();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────────── TITLE ─────────────────
          Text(
            "Bank Details",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            "Manage your bank account for payouts.",
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 18.h),

          // ───────────────── ACCOUNT HOLDER ─────────────────
          _modernLabel("Account Holder Name"),

          SizedBox(height: 6.h),

          _modernTextField(
            controller: _accountHolderController,
            hint: "Enter Account Holder Name",
          ),

          SizedBox(height: 14.h),

          // ───────────────── ACCOUNT NUMBER ─────────────────
          _modernLabel("Account Number"),

          SizedBox(height: 6.h),

          _modernTextField(
            controller: _accountNumberController,
            hint: "Enter Account Number",
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 14.h),

          // ───────────────── BANK NAME ─────────────────
          _modernLabel("Bank Name"),

          SizedBox(height: 6.h),

          _modernTextField(
            controller: _bankNameController,
            hint: "Enter Bank Name",
          ),

          SizedBox(height: 14.h),

          // ───────────────── IFSC CODE ─────────────────
          _modernLabel("IFSC Code"),

          SizedBox(height: 6.h),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modernTextField(
                controller: _ifscCodeController,
                hint: "Enter IFSC Code (e.g., HDFC0123456)",

                onChanged: (value) {
                  final isValid = RegExp(
                    r'^[A-Z]{4}0[A-Z0-9]{6}$',
                  ).hasMatch(value.trim().toUpperCase());

                  setState(() {
                    _isIfscInvalid = value.isNotEmpty && !isValid;
                  });
                },
              ),

              if (_isIfscInvalid)
                Padding(
                  padding: EdgeInsets.only(top: 5.h, left: 4.w),
                  child: Text(
                    "Enter valid IFSC Code",
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 14.h),

          // ───────────────── UPI ID ─────────────────
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

          _modernTextField(
            controller: _upiIdController,
            hint: "Enter UPI ID (e.g., yourname@upi)",
          ),

          SizedBox(height: 22.h),

          // ───────────────── SAVE BUTTON ─────────────────
          Center(
            child: SizedBox(
              width: 170.w,
              height: 34.h,
              child: ElevatedButton(
                onPressed: () async {
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

                  final isValid = RegExp(
                    r'^[A-Z]{4}0[A-Z0-9]{6}$',
                  ).hasMatch(ifsc);

                  setState(() {
                    _isIfscInvalid = !isValid;
                  });

                  // stop update if IFSC invalid
                  if (!isValid) return;

                  try {
                    setState(() => _isSaving = true);

                    final payload = _profile!.toJson();
                    payload['bankDetails'] = {
                      "accountHolder": _accountHolderController.text.trim(),
                      "accountNumber": _accountNumberController.text.trim(),
                      "bankName": _bankNameController.text.trim(),
                      "ifscCode": ifsc,
                      "upiId": _upiIdController.text.trim(),
                    };

                    await ApiService.updateVendorProfile(payload);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Bank details updated successfully"),
                      ),
                    );

                    await _fetchProfileData();
                  } catch (e) {
                    debugPrint("Bank details update error: $e");

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to update bank details"),
                      ),
                    );
                  } finally {
                    setState(() => _isSaving = false);
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B2D3B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),

                child: _isSaving
                    ? SizedBox(
                        height: 14.h,
                        width: 14.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Update Bank Details",
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  TRAVEL SETTINGS TAB
  // ──────────────────────────────────────────────
  Widget _buildTravelSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Travel Settings",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            "Configure your home service travel settings for\naccurate travel time calculation.",
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 18.h),

          _modernLabel("Vendor Type"),
          SizedBox(height: 6.h),

          Container(
            height: 38.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade500, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _vendorType,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.black87,
                ),
                items:
                    [
                      "Shop Only (No travel)",
                      "Home Only",
                      "Onsite Only",
                      "Hybrid (Shop + Home Service)",
                      "Vendor Home Service",
                    ].map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                onChanged: (v) {
                  setState(() {
                    _vendorType = v!;
                  });
                },
              ),
            ),
          ),

          SizedBox(height: 4.h),

          Text(
            "Select how you provide services to customers",
            style: GoogleFonts.inter(
              fontSize: 7.5.sp,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 14.h),

          _modernLabel("Travel Radius (km)"),
          SizedBox(height: 6.h),

          _modernTextField(
            controller: _radiusController,
            hint: "0",
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 4.h),

          Text(
            "Select how you provide services to customers",
            style: GoogleFonts.inter(
              fontSize: 7.5.sp,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 14.h),

          _modernLabel("Average Travel Speed (km/h)"),
          SizedBox(height: 6.h),

          _modernTextField(
            controller: _speedController,
            hint: "30",
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 20.h),

          _labelWithInfo(
            "Base Location (Latitude/Longitude)",
            "Your starting location for travel calculations (shop/home address)",
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: _textField(controller: _latController, hint: "Latitude"),
              ),

              SizedBox(width: 12.w),
              Expanded(
                child: _textField(
                  controller: _lngController,
                  hint: "Longitude",
                ),
              ),
            ],
          ),

          SizedBox(height: 22.h),
          _saveButton(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  COMMON MODERN LABEL
  // ──────────────────────────────────────────────
  Widget _modernLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 9.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  COMMON MODERN TEXTFIELD
  // ──────────────────────────────────────────────
  Widget _modernTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,

      style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.black87),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: GoogleFonts.inter(
          fontSize: 9.sp,
          color: Colors.grey.shade500,
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 0.8),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 0.8),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF4B2D3B), width: 1),
        ),
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          Text(
            "Salon Gallery",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            "Manage your salon's photo gallery.",
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 14.h),

          // UPLOAD BOX
          GestureDetector(
            onTap: () => _pickImage(false),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6F5),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300, width: 0.7),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 34.sp,
                    color: const Color(0xFF4B2D3B),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    "Upload Photos",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    "Drag and drop images here or tap to select files",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 8.5.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // REQUIREMENTS BOX
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4C5F1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "UPLOAD REQUIREMENTS :",
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4B2D3B),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        Text(
                          "• Format : JPG, PNG, WEBP",
                          style: GoogleFonts.inter(
                            fontSize: 7.5.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        Text(
                          "• Max Size : 5MB",
                          style: GoogleFonts.inter(
                            fontSize: 7.5.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // GALLERY GRID
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),
                              child: Image(
                                image: isNew
                                    ? MemoryImage(
                                        base64Decode(imgPath.split(',').last),
                                      )
                                    : NetworkImage(imgPath) as ImageProvider,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        ),

                        // DELETE BUTTON
                        Positioned(
                          top: 6.h,
                          right: 6.w,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isNew) {
                                  _newGalleryBase64.removeAt(
                                    index - images.length,
                                  );
                                } else {
                                  _profile?.gallery.removeAt(index);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(5.sp),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 15.sp,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

          SizedBox(height: 18.h),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 38.h,
            child: ElevatedButton(
              onPressed: () async {
                await _saveButton();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B2D3B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
  //  6. Documents
  // ──────────────────────────────────────────────
  Widget _buildDocumentsTab() {
    if (_isLoading) return _buildLoading();

    final docs = _profile?.documents;

    final documentList = [
      {"label": "Aadhar Card", "key": "aadharCard", "url": docs?.aadharCard},
      {"label": "PAN Card", "key": "panCard", "url": docs?.panCard},
      {
        "label": "Udhayam Certificate",
        "key": "udhayamCert",
        "url": docs?.udhayamCert,
      },
      {"label": "Shop Act", "key": "shopAct", "url": docs?.shopAct},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────────── TITLE ─────────────────
          Text(
            "Business Documents",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            "Upload and manage your verification documents.\nDocuments will be reviewed by our team.",
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 16.h),

          // ───────────────── REQUIREMENTS BOX ─────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "UPLOAD REQUIREMENTS :",
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4B2D3B),
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  "• Format : JPG, PNG, WEBP",
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 4.h),

                Text(
                  "• Max Size : 5MB",
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // ───────────────── DOCUMENT LIST ─────────────────
          ...documentList.map((doc) {
            final key = doc['key'] as String;
            final label = doc['label'] as String;
            final url = doc['url'] as String?;

            final isNew = _newDocumentsBase64.containsKey(key);

            final hasDoc = isNew || (url != null && url.toString().isNotEmpty);

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),

                child: Row(
                  children: [
                    // FILE ICON
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        size: 16.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),

                    SizedBox(width: 10.w),

                    // TITLE + STATUS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 2.h),

                          Text(
                            hasDoc ? "Uploaded" : "Not Uploaded",
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              color: hasDoc ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // STATUS ICON
                    Icon(
                      hasDoc ? Icons.check_rounded : Icons.access_time_rounded,
                      size: 18.sp,
                      color: hasDoc ? Colors.green : Colors.orange,
                    ),

                    SizedBox(width: 6.w),

                    // VIEW BUTTON
                    InkWell(
                      onTap: hasDoc
                          ? () {
                              _viewMedia(
                                isNew ? _newDocumentsBase64[key] : url,
                                label,
                              );
                            }
                          : null,
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.remove_red_eye_outlined,
                          size: 17.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    SizedBox(width: 2.w),

                    // DELETE BUTTON
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isNew) {
                            _newDocumentsBase64.remove(key);
                          } else {
                            switch (key) {
                              case 'aadharCard':
                                _profile?.documents?.aadharCard = null;
                                break;

                              case 'panCard':
                                _profile?.documents?.panCard = null;
                                break;

                              case 'udhayamCert':
                                _profile?.documents?.udhayamCert = null;
                                break;

                              case 'shopAct':
                                _profile?.documents?.shopAct = null;
                                break;
                            }
                          }
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 17.sp,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          SizedBox(height: 24.h),

          // ───────────────── SAVE BUTTON ─────────────────
          Center(
            child: SizedBox(
              width: 180.w,
              height: 36.h,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveButton();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B2D3B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),

                child: Text(
                  "Save Documents",
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildTaxesTab() {
    if (_isLoading) return _buildLoading();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tax Settings",
            style: GoogleFonts.inter(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Configure your tax rates and types.",
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 28.h),
          _label("Tax Value"),
          SizedBox(height: 6.h),
          _textField(
            controller: _taxRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: "e.g. 18.0",
          ),
          SizedBox(height: 20.h),
          _label("Tax Type"),
          SizedBox(height: 6.h),
          _dropdown(
            ["percentage", "fixed"],
            _selectedTaxType,
            (v) => setState(() => _selectedTaxType = v!),
          ),
          SizedBox(height: 36.h),
          _saveButton(text: "Update Tax Settings"),
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
      "Sunday",
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Opening Hours",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Weekly hours",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16.h),
          ...days.map((day) {
            final isOpen = openDays[day] ?? false;

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Day name + apply link (only Monday)
                  SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (day == "Monday") ...[
                          // SizedBox(width: 6.w),
                          /*  GestureDetector(
                            onTap: _applyMondayToAll,
                            child: Text(
                              "apply all",
                              style: GoogleFonts.inter(
                                fontSize: 9.5.sp,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),*/
                        ],
                      ],
                    ),
                  ),

                  // Time fields or Closed state
                  Expanded(
                    child: isOpen
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(child: _compactTimePicker(day, true)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
                                child: Text(
                                  "–",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Expanded(child: _compactTimePicker(day, false)),
                            ],
                          )
                        : Container(
                            height: 28.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              "Closed",
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                  ),

                  SizedBox(width: 12.w),

                  // Compact switch
                  Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: isOpen,
                      onChanged: (v) => setState(() => openDays[day] = v),
                      activeColor: Colors.black87,
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade300,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 20.h),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 34.h,
              child: _saveButton(text: "Save"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactTimePicker(String day, bool isOpenTime) {
    // Always provide fallback so picker opens even if value is missing
    final rawTime = isOpenTime ? openTimes[day] : closeTimes[day];
    final displayTime = (rawTime?.isNotEmpty ?? false)
        ? rawTime!
        : (isOpenTime ? "09:00" : "18:30");

    return GestureDetector(
      onTap: () async {
        final initial = _parseTime(displayTime); // safe fallback

        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.black87,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );

        if (picked != null) {
          final formatted =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
          setState(() {
            if (isOpenTime) {
              openTimes[day] = formatted;
            } else {
              closeTimes[day] = formatted;
            }
          });
        }
      },
      child: Container(
        height: 28.h,
        alignment: Alignment.center,
        constraints: BoxConstraints(
          minWidth: 68.w,
        ), // prevents too narrow fields
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          displayTime,
          style: GoogleFonts.inter(fontSize: 10.5.sp, color: Colors.black87),
        ),
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

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(":");
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // Fallback in case of invalid format
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  // ──────────────────────────────────────────────
  //  8. SMS Packages
  // ──────────────────────────────────────────────
  Widget _buildSMSPackagesTab() {
    if (_isLoading) return _buildLoading();
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
    DateTime purchaseDate =
        _profile?.createdAt ?? DateTime.now().subtract(const Duration(days: 5));
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

  // ──────────────────────────────────────────────
  //  9. Categories
  // ──────────────────────────────────────────────
  Widget _buildUploadRequirements() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 4.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "UPLOAD REQUIREMENTS:",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6B4B9C),
            ),
          ),
          SizedBox(height: 8.h),
          _requirementRow("File formats: JPG, JPEG, PDF"),
          SizedBox(height: 4.h),
          _requirementRow("Maximum file size: 5MB"),
        ],
      ),
    );
  }

  Widget _requirementRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Container(
            width: 4.w,
            height: 4.w,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 56.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              "Category management functionality coming soon.",
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Reusable minimalist widgets
  // ──────────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 9.sp,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade800,
    ),
  );

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
      style: GoogleFonts.inter(fontSize: 9.sp),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (items.isNotEmpty && items.contains(value))
              ? value
              : (items.isNotEmpty ? items.first : null),
          isExpanded: true,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.inter(fontSize: 11.sp)),
                ),
              )
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
            activeColor: Colors.black87,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5.sp,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _saveButton({String text = "Save Changes"}) {
    return SizedBox(
      width: 140.w,
      height: 42.h,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () async {
                // Validate Salon Name (only letters and spaces)
                final salonName = _salonNameController.text.trim();
                final nameValid = RegExp(r'^[A-Za-z\s]+$').hasMatch(salonName);
                if (!nameValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Salon name must contain only letters and spaces.',
                      ),
                    ),
                  );
                  return;
                }

                // Validate Bank Name (only letters and spaces)
                final bankName = _bankNameController.text.trim();
                if (bankName.isNotEmpty) {
                  final bankValid = RegExp(r'^[A-Za-z\s]+$').hasMatch(bankName);
                  if (!bankValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bank name must contain only letters and spaces.',
                        ),
                      ),
                    );
                    return;
                  }
                }

                await _updateProfile();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF432C39),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
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
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
            leading: Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).primaryColor,
              size: 20.sp,
            ),
            title: Text(
              "Why are these settings important?",
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Theme.of(context).primaryColor,
              ),
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
                    "Travel radius determines which customers you can serve",
                  ),
                  _bulletPoint(
                    "Travel speed helps estimate accurate arrival times",
                  ),
                  _bulletPoint(
                    "Base location is used to calculate distances to customers",
                  ),
                  _bulletPoint(
                    "These settings enable real-time travel time calculation via Google Maps",
                  ),
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
          Text(
            "• ",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
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
//  Subscription History Dialog (Internal)
// ──────────────────────────────────────────────
class _SubscriptionHistoryDialog extends StatelessWidget {
  final List<History> history;

  const _SubscriptionHistoryDialog({required this.history});

  @override
  Widget build(BuildContext context) {
    // Sort history to show latest first if not already sorted
    final sortedHistory = List<History>.from(history)
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
                                                "N/A", // Matches screenshot "N/A"
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
}

// ──────────────────────────────────────────────
//  Change Plan Dialog (Internal)
// ──────────────────────────────────────────────
class ChangePlanDialog extends StatefulWidget {
  final Plan? currentPlan;
  final VoidCallback onPlanChanged;
  final String? email;
  final String? phone;

  const ChangePlanDialog({
    this.currentPlan,
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
    _selectedPlanId = widget.currentPlan?.id;
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
        // If current plan is not in the list, don't auto-select it unless it matches ID
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
          userType: 'vendor',
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
                            ],
                          ),
                        ),
                      );
                    },
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: (_selectedPlanId == null || _isSaving)
                      ? null
                      : _handleRenew,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E8DA5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Confirm & Pay",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
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
}
