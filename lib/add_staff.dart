import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddStaffDialog extends StatefulWidget { 
  final Map? existing; // raw API staff object for edit

  const AddStaffDialog({Key? key, this.existing}) : super(key: key);

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog>
    with SingleTickerProviderStateMixin {
  // Personal
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _position = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _description = TextEditingController();

  // Employment
  final _salary = TextEditingController();
  final _experience = TextEditingController();
  final _clients = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _commissionEnabled = false;

  // Bank
  final _accHolder = TextEditingController();
  final _accNumber = TextEditingController();
  final _bankName = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();

  // Permissions (display name -> checked)
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

  // Block time
  DateTime? _blockDate;
  TimeOfDay? _blockStart;
  TimeOfDay? _blockEnd;
  final _blockReason = TextEditingController();

  // Photo (either http url or local file path)
  String? _imagePath;

  // Form keys per tab
  final _personalFormKey = GlobalKey<FormState>();
  final _employmentFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();
  final _blockFormKey = GlobalKey<FormState>();

  late final TabController _tabController;

  // Mapping: Display permission -> API permission string
  static const Map<String, String> displayToPerm = {
    'Dashboard': 'DashboardPage',
    'Calendar': 'CalendarPage',
    'Appointments': 'AppointmentsPage',
    'Staff': 'StaffPage',
    'Products': 'ProductsPage',
    'Orders': 'OrdersPage',
    'Offers & Coupons': 'OffersAndCouponsPage',
    'Notifications': 'NotificationsPage',
    'Clients': 'ClientsPage',
    'Marketplace': 'MarketplacePage',
    'Shipping': 'ShippingPage',
    'Referrals': 'ReferralsPage',
    'Reports': 'ReportsPage',
    'Services': 'ServicesPage',
    'Sales': 'SalesPage',
    'Settlements': 'SettlementsPage',
    'Marketing': 'MarketingPage',
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

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    if (widget.existing != null) {
      final m = widget.existing!;

      // Personal
      final fullName = m['fullName'] ?? '';
      final parts = fullName.toString().split(RegExp(r'\s+'));
      _firstName.text = parts.isNotEmpty ? parts.first : '';
      _lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _position.text = m['position'] ?? '';
      _mobile.text = m['mobileNo'] ?? '';
      _email.text = m['emailAddress'] ?? '';
      _description.text = m['description'] ?? '';

      // Employment
      _salary.text = (m['salary'] ?? '').toString();
      _experience.text = (m['yearOfExperience'] ?? '').toString();
      _clients.text = (m['clientsServed'] ?? '').toString();
      _commissionEnabled = m['commission'] == true;

      if (m['startDate'] != null) _startDate = DateTime.tryParse(m['startDate'].toString());
      if (m['endDate'] != null) _endDate = DateTime.tryParse(m['endDate'].toString());

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
        final available = m['${fullDay}Available'] == true;
        final slots = (m['${fullDay}Slots'] as List?) ?? [];
        if (available && slots.isNotEmpty) {
          final slot = (slots.first as Map?) ?? {};
          final start = (slot['startTime'] ?? '10:00').toString();
          final end = (slot['endTime'] ?? '19:00').toString();
          _weeklyTiming[abbr]!.text = '$start - $end';
        }
      }

      // Blocked Times
      final blocked = (m['blockedTimes'] as List?) ?? [];
      if (blocked.isNotEmpty) {
        final b = (blocked.first as Map?) ?? {};
        _blockDate = DateTime.tryParse((b['startDate'] ?? '').toString());

        final startStr = b['startTime']?.toString();
        final endStr = b['endTime']?.toString();
        if (startStr != null && startStr.contains(':')) {
          final sp = startStr.split(':');
          _blockStart = TimeOfDay(hour: int.parse(sp[0]), minute: int.parse(sp[1]));
        }
        if (endStr != null && endStr.contains(':')) {
          final ep = endStr.split(':');
          _blockEnd = TimeOfDay(hour: int.parse(ep[0]), minute: int.parse(ep[1]));
        }

        _blockReason.text = (b['reason'] ?? '').toString();
      }

      // Photo
      if (m['photo'] != null && m['photo'].toString().isNotEmpty) {
        _imagePath = m['photo'].toString();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

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

    _accHolder.dispose();
    _accNumber.dispose();
    _bankName.dispose();
    _ifsc.dispose();
    _upi.dispose();

    _blockReason.dispose();
    _weeklyTiming.values.forEach((c) => c.dispose());

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
        if (start) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _pickBlockDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _blockDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _blockDate = picked);
  }

  Future<void> _pickBlockTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        if (isStart) _blockStart = picked;
        else _blockEnd = picked;
      });
    }
  }

  void _nextTab() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  void _prevTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  bool _validateAll() {
    final personalOk = _personalFormKey.currentState?.validate() ?? true;
    final employmentOk = _employmentFormKey.currentState?.validate() ?? true;
    final bankOk = _bankFormKey.currentState?.validate() ?? true;
    final blockOk = _blockFormKey.currentState?.validate() ?? true;

    if (!personalOk) {
      _tabController.animateTo(0);
      return false;
    }
    if (!employmentOk) {
      _tabController.animateTo(1);
      return false;
    }
    if (!bankOk) {
      _tabController.animateTo(2);
      return false;
    }
    if (!blockOk) {
      _tabController.animateTo(5);
      return false;
    }

    // Extra password checks for new staff
    if (widget.existing == null) {
      if (_password.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password is required for new staff'), backgroundColor: Colors.red),
        );
        _tabController.animateTo(0);
        return false;
      }
      if (_password.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
        );
        _tabController.animateTo(0);
        return false;
      }
      if (_confirmPassword.text != _password.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
        );
        _tabController.animateTo(0);
        return false;
      }
    } else {
      // On edit, password is optional; if user enters it, validate it
      if (_password.text.trim().isNotEmpty) {
        if (_password.text.trim().length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
          );
          _tabController.animateTo(0);
          return false;
        }
        if (_confirmPassword.text != _password.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
          );
          _tabController.animateTo(0);
          return false;
        }
      }
    }

    return true;
  }

  void _save() {
    if (!_validateAll()) return;

    final fullName = '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();

    // Permissions -> API list
    final List<String> permissions = _permissions.entries
    .where((e) => e.value)
    .map((e) => displayToPerm[e.key]!)
    .toList();
    

    // Availability format
    final Map<String, dynamic> availability = {};
    _weeklyTiming.forEach((abbr, controller) {
      final text = controller.text.trim();
      if (text.isEmpty) return;
      final parts = text.split(' - ');
      if (parts.length != 2) return;

      final fullDay = dayAbbrToFull[abbr]!;
      availability[fullDay] = {
        "available": true,
        "slots": [
          {"startTime": parts[0].trim(), "endTime": parts[1].trim()}
        ]
      };
    });

    // Blocked times
    final List<Map<String, dynamic>> blockedTimes = [];
    if (_blockDate != null &&
        _blockStart != null &&
        _blockEnd != null &&
        _blockReason.text.trim().isNotEmpty) {
      blockedTimes.add({
        'startDate': DateFormat('yyyy-MM-dd').format(_blockDate!),
        'endDate': DateFormat('yyyy-MM-dd').format(_blockDate!),
        'startTime': _formatTime(_blockStart),
        'endTime': _formatTime(_blockEnd),
        'reason': _blockReason.text.trim(),
      });
    }

    // Bank details
    final Map<String, dynamic> bankDetails = {
      "accountHolderName": _accHolder.text.trim(),
      "accountNumber": _accNumber.text.trim(),
      "bankName": _bankName.text.trim(),
      "ifscCode": _ifsc.text.trim(),
      "upiId": _upi.text.trim(),
    };

    // Numeric fields
    final int salary = int.tryParse(_salary.text.trim()) ?? 0;
    final int yearOfExperience = int.tryParse(_experience.text.trim()) ?? 0;
    final int clientsServed = int.tryParse(_clients.text.trim()) ?? 0;

    // Dates
    final String? startDate = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final String? endDate = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    // Password (optional on edit)
    String? password;
    if (widget.existing == null) {
      password = _password.text.trim();
    } else {
      if (_password.text.trim().isNotEmpty) password = _password.text.trim();
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
      'permissions': permissions,
      'permission': permissions,
      'availability': availability,
      'blockedTimes': blockedTimes,
      'bankDetails': bankDetails,
      'userType': 'staff',
      if (password != null) 'password': password,

      // IMPORTANT: this is only useful if backend accepts string photo in JSON
      // If imagePath is local file path, backend won't understand unless you upload it separately.
      if (_imagePath != null) 'photo': _imagePath,
    };

    // keep id for edit
    if (widget.existing != null) {
      result['id'] = widget.existing!['_id'];
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW < 960 ? screenW - 32 : 920.0;
    final dialogH = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogW,
        height: dialogH,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.existing == null ? 'Add New Staff' : 'Edit Staff',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Employment'),
                Tab(text: 'Bank Details'),
                Tab(text: 'Permissions'),
                Tab(text: 'Timing'),
                Tab(text: 'Block Time'),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(),
                  _buildEmploymentTab(),
                  _buildBankTab(),
                  _buildPermissionsTab(),
                  _buildTimingTab(),
                  _buildBlockTimeTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  Row(
                    children: [
                      TextButton(onPressed: _prevTab, child: const Text('Previous')),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _nextTab, child: const Text('Next')),
                      const SizedBox(width: 16),
                      ElevatedButton(onPressed: _save, child: const Text('Save')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _labeled(
                    'First Name',
                    TextFormField(
                      controller: _firstName,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _labeled('Last Name', TextFormField(controller: _lastName))),
              ],
            ),
            _labeled(
              'Position',
              TextFormField(
                controller: _position,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Position is required' : null,
              ),
            ),
            _labeled(
              'Mobile Number',
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                  if (v.trim().length < 10) return 'Enter a valid mobile number';
                  return null;
                },
              ),
            ),
            _labeled(
              'Email Address',
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final ok = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim());
                  if (!ok) return 'Enter a valid email address';
                  return null;
                },
              ),
            ),
            // Password always shown; on edit it's optional
            _labeled(
              'Password ${widget.existing == null ? "(Required)" : "(Optional)"}',
              TextFormField(
                controller: _password,
                obscureText: true,
                validator: (v) {
                  if (widget.existing == null) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.trim().length < 6) return 'Password must be at least 6 characters';
                  } else {
                    if (v != null && v.trim().isNotEmpty && v.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                  }
                  return null;
                },
              ),
            ),
            _labeled(
              'Confirm Password ${widget.existing == null ? "(Required)" : "(If changing password)"}',
              TextFormField(
                controller: _confirmPassword,
                obscureText: true,
                validator: (v) {
                  if (widget.existing == null) {
                    if (v == null || v.isEmpty) return 'Confirm password is required';
                    if (v != _password.text) return 'Passwords do not match';
                  } else {
                    if (_password.text.trim().isNotEmpty) {
                      if (v != _password.text) return 'Passwords do not match';
                    }
                  }
                  return null;
                },
              ),
            ),
            _labeled('Description', TextFormField(controller: _description, maxLines: 3)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _imagePath != null
                      ? (_imagePath!.startsWith('http')
                          ? NetworkImage(_imagePath!)
                          : FileImage(File(_imagePath!)) as ImageProvider)
                      : null,
                  child: _imagePath == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Upload Photo'),
                    ),
                    if (_imagePath != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _imagePath = null),
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove'),
                      ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentTab() {
    return Form(
      key: _employmentFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _labeled(
                    'Salary',
                    TextFormField(
                      controller: _salary,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // optional
                        if (double.tryParse(v.trim()) == null) return 'Enter a valid salary';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _labeled(
                    'Years of Experience',
                    TextFormField(
                      controller: _experience,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // optional
                        if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _labeled(
                    'Clients Served',
                    TextFormField(
                      controller: _clients,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // optional
                        if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Commission', style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: _commissionEnabled,
                        onChanged: (v) => setState(() => _commissionEnabled = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _DateField(label: 'Start Date', date: _startDate, onTap: () => _pickDate(start: true))),
                const SizedBox(width: 16),
                Expanded(child: _DateField(label: 'End Date (Optional)', date: _endDate, onTap: () => _pickDate(start: false))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTab() {
    return Form(
      key: _bankFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _labeled(
              'Account Holder Name',
              TextFormField(
                controller: _accHolder,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Account holder name is required';
                  return null;
                },
              ),
            ),
            _labeled(
              'Account Number',
              TextFormField(
                controller: _accNumber,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Account number is required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a valid account number';
                  return null;
                },
              ),
            ),
            _labeled(
              'Bank Name',
              TextFormField(
                controller: _bankName,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bank name is required' : null,
              ),
            ),
            _labeled(
              'IFSC Code',
              TextFormField(
                controller: _ifsc,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'IFSC code is required' : null,
              ),
            ),
            _labeled(
              'UPI ID',
              TextFormField(
                controller: _upi,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'UPI ID is required' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: _permissions.keys.map((key) {
          return SizedBox(
            width: 200,
            child: CheckboxListTile(
              title: Text(key),
              value: _permissions[key],
              onChanged: (v) => setState(() => _permissions[key] = v ?? false),
              dense: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _weeklyTiming.keys.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(day, style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 16),
                Expanded(child: _TimeRangePicker(day: day, controller: _weeklyTiming[day]!)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBlockTimeTab() {
    return Form(
      key: _blockFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateField(label: 'Block Date', date: _blockDate, onTap: _pickBlockDate),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _TimeField(label: 'Start Time', time: _blockStart, onTap: () => _pickBlockTime(true))),
                const SizedBox(width: 16),
                Expanded(child: _TimeField(label: 'End Time', time: _blockEnd, onTap: () => _pickBlockTime(false))),
              ],
            ),
            const SizedBox(height: 16),
            _labeled(
              'Reason',
              TextFormField(
                controller: _blockReason,
                // Optional; if user fills time/date then reason should be required (handled in _save by checking trim)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget field) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            field,
          ],
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: Text(date == null ? 'Not set' : DateFormat('dd/MM/yyyy').format(date!))),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: Text(time?.format(context) ?? 'Not set')),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeRangePicker extends StatefulWidget {
  final String day;
  final TextEditingController controller;

  const _TimeRangePicker({required this.day, required this.controller});

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  TimeOfDay? start;
  TimeOfDay? end;

  void _updateText() {
    if (start != null && end != null) {
      widget.controller.text = '${start!.format(context)} - ${end!.format(context)}';
    } else {
      widget.controller.text = '';
    }
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        if (isStart) start = picked;
        else end = picked;
      });
      _updateText();
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              child: Text(start?.format(context) ?? 'Start', textAlign: TextAlign.center),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
        Expanded(
          child: InkWell(
            onTap: () => _pick(false),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              child: Text(end?.format(context) ?? 'End', textAlign: TextAlign.center),
            ),
          ),
        ),
        if (start != null || end != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                start = null;
                end = null;
              });
              widget.controller.clear();
            },
          ),
      ],
    );
  }
}
