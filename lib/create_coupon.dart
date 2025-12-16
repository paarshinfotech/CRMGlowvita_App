import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreateCouponPage extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  
  const CreateCouponPage({super.key, required this.services});

  @override
  State<CreateCouponPage> createState() => _CreateCouponPageState();
}

class _CreateCouponPageState extends State<CreateCouponPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _discountValueController = TextEditingController();
  
  // Form state
  bool _useCustomCode = false;
  String _discountType = 'Percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  
  List<String> _selectedServices = [];
  List<String> _selectedCategories = [];
  String _selectedGender = 'All';
  String? _selectedImage;
  
  // Available options
  final List<String> _discountTypes = ['Percentage', 'Fixed Amount'];
  final List<String> _genders = ['All', 'Men', 'Women', 'Unisex'];
  
  @override
  void initState() {
    super.initState();
    // Initialize with all services selected
    _selectedServices = widget.services.map((s) => s['name'] as String).toList();
    // Initialize with all categories selected
    final categories = <String>{};
    for (var service in widget.services) {
      if (service['category'] is String) {
        categories.add(service['category'] as String);
      }
    }
    _selectedCategories = categories.toList();
  }
  
  @override
  void dispose() {
    _couponCodeController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }
  
  List<String> get _availableCategories {
    final categories = <String>{};
    for (var service in widget.services) {
      if (service['category'] is String) {
        categories.add(service['category'] as String);
      }
    }
    return categories.toList();
  }
  
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  
  void _toggleServiceSelection(String serviceName) {
    setState(() {
      if (_selectedServices.contains(serviceName)) {
        _selectedServices.remove(serviceName);
      } else {
        _selectedServices.add(serviceName);
      }
      
      // Update categories based on selected services
      _updateCategoriesBasedOnServices();
    });
  }
  
  void _toggleCategorySelection(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }
  
  void _updateCategoriesBasedOnServices() {
    final categories = <String>{};
    for (var service in widget.services) {
      if (_selectedServices.contains(service['name'])) {
        if (service['category'] is String) {
          categories.add(service['category'] as String);
        }
      }
    }
    setState(() {
      _selectedCategories = categories.toList();
    });
  }
  
  void _saveCoupon() {
    if (_formKey.currentState!.validate()) {
      // Prepare coupon data
      final couponData = {
        'code': _useCustomCode ? _couponCodeController.text : _generateUniqueCode(),
        'discountType': _discountType,
        'discountValue': double.tryParse(_discountValueController.text) ?? 0.0,
        'status': _startDate.isAfter(DateTime.now()) ? 'Scheduled' : 'Active',
        'startsOn': _startDate,
        'expiresOn': _endDate,
        'services': _selectedServices.isEmpty ? 'All Services' : _selectedServices.join(', '),
        'categories': _selectedCategories.isEmpty ? 'All' : _selectedCategories.join(', '),
        'genders': _selectedGender,
        'image': _selectedImage,
        'redeemed': 0,
      };
      
      // Return the coupon data to the previous screen
      Navigator.pop(context, couponData);
    }
  }
  
  String _generateUniqueCode() {
    // Simple code generation - in a real app, you might want a more robust solution
    final now = DateTime.now();
    return 'COUPON${now.millisecondsSinceEpoch.toString().substring(6)}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Create New Coupon',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the details for the new coupon.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Custom Coupon Code
                Row(
                  children: [
                    Checkbox(
                      value: _useCustomCode,
                      onChanged: (value) {
                        setState(() {
                          _useCustomCode = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Use custom coupon code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                if (_useCustomCode)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    child: TextFormField(
                      controller: _couponCodeController,
                      decoration: InputDecoration(
                        labelText: 'Coupon Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (_useCustomCode && (value == null || value.isEmpty)) {
                          return 'Please enter a coupon code';
                        }
                        return null;
                      },
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Discount Type
                Text(
                  'Discount Type',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _discountType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _discountTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _discountType = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Discount Value
                Text(
                  'Discount Value',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _discountType == 'Percentage' ? 'Percentage (%)' : 'Amount (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a discount value';
                    }
                    final numValue = double.tryParse(value);
                    if (numValue == null || numValue <= 0) {
                      return 'Please enter a valid discount value';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Date Range
                Text(
                  'Validity Period',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_startDate),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'to',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_endDate),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Applicable Services
                Text(
                  'Applicable Services',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select specific services or leave empty for all',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.services.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'No services available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _selectedServices.length == widget.services.length,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedServices = widget.services.map((s) => s['name'] as String).toList();
                                  } else {
                                    _selectedServices.clear();
                                  }
                                  _updateCategoriesBasedOnServices();
                                });
                              },
                            ),
                            const Text(
                              'Select all services',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        SizedBox(
                          height: 150,
                          child: ListView(
                            children: widget.services.map((service) {
                              final serviceName = service['name'] as String;
                              return CheckboxListTile(
                                value: _selectedServices.contains(serviceName),
                                onChanged: (value) {
                                  _toggleServiceSelection(serviceName);
                                },
                                title: Text(
                                  serviceName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  service['category'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Applicable Categories
                Text(
                  'Applicable Service Categories',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Auto-selected based on services + manual selection',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_availableCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'No categories available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _selectedCategories.length == _availableCategories.length,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCategories = List.from(_availableCategories);
                                  } else {
                                    _selectedCategories.clear();
                                  }
                                });
                              },
                            ),
                            const Text(
                              'Select all categories',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((category) {
                            return FilterChip(
                              label: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                ),
                              ),
                              selected: _selectedCategories.contains(category),
                              onSelected: (selected) {
                                _toggleCategorySelection(category);
                              },
                              selectedColor: Colors.blue.shade100,
                              backgroundColor: Colors.grey.shade200,
                              checkmarkColor: Colors.blue,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Applicable Genders
                Text(
                  'Applicable Genders',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _genders.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Offer Image
                Text(
                  'Offer Image (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'No image selected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create Coupon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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