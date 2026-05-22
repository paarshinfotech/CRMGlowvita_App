import 'package:flutter/material.dart';
import 'package:glowvita/utils/validators.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'customer_model.dart';
import 'services/api_service.dart';

class AddCustomer extends StatefulWidget {
  final Customer? existing;

  const AddCustomer({super.key, this.existing});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  String? _imagePath;
  bool _isOnline = false;
  bool _isSaving = false;

  // Track which fields have been touched for real-time validation
  final Set<String> _touchedFields = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (widget.existing != null) {
      _fullNameController.text = widget.existing!.fullName;
      _mobileController.text = widget.existing!.mobile;
      _emailController.text = widget.existing!.email ?? '';
      _countryController.text = widget.existing!.country ?? '';
      _occupationController.text = widget.existing!.occupation ?? '';
      _addressController.text = widget.existing!.address ?? '';
      _noteController.text = widget.existing!.note ?? '';
      _selectedGender = widget.existing!.gender;
      _imagePath = widget.existing!.imagePath;
      _isOnline = widget.existing!.isOnline;
      if (widget.existing!.dateOfBirth != null &&
          widget.existing!.dateOfBirth!.isNotEmpty) {
        try {
          _dateOfBirth = DateFormat(
            'dd/MM/yyyy',
          ).parse(widget.existing!.dateOfBirth!);
        } catch (e) {
          _dateOfBirth = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    // Mark all key fields as touched to trigger inline validation display
    setState(() {
      _touchedFields.addAll(['fullName', 'mobile', 'email']);
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final newCustomer = Customer(
        id: widget.existing?.id,
        vendorId: null,
        fullName: _fullNameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        dateOfBirth: _dateOfBirth != null
            ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
            : null,
        gender: _selectedGender,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
        occupation: _occupationController.text.trim().isNotEmpty
            ? _occupationController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        imagePath: _imagePath,
        totalBookings: widget.existing?.totalBookings ?? 0,
        totalSpent: widget.existing?.totalSpent ?? 0.0,
        status: widget.existing?.status ?? 'New',
        createdAt: widget.existing?.createdAt,
        updatedAt: widget.existing?.updatedAt,
        isOnline: _isOnline,
        source: _isOnline ? 'online' : 'offline',
      );

      try {
        if (widget.existing != null) {
          final updatedCustomer = await ApiService.updateClient(newCustomer);
          if (mounted) Navigator.pop(context, updatedCustomer);
        } else {
          final addedCustomer = await ApiService.addClient(newCustomer);
          if (mounted) Navigator.pop(context, addedCustomer);
        }
      } catch (e) {
        print('Error saving customer: $e');
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().contains('No authentication token found')
                    ? 'Session expired. Please log in again.'
                    : 'Failed to save customer. Please try again.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  /// Consistent input decoration with refined styling
  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    String? helperText,
  }) {
    final primary = Theme.of(context).primaryColor;
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: primary, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.grey.shade600,
      ),
      helperStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
      errorStyle: GoogleFonts.poppins(
        fontSize: 11,
        color: const Color(0xFFE53935),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.8),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Theme.of(context).primaryColor,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              dayStyle: GoogleFonts.poppins(fontSize: 14),
              yearStyle: GoogleFonts.poppins(fontSize: 16),
            ),
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _dateOfBirth = d);
  }

  // ─── Section header helper ───────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
        ],
      ),
    );
  }

  // ─── Card wrapper ─────────────────────────────────────────────────────────
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Customer' : 'Add Customer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Avatar Card ─────────────────────────────────────────
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        'Profile Photo',
                        Icons.camera_alt_outlined,
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              _imagePath != null && _imagePath!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 44,
                                      backgroundImage: FileImage(
                                        File(_imagePath!),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 44,
                                      backgroundColor: primary.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 44,
                                        color: primary.withOpacity(0.5),
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: primary,
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Choose Image',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    side: BorderSide(color: primary),
                                    foregroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                if (_imagePath != null &&
                                    _imagePath!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _imagePath = null),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                    ),
                                    label: Text(
                                      'Remove',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Basic Info Card ──────────────────────────────────────
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Basic Information', Icons.badge_outlined),
                      // Full Name — validated with name regex
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          "Full Name *",
                          Icons.person_outline,
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                        onChanged: (_) =>
                            setState(() => _touchedFields.add('fullName')),
                        validator: (value) =>
                            Validators.validateName(value, 'Full Name'),
                      ),
                      const SizedBox(height: 14),
                      // Email — validated (optional field: only validates format if filled)
                      TextFormField(
                        controller: _emailController,
                        decoration: _buildInputDecoration(
                          "Email Address",
                          Icons.email_outlined,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(fontSize: 14),
                        onChanged: (_) =>
                            setState(() => _touchedFields.add('email')),
                        validator: (value) {
                          // Email is optional — only validate format if filled
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Mobile — validated: required + 10 digits
                      TextFormField(
                        controller: _mobileController,
                        decoration: _buildInputDecoration(
                          "Phone Number *",
                          Icons.phone_android_outlined,
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: GoogleFonts.poppins(fontSize: 14),
                        onChanged: (_) =>
                            setState(() => _touchedFields.add('mobile')),
                        validator: (value) => Validators.validatePhone(value),
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null, // hide the counter
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Personal Details Card ────────────────────────────────
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        'Personal Details',
                        Icons.person_pin_outlined,
                      ),
                      // Date of Birth
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: _buildInputDecoration(
                            "Date of Birth",
                            Icons.calendar_today_outlined,
                          ),
                          child: Text(
                            _dateOfBirth == null
                                ? 'Select date'
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_dateOfBirth!),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _dateOfBirth == null
                                  ? Colors.grey.shade500
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Gender
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration(
                          "Gender",
                          Icons.wc_outlined,
                        ),
                        value: _selectedGender,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primary,
                        ),
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(
                            value: "Female",
                            child: Text("Female"),
                          ),
                          DropdownMenuItem(
                            value: "Other",
                            child: Text("Other"),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ),
                      const SizedBox(height: 14),
                      // Country
                      TextFormField(
                        controller: _countryController,
                        decoration: _buildInputDecoration(
                          "Country",
                          Icons.public_outlined,
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      // Occupation
                      TextFormField(
                        controller: _occupationController,
                        decoration: _buildInputDecoration(
                          "Occupation",
                          Icons.work_outline,
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Address & Notes Card ─────────────────────────────────
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        'Address & Notes',
                        Icons.location_on_outlined,
                      ),
                      TextFormField(
                        controller: _addressController,
                        decoration: _buildInputDecoration(
                          "Address",
                          Icons.home_outlined,
                        ),
                        maxLines: 2,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        decoration: _buildInputDecoration(
                          "Note",
                          Icons.note_alt_outlined,
                        ),
                        maxLines: 3,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Save Button ──────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor: primary.withOpacity(0.4),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isEdit ? 'UPDATE CUSTOMER' : 'SAVE CUSTOMER',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
