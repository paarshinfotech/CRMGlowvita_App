import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../vendor_model.dart';
import 'utils/validators.dart';

class AddStaffDialog extends StatefulWidget {
  final Map? existing;
  final VoidCallback? onRefresh;

  const AddStaffDialog({Key? key, this.existing, this.onRefresh})
      : super(key: key);

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog>
    with SingleTickerProviderStateMixin {
  // Theme constants
  final Color _kPrimary = const Color(0xFF4A2C40);
  final Color _kPink = const Color(0xFFB33A6B);
  final Color _kBorder = const Color(0xFFE5E5E5);
  final Color _kLabel = const Color(0xFF2C2C2C);

  // Personal
  final _fullName = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _position = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _description = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Employment / Job
  final _salary = TextEditingController();
  final _experience = TextEditingController();
  final _clients = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _commissionEnabled = false;
  final _commissionPercentage = TextEditingController();

  // Bank
  final _accHolder = TextEditingController();
  final _accNumber = TextEditingController();
  final _bankName = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();

  // Permissions (Access)
  final Map<String, bool> _permissions = {
    'Dashboard': false,
    'Staff': false,
    'Products': false,
    'Orders': false,
    'Offers & Coupons': false,
    'Notifications': false,
    'Calendar': false,
    'Clients': false,
    'Marketplace': false,
    'Shipping': false,
    'Referrals': false,
    'Reports': false,
    'Appointments': false,
    'Services': false,
    'Sales': false,
    'Settlements': false,
    'Marketing': false,
    'Expenses': false,
  };

  // Grouped permissions matching Figma
  final Map<String, List<String>> _permissionGroups = {
    'CORE OPERATIONS': ['Dashboard', 'Calendar', 'Appointments', 'Clients', 'Staff'],
    'SERVICES & PRODUCTS': ['Services', 'Products'],
    'SALES & COMMERCE': ['Sales', 'Orders', 'Marketplace', 'Referrals', 'Offers & Coupons'],
    'FINANCIAL & OPERATIONS': ['Settlements', 'Expenses', 'Reports'],
    'COMMUNICATION': ['Notifications', 'Marketing'],
  };

  // Timing controllers
  final Map<String, TextEditingController> _weeklyTiming = {
    'Mon': TextEditingController(),
    'Tue': TextEditingController(),
    'Wed': TextEditingController(),
    'Thu': TextEditingController(),
    'Fri': TextEditingController(),
    'Sat': TextEditingController(),
    'Sun': TextEditingController(),
  };

  // Weekly availability (day -> isAvailable)
  final Map<String, bool> _weeklyAvailability = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };

  // Salon Opening Hours
  VendorProfile? _vendorProfile;
  bool _isLoadingSalonHours = true;

  // Photo
  String? _imagePath;

  // Form keys per tab
  final _personalFormKey = GlobalKey<FormState>();
  final _employmentFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  late final TabController _tabController;
  bool _isSaving = false;
  Map? _localExisting;

  // Mapping
  static const Map<String, String> displayToPerm = {
    'Dashboard': 'dashboard_view',
    'Calendar': 'calendar_view',
    'Appointments': 'appointments_view',
    'Staff': 'staff_view',
    'Products': 'products_view',
    'Orders': 'orders_view',
    'Offers & Coupons': 'offers_view',
    'Notifications': 'notifications_view',
    'Clients': 'clients_view',
    'Marketplace': 'marketplace_view',
    'Shipping': 'shipping_view',
    'Referrals': 'referrals_view',
    'Reports': 'reports_view',
    'Services': 'services_view',
    'Sales': 'sales_view',
    'Settlements': 'settlements_view',
    'Marketing': 'marketing_view',
    'Expenses': 'expenses_view',
  };

  static const Map<String, String> dayAbbrToFull = {
    'Mon': 'monday',
    'Tue': 'tuesday',
    'Wed': 'wednesday',
    'Thu': 'thursday',
    'Fri': 'friday',
    'Sat': 'saturday',
    'Sun': 'sunday',
  };

