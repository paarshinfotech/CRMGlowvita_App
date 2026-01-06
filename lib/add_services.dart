import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;


class AddServicePage extends StatefulWidget {
  final Map<String, dynamic>? serviceData;
  const AddServicePage({super.key, this.serviceData});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountedPriceController = TextEditingController();
  final TextEditingController _newCategoryNameController = TextEditingController();
  final TextEditingController _newCategoryDescController = TextEditingController();
  final TextEditingController _newServiceNameController = TextEditingController();
  final TextEditingController _newServiceDescController = TextEditingController();
  final TextEditingController _taxValueController = TextEditingController();
  final TextEditingController _homeServiceChargesController = TextEditingController();
  final TextEditingController _weddingServiceChargesController = TextEditingController();

  // Image & Picker
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Category ID tracking (REQUIRED for service API)
  String? selectedCategoryId;
  Map<String, String> categoryIdMap = {};  // Maps category name to MongoDB _id

  late TabController _tabController;
  String? selectedCategory;
  String? selectedServiceName;
  String? _selectedDuration;
  String? _bookingInterval;
  String? _taxType;
  double? _taxValue;
  String? selectedStaff;
  String? _selectedGender;

  bool homeService = false;
  bool weddingService = false;
  bool allowCommission = false;
  bool enableTax = false;
  bool enableOnlineBooking = true;

  List<String> categories = [];
  List<String> serviceNames = [];
  Map<String, String> categoryMap = {}; // Maps category name to ID
  Map<String, List<String>> categoryServicesMap = {}; // Maps category name to its services
  bool _isCategoriesLoading = true; // Flag to track category loading state
  bool _isServicesLoading = false; // Flag to track service loading state

  List<String> staffMembers = [
    "Select All Staff",  
  ];

  List<String> allStaff = []; // Dynamically fetched staff members
  bool _isStaffLoading = true; // Flag to track staff loading state

  final List<String> durations = ["15 min", "20 min", "25 min", "30 min", "40 min"];

