import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AddStaffDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const AddStaffDialog({Key? key, this.existing}) : super(key: key);

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
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

  // Permissions
  final Map<String, bool> _permissions = const {
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
  }.map((k, v) => MapEntry(k, v));

  // Timing
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

  String? _imagePath; // avatar

  final _personalFormKey = GlobalKey<FormState>();
  final _employmentFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    if (m != null) {
      _firstName.text = m['firstName'] ?? '';
      _lastName.text = m['lastName'] ?? '';
      _position.text = m['position'] ?? m['role'] ?? '';
      _mobile.text = m['mobile'] ?? m['phone'] ?? '';
      _email.text = m['email'] ?? '';
      _description.text = m['notes'] ?? '';
      _accHolder.text = m['accountHolder'] ?? '';
      _accNumber.text = m['accountNumber'] ?? '';
      _bankName.text = m['bankName'] ?? '';
      _ifsc.text = m['ifsc'] ?? '';
      _upi.text = m['upi'] ?? '';
      _salary.text = (m['salary'] ?? '').toString();
      _experience.text = (m['experience'] ?? '').toString();
      _clients.text = (m['clients'] ?? '').toString();
      final img = (m['image'] ?? '').toString();
      _imagePath = img.isNotEmpty ? img : null;
    }
  }

  @override
  void dispose() {
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
    for (final c in _weeklyTiming.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: start ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.blue,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              dayStyle: GoogleFonts.poppins(fontSize: 14),
              yearStyle: GoogleFonts.poppins(fontSize: 16),
            ),
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      setState(() {
        if (start) {
          _startDate = d;
        } else {
          _endDate = d;
        }
      });
    }
  }

  Future<void> _pickBlockDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _blockDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.blue,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              dayStyle: GoogleFonts.poppins(fontSize: 14),
              yearStyle: GoogleFonts.poppins(fontSize: 16),
            ),
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _blockDate = d);
  }

  Future<void> _pickBlockTime(bool start) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() {
        if (start) {
          _blockStart = t;
        } else {
          _blockEnd = t;
        }
      });
    }
  }

  void _nextTab(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    if (tabController.index < 5) {
      tabController.animateTo(tabController.index + 1);
    }
  }

  void _prevTab(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    if (tabController.index > 0) {
      tabController.animateTo(tabController.index - 1);
    }
  }

  void _save() {
    if (!_personalFormKey.currentState!.validate()) {
      // Navigate to Personal tab if validation fails
      final tabController = DefaultTabController.maybeOf(context);
      if (tabController != null) {
        tabController.animateTo(0);
      }
      return;
    }

    final id = widget.existing != null
        ? (widget.existing!['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
        : DateTime.now().millisecondsSinceEpoch.toString();

    final result = <String, dynamic>{
      'id': id,
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'role': _position.text.trim(),
      'position': _position.text.trim(),
      'notes': _description.text.trim(),
      'phone': _mobile.text.trim(),
      'mobile': _mobile.text.trim(),
      'email': _email.text.trim(),
      'accountHolder': _accHolder.text.trim(),
      'accountNumber': _accNumber.text.trim(),
      'bankName': _bankName.text.trim(),
      'ifsc': _ifsc.text.trim(),
      'upi': _upi.text.trim(),
      'salary': _salary.text.trim(),
      'joiningDate': _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : '',
      'commission': _commissionEnabled ? 'enabled' : 'disabled',
      'experience': _experience.text.trim(),
      'clients': _clients.text.trim(),
      'image': _imagePath ?? '',
      'status': widget.existing != null ? (widget.existing!['status'] ?? 'Active') : 'Active',
      'permissions': Map<String, bool>.from(_permissions),
      'timing': _weeklyTiming.map((k, v) => MapEntry(k, v.text)),
      'blockTime': {
        'date': _blockDate != null ? DateFormat('dd/MM/yyyy').format(_blockDate!) : '',
        'start': _blockStart?.format(context) ?? '',
        'end': _blockEnd?.format(context) ?? '',
        'reason': _blockReason.text.trim(),
      },
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      dialogBackgroundColor: Colors.white,
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(fontSizeFactor: 0.95),
    );

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final dialogW = screenW < 960.0 ? screenW - 32.0 : 920.0;
    final dialogH = screenH < 700.0 ? screenH - 48.0 : 680.0;

    return Theme(
      data: theme,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SizedBox(
          width: dialogW,
          height: dialogH,
          child: DefaultTabController(
            length: 6,
            initialIndex: 0,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.existing == null ? 'Add New Staff Member' : 'Edit Staff Member',
                        style: GoogleFonts.poppins(fontSize: 16.0, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),

                // Tabs
                Material(
                  color: Colors.white,
                  child: const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Personal'),
                      Tab(text: 'Employment'),
                      Tab(text: 'Bank Details'),
                      Tab(text: 'Permissions'),
                      Tab(text: 'Timing'),
                      Tab(text: 'Block Time'),
                    ],
                  ),
                ),

                // Content with white background
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Personal Tab
                        _buildPersonalTab(),
                        // Employment Tab
                        _buildEmploymentTab(),
                        // Bank Details Tab
                        _buildBankTab(),
                        // Permissions Tab
                        _buildPermissionsTab(),
                        // Timing Tab
                        _buildTimingTab(),
                        // Block Time Tab
                        _buildBlockTimeTab(),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
                  ),
                  child: Builder(
                    builder: (BuildContext footerContext) {
                      return Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _prevTab(footerContext),
                            child: const Text('Previous'),
                          ),
                          const SizedBox(width: 8.0),
                          TextButton(
                            onPressed: () => _nextTab(footerContext),
                            child: const Text('Next'),
                          ),
                          const SizedBox(width: 16.0),
                          ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _personalFormKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth > 900 ? 420.0 : (constraints.maxWidth - 32) / 2;
              return Wrap(
                spacing: 16.0,
                runSpacing: 12.0,
                children: [
                  _Labeled(
                    'First Name',
                    field: TextFormField(
                      controller: _firstName,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                    ),
                    width: fieldWidth,
                  ),
                  _Labeled('Last Name', field: TextFormField(controller: _lastName), width: fieldWidth),
                  _Labeled('Position', field: TextFormField(controller: _position), width: fieldWidth),
                  _Labeled(
                    'Mobile Number',
                    field: TextFormField(controller: _mobile, keyboardType: TextInputType.phone),
                    width: fieldWidth,
                  ),
                  _Labeled(
                    'Email Address',
                    field: TextFormField(controller: _email, keyboardType: TextInputType.emailAddress),
                    width: fieldWidth,
                  ),
                  _Labeled(
                    'Password',
                    field: TextFormField(controller: _password, obscureText: true),
                    width: fieldWidth,
                  ),
                  _Labeled(
                    'Confirm Password',
                    field: TextFormField(
                      controller: _confirmPassword,
                      obscureText: true,
                      validator: (v) {
                        if (_password.text.isNotEmpty && v != _password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    width: fieldWidth,
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photo', style: GoogleFonts.poppins(fontSize: 12.0, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            _imagePath != null && _imagePath!.isNotEmpty
                                ? CircleAvatar(radius: 28.0, backgroundImage: FileImage(File(_imagePath!)))
                                : const CircleAvatar(radius: 28.0, child: Icon(Icons.person)),
                            const SizedBox(width: 12.0),
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library_outlined, size: 18.0),
                              label: const Text('Choose Image'),
                            ),
                            if (_imagePath != null && _imagePath!.isNotEmpty) ...[
                              const SizedBox(width: 8.0),
                              TextButton.icon(
                                onPressed: () => setState(() => _imagePath = null),
                                icon: const Icon(Icons.close),
                                label: const Text('Remove'),
                              ),
                            ],
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: GoogleFonts.poppins(fontSize: 12.0, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6.0),
                        TextFormField(
                          controller: _description,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'Enter staff description'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmploymentTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _employmentFormKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth > 900 ? 420.0 : (constraints.maxWidth - 32) / 2;
              return Wrap(
                spacing: 16.0,
                runSpacing: 12.0,
                children: [
                  _Labeled(
                    'Salary',
                    field: TextFormField(controller: _salary, keyboardType: TextInputType.number),
                    width: fieldWidth,
                  ),
                  _Labeled(
                    'Years of Experience',
                    field: TextFormField(controller: _experience, keyboardType: TextInputType.number),
                    width: fieldWidth,
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: GoogleFonts.poppins(fontSize: 12.0, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _startDate == null ? 'Not selected' : DateFormat('dd/MM/yyyy').format(_startDate!),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            OutlinedButton(onPressed: () => _pickDate(start: true), child: const Text('Pick')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Date (optional)', style: GoogleFonts.poppins(fontSize: 12.0, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _endDate == null ? 'Not selected' : DateFormat('dd/MM/yyyy').format(_endDate!),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            OutlinedButton(onPressed: () => _pickDate(start: false), child: const Text('Pick')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Labeled(
                    'Clients Served',
                    field: TextFormField(controller: _clients, keyboardType: TextInputType.number),
                    width: fieldWidth,
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Commission', style: GoogleFonts.poppins(fontSize: 12.0, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            const Text('Enable Staff Commission'),
                            const SizedBox(width: 12.0),
                            Switch(
                              value: _commissionEnabled,
                              onChanged: (v) => setState(() => _commissionEnabled = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBankTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _bankFormKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth > 900 ? 420.0 : (constraints.maxWidth - 32) / 2;
              return Wrap(
                spacing: 16.0,
                runSpacing: 12.0,
                children: [
                  _Labeled('Account Holder Name', field: TextFormField(controller: _accHolder), width: fieldWidth),
                  _Labeled(
                    'Account Number',
                    field: TextFormField(controller: _accNumber, keyboardType: TextInputType.number),
                    width: fieldWidth,
                  ),
                  _Labeled('Bank Name', field: TextFormField(controller: _bankName), width: fieldWidth),
                  _Labeled('IFSC Code', field: TextFormField(controller: _ifsc), width: fieldWidth),
                  _Labeled('UPI ID', field: TextFormField(controller: _upi), width: fieldWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permissions', style: GoogleFonts.poppins(fontSize: 14.0, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12.0),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 4.5,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final key = _permissions.keys.elementAt(index);
                    return CheckboxListTile(
                      value: _permissions[key],
                      onChanged: (v) => setState(() => _permissions[key] = v ?? false),
                      title: Text(key, style: GoogleFonts.poppins(fontSize: 11)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Working Hours', style: GoogleFonts.poppins(fontSize: 14.0, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12.0),
            Column(
              children: _weeklyTiming.keys.map((day) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80.0,
                        child: Text(day, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: _TimeRangePicker(
                          day: day,
                          onTimeSelected: (start, end) {
                            _weeklyTiming[day]!.text = start != null && end != null
                                ? '${start.format(context)} - ${end.format(context)}'
                                : '';
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockTimeTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Block Time', style: GoogleFonts.poppins(fontSize: 14.0, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _blockDate == null ? 'No date chosen' : DateFormat('dd/MM/yyyy').format(_blockDate!),
                  ),
                ),
                const SizedBox(width: 8.0),
                OutlinedButton(onPressed: _pickBlockDate, child: const Text('Pick Date')),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(child: Text(_blockStart == null ? 'Start time' : _blockStart!.format(context))),
                const SizedBox(width: 8.0),
                OutlinedButton(onPressed: () => _pickBlockTime(true), child: const Text('Pick Start')),
                const SizedBox(width: 16.0),
                Expanded(child: Text(_blockEnd == null ? 'End time' : _blockEnd!.format(context))),
                const SizedBox(width: 8.0),
                OutlinedButton(onPressed: () => _pickBlockTime(false), child: const Text('Pick End')),
              ],
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _blockReason,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget field;
  final double? width;

  const _Labeled(this.label, {required this.field, this.width, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 420.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12.0, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6.0),
          field,
        ],
      ),
    );
  }
}

class _TimeRangePicker extends StatefulWidget {
  final String day;
  final Function(TimeOfDay?, TimeOfDay?) onTimeSelected;

  const _TimeRangePicker({required this.day, required this.onTimeSelected, Key? key}) : super(key: key);

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100, width: 1),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100, width: 1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
      widget.onTimeSelected(_startTime, _endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.blue.shade50,
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      _startTime?.format(context) ?? 'Start',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _startTime != null ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade600),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.blue.shade50,
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      _endTime?.format(context) ?? 'End',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _endTime != null ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_startTime != null || _endTime != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _startTime = null;
                  _endTime = null;
                });
                widget.onTimeSelected(null, null);
              },
            ),
        ],
      ),
    );
  }
}
