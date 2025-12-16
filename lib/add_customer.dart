import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'customer_model.dart';

class AddCustomer extends StatefulWidget {
  final Customer? existing;
  
  const AddCustomer({super.key, this.existing});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to easily access form field values
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

  @override
  void initState() {
    super.initState();
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
      if (widget.existing!.dateOfBirth != null && widget.existing!.dateOfBirth!.isNotEmpty) {
        try {
          _dateOfBirth = DateFormat('dd/MM/yyyy').parse(widget.existing!.dateOfBirth!);
        } catch (e) {
          _dateOfBirth = null;
        }
      }
    }
  }
  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    // This triggers the validator on all TextFormFields
    if (_formKey.currentState!.validate()) {
      // If the form is valid, create a Customer object
      final newCustomer = Customer(
        id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _fullNameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        dateOfBirth: _dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!) : null,
        gender: _selectedGender,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        imagePath: _imagePath,
        totalBookings: widget.existing?.totalBookings ?? 0,
        totalSpent: widget.existing?.totalSpent ?? 0.0,
        status: widget.existing?.status ?? 'Active',
        createdAt: widget.existing?.createdAt,
        isOnline: _isOnline,
      );

      // Pop the screen and return the new customer object
      Navigator.pop(context, newCustomer);
    } else {
      // If the form is invalid, show an error snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
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
      setState(() => _dateOfBirth = d);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Customer' : 'Edit Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF4F4F4),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _imagePath != null && _imagePath!.isNotEmpty
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: FileImage(File(_imagePath!)),
                            )
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                              child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                            ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Choose Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      if (_imagePath != null && _imagePath!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _imagePath = null),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Remove'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: _buildInputDecoration("Full Name", Icons.person_outline),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _buildInputDecoration("Email Address", Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: _buildInputDecoration("Phone Number", Icons.phone_android_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 16),
              // Date of Birth
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _buildInputDecoration("Date of Birth", Icons.calendar_today_outlined),
                  child: Text(
                    _dateOfBirth == null ? 'Select date' : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
                    style: TextStyle(
                      color: _dateOfBirth == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration("Gender", Icons.wc_outlined),
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: _buildInputDecoration("Country", Icons.public_outlined),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _occupationController,
                decoration: _buildInputDecoration("Occupation", Icons.work_outline),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration("Address", Icons.location_on_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: _buildInputDecoration("Note", Icons.note_outlined),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text('Online Client', style: GoogleFonts.poppins(fontSize: 14)),
                subtitle: Text('Can book appointments online', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                value: _isOnline,
                onChanged: (val) => setState(() => _isOnline = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.blue,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: Text(
                  widget.existing == null ? "SAVE CUSTOMER" : "UPDATE CUSTOMER",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}