  static const Map<String, String> dayFullToAbbr = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  ImageProvider? _getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('data:image')) {
      return MemoryImage(base64Decode(path.split(',').last));
    }
    if (path.contains('/')) {
      final baseUrl = 'https://partners.glowvitasalon.com';
      final fullUrl = '$baseUrl${path.startsWith('/') ? path : '/$path'}';
      return NetworkImage(fullUrl);
    }
    return FileImage(File(path));
  }

  int _timeToMinutes(String time) {
    if (time.isEmpty) return 0;
    try {
      try {
        final date = DateFormat.jm().parse(time.trim());
        return date.hour * 60 + date.minute;
      } catch (_) {
        final date = DateFormat("HH:mm").parse(time.trim());
        return date.hour * 60 + date.minute;
      }
    } catch (e) {
      debugPrint('Error parsing time to minutes ($time): $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _localExisting = widget.existing;
    _fetchSalonHours();

    // Auto split Full Name to First & Last Name
    _fullName.addListener(() {
      final text = _fullName.text.trim();
      final parts = text.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        _firstName.text = parts.first;
        _lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      } else {
        _firstName.text = '';
        _lastName.text = '';
      }
    });

    // Initialize default availability
    _weeklyAvailability['monday'] = true;
    _weeklyAvailability['tuesday'] = true;
    _weeklyAvailability['wednesday'] = true;
    _weeklyAvailability['thursday'] = true;
    _weeklyAvailability['friday'] = true;
    _weeklyAvailability['saturday'] = true;
    _weeklyAvailability['sunday'] = true;

    if (widget.existing != null) {
      final m = widget.existing!;

      // Personal
      final fullName = m['fullName'] ?? '';
      _fullName.text = fullName;
      _position.text = m['position'] ?? '';
      _mobile.text = m['mobileNo'] ?? '';
      _email.text = m['emailAddress'] ?? '';
      _description.text = m['description'] ?? '';

      // Employment
      _salary.text = (m['salary'] ?? '').toString();
      _experience.text = (m['yearOfExperience'] ?? '').toString();
      _clients.text = (m['clientsServed'] ?? '').toString();
      _commissionEnabled = m['commission'] == true;
      _commissionPercentage.text =
          (m['commissionRate'] ?? m['commissionPercentage'] ?? '').toString();

      if (m['startDate'] != null) {
        _startDate = DateTime.tryParse(m['startDate'].toString());
      }
      if (m['endDate'] != null) {
        _endDate = DateTime.tryParse(m['endDate'].toString());
      }

      // Bank
      final bank = (m['bankDetails'] as Map?) ?? {};
      _accHolder.text = (bank['accountHolderName'] ?? '').toString();
      _accNumber.text = (bank['accountNumber'] ?? '').toString();
      _bankName.text = (bank['bankName'] ?? '').toString();
      _ifsc.text = (bank['ifscCode'] ?? '').toString();
      _upi.text = (bank['upiId'] ?? '').toString();

      // Permissions
      final permList = (m['permissions'] as List?) ?? [];
      final inverse = displayToPerm.map((k, v) => MapEntry(v, k));
      for (final perm in permList) {
        final displayName = inverse[perm];
        if (displayName != null) _permissions[displayName] = true;
      }

      // Availability
      for (final fullDay in dayFullToAbbr.keys) {
        final abbr = dayFullToAbbr[fullDay]!;
        bool available = false;
        List slots = [];

        if (m.containsKey('${fullDay}Available')) {
          available = m['${fullDay}Available'] == true;
          slots = m['${fullDay}Slots'] as List? ?? [];
        } else {
          final availabilityData = m['availability'] as Map?;
          if (availabilityData != null) {
            if (availabilityData.containsKey('${fullDay}Available')) {
              available = availabilityData['${fullDay}Available'] == true;
              slots = availabilityData['${fullDay}Slots'] as List? ?? [];
            } else if (availabilityData.containsKey(fullDay)) {
              final dayData = availabilityData[fullDay] as Map?;
              if (dayData != null) {
                available = dayData['available'] == true;
                slots = dayData['slots'] as List? ?? [];
              }
            }
          }
        }

        _weeklyAvailability[fullDay] = available;
        if (available && slots.isNotEmpty) {
          final slot = (slots.first as Map?) ?? {};
          final start = (slot['startTime'] ?? '10:00').toString();
          final end = (slot['endTime'] ?? '19:00').toString();
          _weeklyTiming[abbr]!.text = '$start - $end';
        }
      }

      // Photo
      if (m['photo'] != null && m['photo'].toString().isNotEmpty) {
        _imagePath = m['photo'].toString();
      }
    }
  }

  Future<void> _fetchSalonHours() async {
    try {
      final profile = await ApiService.getVendorProfile();
      if (mounted) {
        setState(() {
          _vendorProfile = profile;
          _isLoadingSalonHours = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching salon hours: $e');
      if (mounted) {
        setState(() {
          _isLoadingSalonHours = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _position.dispose();
    _mobile.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _description.dispose();
    _salary.dispose();
    _experience.dispose();
    _clients.dispose();
    _commissionPercentage.dispose();
    _accHolder.dispose();
    _accNumber.dispose();
    _bankName.dispose();
    _ifsc.dispose();
    _upi.dispose();
    _weeklyTiming.values.forEach((c) => c.dispose());
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  bool _validateAll() {
    final personalOk = _personalFormKey.currentState?.validate() ?? true;
    final employmentOk = _employmentFormKey.currentState?.validate() ?? true;
    final bankOk = _bankFormKey.currentState?.validate() ?? true;

    if (!personalOk) {
      _tabController.animateTo(0);
      return false;
    }
    if (!employmentOk) {
      _tabController.animateTo(1);
      return false;
    }
    if (!bankOk) {
      _tabController.animateTo(3); // bank is index 3
      return false;
    }

    // Password validations
    if (widget.existing == null) {
      final passErr = Validators.validatePassword(_password.text);
      if (passErr != null) {
        _showError(passErr);
        _tabController.animateTo(0);
        return false;
      }
      if (_confirmPassword.text != _password.text) {
        _showError('Passwords do not match');
        _tabController.animateTo(0);
        return false;
      }
    } else {
      if (_password.text.isNotEmpty) {
        final passErr = Validators.validatePassword(_password.text);
        if (passErr != null) {
          _showError(passErr);
          _tabController.animateTo(0);
          return false;
        }
        if (_confirmPassword.text != _password.text) {
          _showError('Passwords do not match');
          _tabController.animateTo(0);
          return false;
        }
      }
    }

    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _save() async {
    if (!_validateAll()) return;

    final fullName = _fullName.text.trim();
    final List<String> permissions = _permissions.entries
        .where((e) => e.value)
        .map((e) => displayToPerm[e.key]!)
        .toList();

    final Map<String, dynamic> availabilityFields = {};

    _weeklyTiming.forEach((abbr, controller) {
      final text = controller.text.trim();
      final fullDay = dayAbbrToFull[abbr]!;
      final isAvailable = _weeklyAvailability[fullDay] ?? false;

      availabilityFields['${fullDay}Available'] = isAvailable;

      if (!isAvailable || text.isEmpty) {
        availabilityFields['${fullDay}Slots'] = [];
      } else {
        final parts = text.split(' - ');
        if (parts.length == 2) {
          final startTime = parts[0].trim();
          final endTime = parts[1].trim();

          availabilityFields['${fullDay}Slots'] = [
            {
              "startTime": startTime,
              "endTime": endTime,
              "startMinutes": _timeToMinutes(startTime),
              "endMinutes": _timeToMinutes(endTime),
            },
          ];
        } else {
          availabilityFields['${fullDay}Slots'] = [];
        }
      }
    });

    final double commissionPercentage =
        double.tryParse(_commissionPercentage.text.trim()) ?? 0.0;

    final Map<String, dynamic> bankDetails = {
      "accountHolderName": _accHolder.text.trim(),
      "accountNumber": _accNumber.text.trim(),
      "bankName": _bankName.text.trim(),
      "ifscCode": _ifsc.text.trim(),
      "upiId": _upi.text.trim(),
    };

    final int salary = int.tryParse(_salary.text.trim()) ?? 0;
    final int yearOfExperience = int.tryParse(_experience.text.trim()) ?? 0;
    final int clientsServed = int.tryParse(_clients.text.trim()) ?? 0;

    final String? startDate = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;
    final String? endDate = _endDate != null
        ? DateFormat('yyyy-MM-dd').format(_endDate!)
        : null;

    String? password;
    if (widget.existing == null) {
      password = _password.text.trim();
    } else {
      if (_password.text.trim().isNotEmpty) {
        password = _password.text.trim();
      }
    }

    String? photoBase64 = _imagePath;
    if (_imagePath != null &&
        !_imagePath!.startsWith('http') &&
        !_imagePath!.startsWith('data:image')) {
      try {
        final bytes = File(_imagePath!).readAsBytesSync();
        photoBase64 =
            'data:image/${_imagePath!.split('.').last};base64,${base64Encode(bytes)}';
      } catch (e) {
        debugPrint('Error converting image to base64: $e');
      }
    }

    final Map<String, dynamic> result = {
      'fullName': fullName.isEmpty ? 'Unnamed Staff' : fullName,
      'position': _position.text.trim(),
      'mobileNo': _mobile.text.trim(),
      'emailAddress': _email.text.trim(),
      'description': _description.text.trim(),
      'salary': salary,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'yearOfExperience': yearOfExperience,
      'clientsServed': clientsServed,
      'commission': _commissionEnabled,
      'commissionRate': commissionPercentage,
      'permissions': permissions,
      'permission': permissions,
      ...availabilityFields,
      'blockedTimes': [],
      'bankDetails': bankDetails,
      'userType': 'staff',
      if (password != null) 'password': password,
      if (photoBase64 != null) 'photo': photoBase64,
    };

    if (_localExisting != null) {
      result['id'] = _localExisting!['_id'];
      result['_id'] = _localExisting!['_id'];
    }

    setState(() => _isSaving = true);
    try {
      if (_localExisting != null) {
        await ApiService.updateStaff(_localExisting!['_id'], result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final response = await ApiService.createStaff(result);
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['staff'] != null) {
            _localExisting = data['staff'];
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Staff created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
      widget.onRefresh?.call();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showError('Error saving staff: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW < 480 ? screenW - 16 : 420.0;
    final dialogH = MediaQuery.of(context).size.height * 0.88;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: dialogW,
          height: dialogH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Staff Member',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add a new staff member to your team.',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar Scrollable
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
                labelColor: _kPink,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _kPink,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: 'Personal'),
                  Tab(text: 'Job'),
                  Tab(text: 'Commission'),
                  Tab(text: 'Bank'),
                  Tab(text: 'Access'),
                  Tab(text: 'Timing'),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFF1F1F1)),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalTab(),
                    _buildJobTab(),
                    _buildCommissionTab(),
                    _buildBankTab(),
                    _buildAccessTab(),
                    _buildTimingTab(),
                  ],
                ),
              ),

              // Footer navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: _kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (_tabController.index > 0) {
                            _tabController.animateTo(_tabController.index - 1);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: _kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_tabController.index < 5) {
                            _tabController.animateTo(_tabController.index + 1);
                          } else {
                            _save();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _tabController.index == 5 ? 'Save Staff' : 'Next',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: _kPink,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: _kPink.withOpacity(0.3), height: 1)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _kLabel,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 8, color: Colors.red),
      ),
      validator: validator,
    );
  }

  Widget _buildPersonalTab() {
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo upload row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: _getImageProvider(_imagePath),
                  child: _imagePath == null
                      ? Icon(Icons.person, size: 28, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFILE PHOTO',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                      Text(
                        'JPG, PNG or WEBP - Max 5MB',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(color: _kPink),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'UPLOAD',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: _kPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('PERSONAL INFORMATION'),

            _buildFieldLabel('FULL NAME', required: true),
            _buildTextField(
              controller: _fullName,
              hintText: 'e.g. Priya Sharma',
              validator: (v) => Validators.validateName(v, 'Full name'),
            ),

            _buildFieldLabel('POSITION', required: true),
            _buildTextField(
              controller: _position,
              hintText: 'e.g. Senior Stylist',
              validator: (v) => Validators.validateName(v, 'Position'),
            ),

            _buildFieldLabel('MOBILE NUMBER', required: true),
            _buildTextField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              hintText: '+91 9085412873',
              validator: Validators.validatePhone,
            ),

            _buildFieldLabel('EMAIL ADDRESS', required: true),
            _buildTextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              hintText: 'e.g. staff@salon.com',
              validator: Validators.validateEmail,
            ),

            // Password
            _buildFieldLabel(
              'PASSWORD ${widget.existing == null ? "(Required)" : "(Optional)"}',
              required: widget.existing == null,
            ),
            _buildTextField(
              controller: _password,
              obscureText: _obscurePassword,
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 14,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (widget.existing == null) {
                  return Validators.validatePassword(v);
                }
                if (v != null && v.isNotEmpty) {
                  return Validators.validatePassword(v);
                }
                return null;
              },
            ),

            _buildFieldLabel(
              'CONFIRM PASSWORD ${widget.existing == null ? "(Required)" : "(Optional)"}',
              required: widget.existing == null,
            ),
            _buildTextField(
              controller: _confirmPassword,
              obscureText: _obscureConfirmPassword,
              hintText: 'Confirm Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  size: 14,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (v) {
                if (widget.existing == null) {
                  if (v == null || v.isEmpty) return 'Confirm password is required';
                  if (v != _password.text) return 'Passwords do not match';
                } else if (_password.text.trim().isNotEmpty) {
                  if (v != _password.text) return 'Passwords do not match';
                }
                return null;
              },
            ),

            _buildFieldLabel('DESCRIPTION (Optional)'),
            _buildTextField(
              controller: _description,
              hintText: 'Brief bio or notes about this staff member...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTab() {
    return Form(
      key: _employmentFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('JOB INFORMATION'),

            _buildFieldLabel('SALARY (Per Month) *', required: true),
            _buildTextField(
              controller: _salary,
              keyboardType: TextInputType.number,
              hintText: 'e.g. 50,000/-',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Salary is required';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid salary';
                return null;
              },
            ),

            _buildFieldLabel('YEARS OF EXPERIENCE *', required: true),
            _buildTextField(
              controller: _experience,
              keyboardType: TextInputType.number,
              hintText: 'e.g. 4',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Experience is required';
                if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),

            // Start & End Date row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('START DATE *', required: true),
                      InkWell(
                        onTap: () => _pickDate(start: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate == null
                                    ? 'Select Date'
                                    : DateFormat('dd-MM-yyyy').format(_startDate!),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: _startDate == null ? Colors.grey[400] : Colors.black87,
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('END DATE *', required: true),
                      InkWell(
                        onTap: () => _pickDate(start: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate == null
                                    ? 'Select Date'
                                    : DateFormat('dd-MM-yyyy').format(_endDate!),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: _endDate == null ? Colors.grey[400] : Colors.black87,
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _buildFieldLabel('CLIENTS SERVED (Optional) *', required: true),
            _buildTextField(
              controller: _clients,
              keyboardType: TextInputType.number,
              hintText: 'Total number of clients served',
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('COMMISSION DETAILS'),

          // Commission Switch Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Commission',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      Text(
                        'Enable automatic commission calculation for this staff.',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _commissionEnabled,
                  activeColor: _kPink,
                  onChanged: (v) => setState(() => _commissionEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Conditional display based on toggle
          if (!_commissionEnabled)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_graph_outlined, size: 36, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Commission is Disabled',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn on the switch above to start tracking\nperformance-based earnings for this staff member.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildFieldLabel('COMMISSION RATE (%)', required: true),
            _buildTextField(
              controller: _commissionPercentage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: 'e.g. 10',
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('%', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              validator: (v) {
                if (_commissionEnabled) {
                  if (v == null || v.trim().isEmpty) return 'Percentage is required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff will earn ${_commissionPercentage.text.isEmpty ? '0' : _commissionPercentage.text}% on all completed appointments.',
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankTab() {
    return Form(
      key: _bankFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_outlined, size: 16, color: Colors.amber[900]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURE & CONFIDENTIAL',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bank details are encrypted and stored securely. This information is only used for salary disbursement.',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('BANKING INFORMATION'),

            _buildFieldLabel('ACCOUNT HOLDER NAME', required: true),
            _buildTextField(
              controller: _accHolder,
              hintText: 'Full name as per bank records',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            _buildFieldLabel('ACCOUNT NUMBER', required: true),
            _buildTextField(
              controller: _accNumber,
              keyboardType: TextInputType.number,
              hintText: 'e.g. 1234567890',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            _buildFieldLabel('BANK NAME', required: true),
            _buildTextField(
              controller: _bankName,
              hintText: 'e.g. HDFC Bank, ICICI Bank......',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('IFSC CODE *', required: true),
                      _buildTextField(
                        controller: _ifsc,
                        hintText: 'e.g. HDFC0123456',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('UPI ID (Optional) *', required: true),
                      _buildTextField(
                        controller: _upi,
                        hintText: 'e.g. name@upi',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessTab() {
    // Check if all permissions are enabled
    bool isAllSelected = _permissions.values.every((v) => v);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERMISSIONS',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _kPink,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    final target = !isAllSelected;
                    _permissions.keys.forEach((k) => _permissions[k] = target);
                  });
                },
                child: Text(
                  isAllSelected ? 'Deselect All' : 'Select All',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: _kPink.withOpacity(0.3), height: 1),
          const SizedBox(height: 12),

          // Loop grouped permissions
          ..._permissionGroups.entries.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    group.key,
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: group.value.map((permission) {
                    final isChecked = _permissions[permission] ?? false;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: _kPink,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) {
                            setState(() => _permissions[permission] = v ?? false);
                          },
                        ),
                        Text(
                          permission,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimingTab() {
    if (_isLoadingSalonHours) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<String> orderedDays = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('WEEKLY WORKING HOURS'),

          ...orderedDays.map((fullDay) {
            final abbr = dayFullToAbbr[fullDay]!;
            final isAvailable = _weeklyAvailability[fullDay] ?? false;

            final oh = _vendorProfile?.openingHours.firstWhere(
              (h) => h.day.toLowerCase() == fullDay.toLowerCase(),
              orElse: () => OpeningHour(
                day: fullDay,
                open: '09:00',
                close: '18:00',
                isOpen: true,
              ),
            );

            // Compute hour counts
            String hoursLabel = 'Off';
            if (isAvailable && _weeklyTiming[abbr]!.text.isNotEmpty) {
              final text = _weeklyTiming[abbr]!.text;
              final parts = text.split(' - ');
              if (parts.length == 2) {
                final sm = _timeToMinutes(parts[0]);
                final em = _timeToMinutes(parts[1]);
                final diff = em - sm;
                if (diff > 0) {
                  final hrs = (diff / 60).toStringAsFixed(1);
                  hoursLabel = '${hrs.replaceAll('.0', '')} Hrs';
                }
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fullDay.substring(0, 1).toUpperCase() + fullDay.substring(1),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            hoursLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: isAvailable ? _kPink : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isAvailable,
                            activeColor: _kPink,
                            onChanged: (v) {
                              setState(() {
                                _weeklyAvailability[fullDay] = v;
                                if (!v) {
                                  _weeklyTiming[abbr]!.clear();
                                } else if (_weeklyTiming[abbr]!.text.isEmpty) {
                                  if (oh != null && oh.isOpen) {
                                    _weeklyTiming[abbr]!.text = '${oh.open} - ${oh.close}';
                                  } else {
                                    _weeklyTiming[abbr]!.text = '10:00 - 19:00';
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isAvailable) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeRangePicker(
                            day: fullDay,
                            controller: _weeklyTiming[abbr]!,
                            salonHours: oh,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _TimeRangePicker extends StatefulWidget {
  final String day;
  final TextEditingController controller;
  final OpeningHour? salonHours;

  const _TimeRangePicker({
    required this.day,
    required this.controller,
    this.salonHours,
  });

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  TimeOfDay? start;
  TimeOfDay? end;

  @override
  void initState() {
    super.initState();
    _parseFromController();
  }

  void _parseFromController() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    final parts = text.split(' - ');
    if (parts.length == 2) {
      setState(() {
        start = _parseTime(parts[0]);
        end = _parseTime(parts[1]);
      });
    }
  }

  void _updateText() {
    if (start != null && end != null) {
      final now = DateTime.now();
      final dtStart = DateTime(now.year, now.month, now.day, start!.hour, start!.minute);
      final dtEnd = DateTime(now.year, now.month, now.day, end!.hour, end!.minute);
      widget.controller.text =
          '${DateFormat.jm().format(dtStart)} - ${DateFormat.jm().format(dtEnd)}';
    } else {
      widget.controller.text = '';
    }
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (start ?? const TimeOfDay(hour: 9, minute: 0))
          : (end ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      if (widget.salonHours != null && widget.salonHours!.isOpen) {
        final salonOpen = _parseTime(widget.salonHours!.open);
        final salonClose = _parseTime(widget.salonHours!.close);

        final staffTimeMins = picked.hour * 60 + picked.minute;
        final salonOpenMins = salonOpen.hour * 60 + salonOpen.minute;
        final salonCloseMins = salonClose.hour * 60 + salonClose.minute;

        if (staffTimeMins < salonOpenMins || staffTimeMins > salonCloseMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected time must be within salon hours (${widget.salonHours!.open} - ${widget.salonHours!.close})',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      setState(() {
        if (isStart) {
          start = picked;
        } else {
          end = picked;
        }
      });

      if (start != null && end != null) {
        final startMins = start!.hour * 60 + start!.minute;
        final endMins = end!.hour * 60 + end!.minute;
        if (startMins >= endMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start time must be before end time'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      _updateText();
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      try {
        final date = DateFormat.jm().parse(time.trim());
        return TimeOfDay(hour: date.hour, minute: date.minute);
      } catch (_) {
        final pts = time.split(':');
        return TimeOfDay(
          hour: int.parse(pts[0].trim()),
          minute: int.parse(pts[1].trim().split(' ')[0]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing time string ($time): $e');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pick(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    start?.format(context) ?? 'Start Time',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
                  ),
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('-', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _pick(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    end?.format(context) ?? 'End Time',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87),
                  ),
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