  final List<String> bookingIntervals = ["5", "10", "15", "20", "25", "30", "45", "60", "90", "120"];
  final List<String> taxTypes = ["percentage", "fixed"];
  final List<String> genders = ["male", "female", "unisex"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize loading states
    _isCategoriesLoading = true;
    _isStaffLoading = true;
    
    // Fetch data from APIs
    _fetchCategories();
    _fetchStaff();

    if (widget.serviceData != null) {
      _serviceNameController.text = widget.serviceData!['name'] ?? '';
      selectedCategory = widget.serviceData!['category'];
      _descriptionController.text = widget.serviceData!['description'] ?? '';
      _priceController.text = widget.serviceData!['price']?.toString() ?? '';
      _discountedPriceController.text = widget.serviceData!['discounted_price']?.toString() ?? '';
      _selectedDuration = widget.serviceData!['duration'];
      homeService = widget.serviceData!['homeService']?['available'] ?? false;
      _homeServiceChargesController.text = widget.serviceData!['homeService']?['charges']?.toString() ?? '';
      weddingService = widget.serviceData!['weddingService']?['available'] ?? false;
      _weddingServiceChargesController.text = widget.serviceData!['weddingService']?['charges']?.toString() ?? '';
      allowCommission = widget.serviceData!['allow_commission'] ?? false;
      var staffData = widget.serviceData!['staff'];
      // Handle staff data - might be a list or single value
      if (staffData is List) {
        selectedStaff = staffData.join(',');
      } else {
        selectedStaff = staffData;
      }
      _bookingInterval = widget.serviceData!['booking_interval'];
      _selectedGender = widget.serviceData!['gender'];
      enableTax = widget.serviceData!['tax']?['enabled'] ?? false;
      _taxType = widget.serviceData!['tax']?['type'];
      _taxValue = widget.serviceData!['tax']?['value']?.toDouble();
      _taxValueController.text = _taxValue?.toString() ?? '';
      enableOnlineBooking = widget.serviceData!['onlineBooking'] ?? true;
      
      // If editing, fetch services for the selected category
      // Delay this until after categories are loaded
      Future.delayed(Duration.zero, () {
        if (selectedCategory != null) {
          _fetchServicesByCategory(selectedCategory!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serviceData == null ? 'Add Service' : 'Edit Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Advanced'),
            Tab(text: 'Booking & Tax'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Basic Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dropdown(
                    categories,
                    selectedCategory,
                    (val) {
                      setState(() {
                        selectedCategory = val;
                        selectedServiceName = null;
                        if (val != null) {
                          _fetchServicesByCategory(val);
                        }
                      });
                    },
                    label: 'Category',
                    hint: 'Select a category',
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
                  if (_isCategoriesLoading) ...[
                    const SizedBox(height: 8),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showAddCategoryForm,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Category', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dropdown(
                    serviceNames,
                    selectedServiceName,
                    (val) => setState(() => selectedServiceName = val),
                    label: 'Existing Service (Optional)',
                    hint: _isServicesLoading ? 'Loading...' : 'Select existing service',
                    enabled: selectedCategory != null, // Only enable when category is selected
                  ),
                  if (_isServicesLoading) ...[
                    const SizedBox(height: 8),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showAddServiceForm,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Service', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _input(
                    _descriptionController,
                    label: 'Description',
                    hint: 'Brief description of the service',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _input(
                          _priceController,
                          label: 'Price',
                          hint: 'e.g. 500',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Price is required';
                            final num = double.tryParse(value!);
                            if (num == null || num <= 0) return 'Enter a valid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _input(
                          _discountedPriceController,
                          label: 'Discounted Price (Optional)',
                          hint: 'e.g. 450',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _dropdown(
                    durations,
                    _selectedDuration,
                    (val) => setState(() => _selectedDuration = val),
                    label: 'Duration',
                    hint: 'Select duration',
                  ),
                  const SizedBox(height: 16),
                  _dropdown(
                    genders,
                    _selectedGender,
                    (val) => setState(() => _selectedGender = val),
                    label: 'Gender',
                    hint: 'Select gender',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final XFile? picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedImage = File(picked.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      _selectedImage == null ? "Upload Image" : "Image Selected ✓",
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, height: 100, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
            // Advanced Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header("Staff Assignment"),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isStaffLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: selectedStaff == 'All Staff',
                                      onChanged: (bool? value) {
                                        setState(() {
                                          selectedStaff = value == true ? 'All Staff' : null;
                                        });
                                      },
                                    ),
                                    const Text("All Staff", style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const Divider(height: 16),
                                ...allStaff.map((staffName) => 
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: selectedStaff != 'All Staff' && (selectedStaff?.contains(staffName) ?? false),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (selectedStaff == 'All Staff') {
                                              selectedStaff = staffName;
                                            } else {
                                              if (value == true) {
                                                if (selectedStaff == null) {
                                                  selectedStaff = staffName;
                                                } else {
                                                  selectedStaff = '$selectedStaff,$staffName';
                                                }
                                              } else {
                                                if (selectedStaff != null) {
                                                  var staffList = selectedStaff!.split(',');
                                                  staffList.remove(staffName);
                                                  selectedStaff = staffList.join(',');
                                                  if (selectedStaff!.isEmpty) selectedStaff = null;
                                                }
                                              }
                                            }
                                          });
                                        },
                                      ),
                                      Expanded(child: Text(staffName, style: const TextStyle(fontSize: 13))),
                                    ],
                                  ),
                                ).toList(),
                              ],
                            ),
                    ),
                  ),
                  _spacer(6),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SwitchListTile(
                        value: allowCommission,
                        onChanged: (val) => setState(() => allowCommission = val),
                        title: const Text("Enable Staff Commission", style: TextStyle(fontSize: 13)),
                        subtitle: const Text("Calculate staff commission when service is sold", style: TextStyle(fontSize: 11)),
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ),
                  _spacer(12),
                  _header("Service Options"),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  value: homeService,
                                  onChanged: (val) => setState(() => homeService = val),
                                  title: const Text("Enable Home Service", style: TextStyle(fontSize: 13)),
                                  activeColor: Colors.blue,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              if (homeService) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _input(
                                    _homeServiceChargesController,
                                    label: 'Charges',
                                    hint: 'e.g. 100',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  value: weddingService,
                                  onChanged: (val) => setState(() => weddingService = val),
                                  title: const Text("Enable Wedding Service", style: TextStyle(fontSize: 13)),
                                  activeColor: Colors.blue,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              if (weddingService) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _input(
                                    _weddingServiceChargesController,
                                    label: 'Charges',
                                    hint: 'e.g. 200',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Booking & Tax Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header("Booking Settings"),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _dropdown(
                        bookingIntervals,
                        _bookingInterval,
                        (val) => setState(() => _bookingInterval = val),
                        label: "Booking Interval (minutes)",
                        hint: "Select interval (5-120 minutes)",
                      ),
                    ),
                  ),
                  _spacer(12),
                  _header("Tax Settings"),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: enableTax,
                            onChanged: (val) {
                              setState(() {
                                enableTax = val;
                                if (!val) {
                                  _taxType = null;
                                  _taxValue = null;
                                  _taxValueController.clear();
                                }
                              });
                            },
                            title: const Text("Enable Tax", style: TextStyle(fontSize: 13)),
                            activeColor: Colors.blue,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          if (enableTax) ...[
                            const Divider(height: 16),
                            _dropdown(
                              taxTypes,
                              _taxType,
                              (val) => setState(() => _taxType = val),
                              label: "Tax Type",
                              hint: "Select tax type",
                            ),
                            const SizedBox(height: 8),
                            _input(
                              _taxValueController,
                              label: "Tax Value",
                              hint: "Enter tax value",
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (enableTax && (value == null || value.isEmpty)) {
                                  return "Tax value is required when tax is enabled";
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _taxValue = double.tryParse(value);
                              },
                            ),
                          ],
                          const Divider(height: 16),
                          SwitchListTile(
                            value: enableOnlineBooking,
                            onChanged: (val) => setState(() => enableOnlineBooking = val),
                            title: const Text("Enable Online Booking", style: TextStyle(fontSize: 13)),
                            activeColor: Colors.blue,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                
                final serviceData = { 
                  'name': _serviceNameController.text.trim().isNotEmpty
                      ? _serviceNameController.text.trim()
                      : (selectedServiceName ?? ''),
                  'category': selectedCategory,
                  'description': _descriptionController.text.trim(),
                  'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
                  'discounted_price': _discountedPriceController.text.trim().isEmpty
                      ? null
                      : double.tryParse(_discountedPriceController.text.trim()),
                  'duration': _selectedDuration,
                  'gender': _selectedGender ?? 'unisex',
                  'homeService': {
                    'available': homeService,
                    'charges': homeService ? double.tryParse(_homeServiceChargesController.text.trim()) : null,
                  },
                  'weddingService': {
                    'available': weddingService,
                    'charges': weddingService ? double.tryParse(_weddingServiceChargesController.text.trim()) : null,
                  },
                  'allow_commission': allowCommission,
                  'staff': selectedStaff == 'All Staff' 
                      ? allStaff // All staff selected
                      : selectedStaff != null 
                          ? selectedStaff!.split(',').where((s) => s.isNotEmpty).toList() // Selected specific staff
                          : [], // No staff selected
                  'booking_interval': _bookingInterval,
                  'tax': {
                    'enabled': enableTax,
                    'type': _taxType,
                    'value': _taxValue,
                  },
                  'online_booking': enableOnlineBooking,
                };
                
                // Add image to service data if available
                if (_selectedImage != null) {
                  final bytes = await _selectedImage!.readAsBytes();
                  final base64 = base64Encode(bytes);
                  final mimeType = _selectedImage!.path.endsWith('.png')
                      ? 'png'
                      : 'jpeg';
                  serviceData['image'] = 'data:image/$mimeType;base64,$base64';
                }
                
                try {
                  if (widget.serviceData == null) {
                    // Creating a new service
                    final success = await ApiService.createService(serviceData);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh the services for the current category
                      if (selectedCategory != null) {
                        await _fetchServicesByCategory(selectedCategory!);
                      }
                      Navigator.pop(context, serviceData);
                    }
                  } else {
                    // Updating existing service
                    final serviceId = widget.serviceData!['_id'];
                    if (serviceId != null) {
                      final success = await ApiService.updateService(serviceId, serviceData);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Service updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh the services for the current category
                        if (selectedCategory != null) {
                          await _fetchServicesByCategory(selectedCategory!);
                        }
                        Navigator.pop(context, serviceData);
                      }
                    } else {
                      throw Exception('Service ID is missing for update operation');
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ' + e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                widget.serviceData == null ? "Add Service" : "Update Service",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isStaffLoading = true;
    });

    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('https://partners.v2winonline.com/api/crm/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> staffData;
        if (decoded is List) {
          staffData = decoded;
        } else {
          staffData = decoded['data'] ?? [];
        }

        List<String> staffNames = [];
        for (var staff in staffData) {
          String name = staff['fullName'] ?? 'Unknown Staff';
          staffNames.add(name);
        }

        setState(() {
          allStaff = staffNames;
          staffMembers = ['All Staff', ...allStaff];
          _isStaffLoading = false;
        });
      } else {
        throw Exception('Failed to load staff: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching staff: $e');
      // Fallback to default values if API call fails
      setState(() {
        staffMembers = ['All Staff'];
        _isStaffLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isCategoriesLoading = true;
    });
    
    try {
      print('Fetching categories...');
      final token = await ApiService.getAuthToken();
      print('Token retrieved: $token'); // Debug print
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('https://partners.v2winonline.com/api/crm/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
      );
      print('Category API Response Status: ${response.statusCode}'); // Debug print

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Category API Response: $decoded'); // Debug print
        List<dynamic> categoryData;
        if (decoded is List) {
          categoryData = decoded;
        } else {
          categoryData = decoded['data'] ?? [];
        }
        
        setState(() {
          categories = [];
          categoryMap = {};
          categoryIdMap = {};
          
          for (var cat in categoryData) {
            String name = cat['name'] ?? 'Unknown Category';
            String id = cat['_id'] ?? '';
            print('Adding category: $name with ID: $id'); // Debug print
            categories.add(name);
            categoryMap[name] = id;
            categoryIdMap[name] = id;
          }
        });
        print('Categories loaded: ${categories.length}');
      } else {
        print('Category API Error: ${response.body}'); // Debug print
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Fallback to empty list
      setState(() {
        categories = [];
      });
    } finally {
      setState(() {
        _isCategoriesLoading = false;
      });
    }
  }

  Future<void> _fetchServicesByCategory(String categoryName) async {
    setState(() {
      _isServicesLoading = true;
    });
    
    try {
      print('Fetching services for category: $categoryName');
      final token = await ApiService.getAuthToken();
      print('Service API Token retrieved: $token'); // Debug print
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('https://admin.v2winonline.com/api/admin/services'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'crm_access_token=$token',
        },
      );
      print('Service API Response Status: ${response.statusCode}'); // Debug print

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Service API Response: $decoded'); // Debug print
        List<dynamic> serviceData;
        if (decoded is List) {
          serviceData = decoded;
        } else {
          serviceData = decoded['data'] ?? [];
        }
        
        // Filter services by selected category
        List<String> servicesInCategory = [];
        for (var service in serviceData) {
          String serviceCategory = '';
          if (service['category'] is Map) {
            serviceCategory = service['category']['name'] ?? service['category']['_id'] ?? '';
          } else {
            serviceCategory = service['categoryName'] ?? service['category'] ?? '';
          }
          
          print('Checking service: ' + (service['name']?.toString() ?? 'Unknown') + ' with category: ' + serviceCategory); // Debug print
          if (serviceCategory == categoryName) {
            servicesInCategory.add(service['name'] ?? 'Unknown Service');
          }
        }
        
        setState(() {
          categoryServicesMap[categoryName] = servicesInCategory;
          serviceNames = servicesInCategory;
        });
        print('Services loaded for category $categoryName: ${servicesInCategory.length}');
      } else {
        print('Service API Error: ${response.body}'); // Debug print
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching services: $e');
      // Fallback to empty list
      setState(() {
        serviceNames = [];
      });
    } finally {
      setState(() {
        _isServicesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _newCategoryNameController.dispose();
    _newCategoryDescController.dispose();
    _newServiceNameController.dispose();
    _newServiceDescController.dispose();
    _taxValueController.dispose();
    _homeServiceChargesController.dispose();
    _weddingServiceChargesController.dispose();
    super.dispose();
  }
  
   // Enhanced input decoration with smaller font sizes
  InputDecoration _dec({String? label, String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      // Clean, modern borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      labelStyle: const TextStyle(fontSize: 14),
      hintStyle: const TextStyle(fontSize: 10),
    );
  }

  Widget _input(
    TextEditingController controller, {
    int maxLines = 1,
    String? label,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _dec(label: label, hint: hint, helper: helper),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _dropdown(
    List<String> items,
    String? selected,
    ValueChanged<String?>? onChanged, {
    String? label,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    print('Dropdown created with ' + items.length.toString() + ' items'); // Debug print
    return DropdownButtonFormField<String>(
      value: selected,
      items: items.isNotEmpty 
        ? items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList()
        : <DropdownMenuItem<String>>[],
      onChanged: enabled ? onChanged : null, // Only allow changes if enabled
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _dec(label: label, hint: hint, helper: helper),
      isExpanded: true,
      borderRadius: BorderRadius.circular(8),
      menuMaxHeight: 300,
      dropdownColor: Colors.white,
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  Widget _spacer(double height) => SizedBox(height: height);

  void _showAddCategoryForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Add Category",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  _newCategoryNameController,
                  label: "Category Name",
                  hint: "e.g. Hair Coloring",
                ),
                const SizedBox(height: 12),
                _input(
                  _newCategoryDescController,
                  label: "Description",
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final XFile? picked = await _picker.pickImage(
                      source: ImageSource.gallery, // or ImageSource.camera
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedImage = File(picked.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(
                    _selectedImage == null ? "Add Image" : "Image Selected ✓",
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 100, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = _newCategoryNameController.text.trim();
                          if (name.isEmpty) return;

                          // Build payload
                          String? imageBase64;
                          if (_selectedImage != null) {
                            final bytes = await _selectedImage!.readAsBytes();
                            final base64 = base64Encode(bytes);
                            final mimeType = _selectedImage!.path.endsWith('.png')
                                ? 'png'
                                : 'jpeg'; // adjust if needed
                            imageBase64 = 'data:image/$mimeType;base64,$base64';
                          }

                          final payload = {
                            "name": name,
                            "description": _newCategoryDescController.text.trim(),
                            if (imageBase64 != null) "image": imageBase64,
                          };

                          try {
                            final token = await ApiService.getAuthToken();
                            final response = await http.post(
                              Uri.parse('https://admin.v2winonline.com/api/admin/categories'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Cookie': 'crm_access_token=$token',
                              },
                              body: jsonEncode(payload),
                            );

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              // Success - update local list with the response data
                              final responseData = json.decode(response.body);
                              setState(() {
                                // Add the new category to the list using the name from response
                                categories.add(responseData['name']);
                                // Update the category map with the new category ID
                                categoryMap[responseData['name']] = responseData['_id'];
                                selectedCategory = responseData['name'];
                                // After adding category, fetch services for the new category
                                _fetchServicesByCategory(responseData['name']);
                              });
                              _newCategoryNameController.clear();
                              _newCategoryDescController.clear();
                              _selectedImage = null;
                              Navigator.pop(context);
                              // Refresh services for the new category
                              if (selectedCategory != null) {
                                _fetchServicesByCategory(selectedCategory!);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Category added successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add category: ${response.body}')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error adding category: $e')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Add", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showAddServiceForm() {
    // Reset image when opening dialog
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Add Service",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  _newServiceNameController,
                  label: "Service Name",
                  hint: "e.g. Deluxe Facial",
                ),
                const SizedBox(height: 12),
                _input(
                  _newServiceDescController,
                  label: "Description",
                  hint: "Optional",
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final XFile? picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        _selectedImage = File(picked.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(
                    _selectedImage == null ? "Add Image" : "Image Selected ✓",
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = _newServiceNameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Service name is required')),
                            );
                            return;
                          }

                          // Get the category ID from the map
                          String? categoryId = categoryIdMap[selectedCategory] ?? categoryMap[selectedCategory];
                          if (categoryId == null || categoryId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a category first')),
                            );
                            return;
                          }

                          String? imageBase64;
                          if (_selectedImage != null) {
                            final bytes = await _selectedImage!.readAsBytes();
                            final base64 = base64Encode(bytes);
                            final mimeType = _selectedImage!.path.endsWith('.png')
                                ? 'png'
                                : 'jpeg';
                            imageBase64 = 'data:image/$mimeType;base64,$base64';
                          }

                          final payload = {
                            "name": name,
                            "description": _newServiceDescController.text.trim(),
                            "category": categoryId,  // This must be the ObjectId string
                            if (imageBase64 != null) "image": imageBase64,
                          };

                          try {
                            final token = await ApiService.getAuthToken();
                            if (token == null) {
                              throw Exception('No authentication token found');
                            }
                            
                            final response = await http.post(
                              Uri.parse('https://admin.v2winonline.com/api/admin/services'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Cookie': 'crm_access_token=$token',
                              },
                              body: jsonEncode(payload),
                            );

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              final responseData = json.decode(response.body);
                              setState(() {
                                // Add to current category services list
                                if (categoryServicesMap[selectedCategory] != null) {
                                  categoryServicesMap[selectedCategory]!.add(responseData['name']);
                                } else {
                                  categoryServicesMap[selectedCategory!] = [responseData['name']];
                                }
                                serviceNames.add(responseData['name']);
                                selectedServiceName = responseData['name'];
                              });
                              _newServiceNameController.clear();
                              _newServiceDescController.clear();
                              _selectedImage = null;

                              Navigator.pop(context);
                              // Refresh services for the current category
                              if (selectedCategory != null) {
                                _fetchServicesByCategory(selectedCategory!);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Service added successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${response.body}')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Network error: $e')),
                            );
                          }
                        },
                        child: const Text("Save", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          );
        });
      },
    );
  }
}