import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'addon_model.dart';

class AddServicePage extends StatefulWidget {
  final Map<String, dynamic>? serviceData;
  const AddServicePage({super.key, this.serviceData});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountedPriceController =
      TextEditingController();
  final TextEditingController _newCategoryNameController =
      TextEditingController();
  final TextEditingController _newCategoryDescController =
      TextEditingController();
  final TextEditingController _newServiceNameController =
      TextEditingController();
  final TextEditingController _newServiceDescController =
      TextEditingController();
  final TextEditingController _taxValueController = TextEditingController();
  final TextEditingController _homeServiceChargesController =
      TextEditingController();
  final TextEditingController _weddingServiceChargesController =
      TextEditingController();

  // Image & Picker
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Category ID tracking
  String? selectedCategoryId; // Will store the actual MongoDB _id
  List<String> selectedStaffIds = []; // List of selected staff IDs
  Map<String, String> staffNameToId = {}; // Maps staff name to ID
  Map<String, String> staffIdToName = {}; // Maps staff ID to name
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

  List<AddOn> _availableAddOns = [];
  List<String> _selectedAddOnIds = [];
  bool _isAddOnsLoading = true;

  List<String> categories = [];
  List<String> serviceNames = [];
  Map<String, String> categoryIdMap = {}; // Maps category name to ID
  Map<String, List<String>> categoryServicesMap =
      {}; // Maps category name to its services
  Map<String, List<String>> serviceNameToAddonIds = {}; // Added
  bool _isCategoriesLoading = true; // Flag to track category loading state
  bool _isServicesLoading = false; // Flag to track service loading state

  List<String> staffMembers = [
    "Select All Staff",
  ];

  List<String> allStaff = []; // Dynamically fetched staff members
  bool _isStaffLoading = true; // Flag to track staff loading state

  final List<String> durations = [
    "15 min",
    "20 min",
    "25 min",
    "30 min",
    "40 min"
  ];

  final List<String> bookingIntervals = [
    "5",
    "10",
    "15",
    "20",
    "25",
    "30",
    "45",
    "60",
    "90",
    "120"
  ];
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
    _fetchStaff();
    _fetchCategories();
    _fetchAddOns();

    if (widget.serviceData != null) {
      final data = widget.serviceData!;
      _serviceNameController.text =
          data['name'] ?? data['serviceName'] ?? data['service_name'] ?? '';
      selectedCategory = data['category'];
      selectedCategoryId =
          data['categoryId'] ?? data['category_id'] ?? data['category_ID'];
      _descriptionController.text = data['description'] ?? '';

      var priceVal =
          data['price'] ?? data['service_price'] ?? data['servicePrice'];
      _priceController.text = priceVal?.toString() ?? '';

      // Fix: Use correct key 'discountedPrice' and convert to String
      var discPriceVal = data['discountedPrice'] ??
          data['discounted_price'] ??
          data['service_discounted_price'];
      _discountedPriceController.text = discPriceVal?.toString() ?? '';

      // Fix: Convert int duration to String and ensure it matches dropdown format e.g. "30 min"
      var durationValue = data['duration'];
      if (durationValue != null) {
        String durStr = durationValue.toString();
        if (durations.contains("$durStr min")) {
          _selectedDuration = "$durStr min";
        } else if (durations.contains(durStr)) {
          _selectedDuration = durStr;
        } else {
          _selectedDuration =
              durations.contains("30 min") ? "30 min" : durations.first;
        }
      }

      homeService = data['homeService']?['available'] ?? false;
      _homeServiceChargesController.text =
          (data['homeService']?['charges'] ?? data['homeServiceCharges'])
                  ?.toString() ??
              '';

      weddingService = data['weddingService']?['available'] ??
          (data['eventService']?['available'] ?? data['eventService'] ?? false);
      _weddingServiceChargesController.text = (data['weddingService']
                      ?['charges'] ??
                  data['weddingServiceCharges'] ??
                  data['eventService']?['charges'])
              ?.toString() ??
          '';

      // Fix: Use correct key 'commission' or 'allow_commission'
      allowCommission = data['commission'] ?? data['allow_commission'] ?? false;

      var staffData = data['staff'];
      if (staffData is List) {
        selectedStaff = staffData.join(',');
      } else {
        selectedStaff = staffData?.toString();
      }

      // Fix: Convert int booking interval to String if needed
      var interval = data['bookingInterval'] ?? data['booking_interval'];
      if (interval != null) {
        _bookingInterval = interval.toString();
      }

      // Fix: Normalize gender to match dropdown values
      var genderVal = data['gender']?.toString().toLowerCase();
      if (genderVal != null) {
        if (genders.contains(genderVal)) {
          _selectedGender = genderVal;
        } else if (genderVal == 'men') {
          _selectedGender = 'male';
        } else if (genderVal == 'women') {
          _selectedGender = 'female';
        } else if (genderVal == 'others') {
          _selectedGender = 'unisex';
        } else {
          // Fallback to first item if no match
          _selectedGender = genders.first;
        }
      }

      // Fix: Robust tax handling
      var taxData = data['tax'];
      if (taxData is Map) {
        enableTax = taxData['enabled'] ?? false;
        _taxType = taxData['type'];
        _taxValue = (taxData['value'] as num?)?.toDouble();
        _taxValueController.text = _taxValue?.toString() ?? '';
      } else if (taxData is num) {
        enableTax = true;
        _taxValue = taxData.toDouble();
        _taxValueController.text = _taxValue.toString();
        _taxType = "percentage"; // Default to percentage if only num is given
      }

      enableOnlineBooking = data['onlineBooking'] ?? true;

      _selectedAddOnIds = data['addOns'] != null
          ? List<String>.from(data['addOns'])
          : (data['mappedAddons'] != null
              ? List<String>.from(data['mappedAddons'])
              : []);

      // Fix: Pre-populate selectedServiceName and normalize category
      selectedServiceName = data['name'];
      if (selectedCategory == null || selectedCategory == 'Uncategorized') {
        selectedCategory = 'Uncategorized';
      }

      // If editing, fetch services for the selected category
      Future.delayed(Duration.zero, () {
        if (selectedCategory != null && selectedCategory != 'Uncategorized') {
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
                  const SizedBox(height: 16),
                  _dropdown(
                    categories,
                    selectedCategory,
                    (val) {
                      setState(() {
                        selectedCategory = val;
                        selectedCategoryId = categoryIdMap[val];
                        selectedServiceName = null;
                        if (val != null) {
                          _fetchServicesByCategory(val);
                        }
                      });
                    },
                    label: 'Category',
                    hint: 'Select a category',
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  if (_isCategoriesLoading) ...[
                    const SizedBox(height: 8),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showAddCategoryForm,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Category',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dropdown(
                    serviceNames.isEmpty && selectedCategory != null
                        ? ['No service added']
                        : serviceNames,
                    selectedServiceName,
                    (val) {
                      setState(() {
                        selectedServiceName = val;
                        if (val != null &&
                            serviceNameToAddonIds.containsKey(val)) {
                          _selectedAddOnIds =
                              List.from(serviceNameToAddonIds[val]!);
                        }
                      });
                    },
                    label: 'Service Name',
                    hint: _isServicesLoading
                        ? 'Loading...'
                        : (selectedCategory != null
                            ? 'Select service'
                            : 'Select a category first'),
                    enabled: selectedCategory !=
                        null, // Only enable when category is selected
                  ),
                  if (_isServicesLoading) ...[
                    const SizedBox(height: 8),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showAddServiceForm,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Service',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
                            if (value?.isEmpty == true)
                              return 'Price is required';
                            final num = double.tryParse(value!);
                            if (num == null || num <= 0)
                              return 'Enter a valid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _input(
                          _discountedPriceController,
                          label: 'Discounted Price',
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
                      _selectedImage == null
                          ? "Upload Image"
                          : "Image Selected ✓",
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
                      child: Image.file(_selectedImage!,
                          height: 100, fit: BoxFit.cover),
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                                          selectedStaff = value == true
                                              ? 'All Staff'
                                              : null;
                                        });
                                      },
                                    ),
                                    const Text("All Staff",
                                        style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const Divider(height: 16),
                                ...allStaff
                                    .map(
                                      (staffName) => Row(
                                        children: [
                                          Checkbox(
                                            value: selectedStaff !=
                                                    'All Staff' &&
                                                (selectedStaff
                                                        ?.split(',')
                                                        .map((s) => s.trim())
                                                        .contains(staffName) ??
                                                    false),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (selectedStaff ==
                                                    'All Staff') {
                                                  selectedStaff = staffName;
                                                } else {
                                                  if (value == true) {
                                                    if (selectedStaff == null) {
                                                      selectedStaff = staffName;
                                                    } else {
                                                      selectedStaff =
                                                          '$selectedStaff,$staffName';
                                                    }
                                                  } else {
                                                    if (selectedStaff != null) {
                                                      var staffList =
                                                          selectedStaff!
                                                              .split(',');
                                                      staffList
                                                          .remove(staffName);
                                                      selectedStaff =
                                                          staffList.join(',');
                                                      if (selectedStaff!
                                                          .isEmpty)
                                                        selectedStaff = null;
                                                    }
                                                  }
                                                }
                                              });
                                            },
                                          ),
                                          Expanded(
                                              child: Text(staffName,
                                                  style: const TextStyle(
                                                      fontSize: 13))),
                                        ],
                                      ),
                                    )
                                    .toList(),
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
                        onChanged: (val) =>
                            setState(() => allowCommission = val),
                        title: const Text("Enable Staff Commission",
                            style: TextStyle(fontSize: 13)),
                        subtitle: const Text(
                            "Calculate staff commission when service is sold",
                            style: TextStyle(fontSize: 11)),
                        activeColor: Theme.of(context).primaryColor,
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
                                  onChanged: (val) =>
                                      setState(() => homeService = val),
                                  title: const Text("Enable Home Service",
                                      style: TextStyle(fontSize: 13)),
                                  activeColor: Theme.of(context).primaryColor,
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
                                  onChanged: (val) =>
                                      setState(() => weddingService = val),
                                  title: const Text("Enable Wedding Service",
                                      style: TextStyle(fontSize: 13)),
                                  activeColor: Theme.of(context).primaryColor,
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
                  if (widget.serviceData != null) ...[
                    _spacer(12),
                    _header("Add-ons"),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isAddOnsLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Builder(builder: (context) {
                                        final serviceId =
                                            widget.serviceData!['_id'] ??
                                                widget.serviceData!['id'];
                                        final visibleAddons = _availableAddOns
                                            .where((a) =>
                                                a.mappedServices
                                                    ?.contains(serviceId) ??
                                                false)
                                            .toList();
                                        return Checkbox(
                                          value: visibleAddons.isNotEmpty &&
                                              visibleAddons.every((a) =>
                                                  _selectedAddOnIds
                                                      .contains(a.id)),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                for (var a in visibleAddons) {
                                                  if (!_selectedAddOnIds
                                                      .contains(a.id)) {
                                                    _selectedAddOnIds
                                                        .add(a.id!);
                                                  }
                                                }
                                              } else {
                                                for (var a in visibleAddons) {
                                                  _selectedAddOnIds
                                                      .remove(a.id);
                                                }
                                              }
                                            });
                                          },
                                          activeColor:
                                              Theme.of(context).primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        );
                                      }),
                                      Text("Select All Add-ons",
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  ..._availableAddOns.where((addon) {
                                    final serviceId =
                                        widget.serviceData!['_id'] ??
                                            widget.serviceData!['id'];
                                    return addon.mappedServices
                                            ?.contains(serviceId) ??
                                        false;
                                  }).map((addon) {
                                    final isSelected =
                                        _selectedAddOnIds.contains(addon.id);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedAddOnIds.remove(addon.id);
                                          } else {
                                            _selectedAddOnIds.add(addon.id!);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedAddOnIds
                                                        .add(addon.id!);
                                                  } else {
                                                    _selectedAddOnIds
                                                        .remove(addon.id);
                                                  }
                                                });
                                              },
                                              activeColor: Theme.of(context)
                                                  .primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                "${addon.name} (₹${addon.price?.toStringAsFixed(0)})",
                                                style: GoogleFonts.poppins(
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                      ),
                    ),
                  ],
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
                            title: const Text("Enable Tax",
                                style: TextStyle(fontSize: 13)),
                            activeColor: Theme.of(context).primaryColor,
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
                                if (enableTax &&
                                    (value == null || value.isEmpty)) {
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
                            onChanged: (val) =>
                                setState(() => enableOnlineBooking = val),
                            title: const Text("Enable Online Booking",
                                style: TextStyle(fontSize: 13)),
                            activeColor: Theme.of(context).primaryColor,
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
                if (_tabController.index < 2) {
                  // Move to next tab if not on the last tab
                  _tabController.animateTo(_tabController.index + 1);
                } else {
                  // On the last tab (Booking & Tax), save the service
                  if (!_formKey.currentState!.validate()) return;

                  final serviceData = {
                    'name': _serviceNameController.text.trim().isNotEmpty
                        ? _serviceNameController.text.trim()
                        : (selectedServiceName ?? ''),
                    'category_id':
                        selectedCategoryId ?? categoryIdMap[selectedCategory],
                    'description': _descriptionController.text.trim(),
                    'price':
                        double.tryParse(_priceController.text.trim()) ?? 0.0,
                    'discounted_price':
                        _discountedPriceController.text.trim().isEmpty
                            ? null
                            : double.tryParse(
                                _discountedPriceController.text.trim()),
                    'duration': _selectedDuration,
                    'gender': _selectedGender ?? 'unisex',
                    'homeService': {
                      'available': homeService,
                      'charges': homeService
                          ? double.tryParse(
                              _homeServiceChargesController.text.trim())
                          : null,
                    },
                    'weddingService': {
                      'available': weddingService,
                      'charges': weddingService
                          ? double.tryParse(
                              _weddingServiceChargesController.text.trim())
                          : null,
                    },
                    'allow_commission': allowCommission,
                    'home_service': homeService, // Added
                    'wedding_service': weddingService, // Added
                    'enable_tax': enableTax, // Added
                    'staff': selectedStaff == 'All Staff'
                        ? allStaff
                            .map((name) => staffNameToId[name] ?? name)
                            .toList() // All staff IDs
                        : selectedStaff != null
                            ? selectedStaff!
                                .split(',')
                                .where((s) => s.trim().isNotEmpty)
                                .map((name) =>
                                    staffNameToId[name.trim()] ?? name.trim())
                                .toList() // Selected specific staff IDs
                            : [], // No staff selected
                    'booking_interval': _bookingInterval,
                    'tax': {
                      'enabled': enableTax,
                      'type': _taxType,
                      'value': _taxValue,
                    },
                    'online_booking': enableOnlineBooking,
                    'addOns': _selectedAddOnIds,
                  };

                  if (_selectedImage != null) {
                    final bytes = await _selectedImage!.readAsBytes();
                    final base64 = base64Encode(bytes);
                    final mimeType =
                        _selectedImage!.path.endsWith('.png') ? 'png' : 'jpeg';
                    serviceData['image'] =
                        'data:image/$mimeType;base64,$base64';
                  }
                  try {
                    if (widget.serviceData == null) {
                      // Creating a new service
                      final success =
                          await ApiService.createService(serviceData);
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
                        final success = await ApiService.updateService(
                            serviceId, serviceData);
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
                        throw Exception(
                            'Service ID is missing for update operation');
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ' +
                            e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _tabController.index < 2
                    ? "Next"
                    : (widget.serviceData == null
                        ? "Save Service"
                        : "Update Service"),
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

  Future<void> _fetchAddOns() async {
    setState(() => _isAddOnsLoading = true);
    try {
      final addons = await ApiService.getAddOns();
      setState(() {
        _availableAddOns = addons;
        _isAddOnsLoading = false;
      });
    } catch (e) {
      print('Error fetching add-ons: $e');
      setState(() => _isAddOnsLoading = false);
    }
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isStaffLoading = true;
    });

    try {
      final members = await ApiService.getStaff();

      List<String> staffNames = [];
      staffNameToId.clear();
      staffIdToName.clear();
      for (var staff in members) {
        String name = staff.fullName ?? 'Unknown Staff';
        String id = staff.id ?? '';
        staffNames.add(name);
        staffNameToId[name] = id;
        staffIdToName[id] = name;
      }

      setState(() {
        allStaff = staffNames;
        staffMembers = ['All Staff', ...allStaff];
        _isStaffLoading = false;

        // If we have selectedStaff that contains IDs, translate them to names
        if (selectedStaff != null && selectedStaff != 'All Staff') {
          List<String> currentParts = selectedStaff!.split(',');
          List<String> names = [];
          for (var part in currentParts) {
            String trimmed = part.trim();
            if (staffIdToName.containsKey(trimmed)) {
              names.add(staffIdToName[trimmed]!);
            } else {
              names.add(trimmed);
            }
          }
          selectedStaff = names.join(',');
        }
      });
    } catch (e) {
      print('Error fetching staff: $e');
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
      final categoryData = await ApiService.getServiceCategories();

      setState(() {
        categories = [];
        categoryIdMap = {}; // name → id

        for (var cat in categoryData) {
          String name = cat['name'] ?? 'Unknown Category';
          String id = cat['_id'] ?? '';
          categories.add(name);
          categoryIdMap[name] = id;
        }

        if (selectedCategory != null &&
            !categories.contains(selectedCategory)) {
          categories.add(selectedCategory!);
        }
      });
      print('Categories loaded: ${categories.length}');
    } catch (e) {
      print('Error fetching categories: $e');
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
      final servicesData = await ApiService.getServicesByCategory(categoryName);

      List<String> names = [];
      for (var s in servicesData) {
        String name = s['name'] ?? 'Unknown Service';
        names.add(name);

        if (s['addOns'] != null && s['addOns'] is List) {
          serviceNameToAddonIds[name] = List<String>.from(s['addOns']);
        }
      }

      setState(() {
        categoryServicesMap[categoryName] = names;
        if (selectedCategory == categoryName) {
          serviceNames = names;
          if (selectedServiceName != null &&
              !serviceNames.contains(selectedServiceName)) {
            serviceNames.add(selectedServiceName!);
          }
        }
        _isServicesLoading = false;
      });
    } catch (e) {
      print('Error fetching services for category: $e');
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
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
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
    print('Dropdown created with ' +
        items.length.toString() +
        ' items'); // Debug print
    // Check if this is the special case of "No service added"
    bool isNoServiceAdded = items.length == 1 && items[0] == 'No service added';
    // Fix: Flutter crashes if 'value' is not in 'items'.
    // We check if 'selected' is in 'items', otherwise we pass null.
    String? effectiveValue = (items.contains(selected)) ? selected : null;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      items: items.isNotEmpty
          ? items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13))))
              .toList()
          : <DropdownMenuItem<String>>[],
      onChanged: enabled && !isNoServiceAdded
          ? onChanged
          : null, // Only allow changes if enabled and not the "No service added" case
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                    child: Image.file(_selectedImage!,
                        height: 100, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(fontSize: 12)),
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
                            final mimeType =
                                _selectedImage!.path.endsWith('.png')
                                    ? 'png'
                                    : 'jpeg'; // adjust if needed
                            imageBase64 = 'data:image/$mimeType;base64,$base64';
                          }

                          final payload = {
                            "name": name,
                            "description":
                                _newCategoryDescController.text.trim(),
                            if (imageBase64 != null) "image": imageBase64,
                          };

                          try {
                            final response =
                                await ApiService.createMasterCategory(payload);

                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              // Success - update local list with the response data
                              final responseData = json.decode(response.body);
                              setState(() {
                                // Add the new category to the list using the name from response
                                categories.add(responseData['name']);
                                // Update the category map with the new category ID
                                categoryIdMap[responseData['name']] =
                                    responseData['_id'];
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
                                const SnackBar(
                                    content:
                                        Text('Category added successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to add category: ${response.body}')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error adding category: $e')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child:
                            const Text("Add", style: TextStyle(fontSize: 12)),
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
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                        child: const Text("Cancel",
                            style: TextStyle(fontSize: 12)),
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
                              const SnackBar(
                                  content: Text('Service name is required')),
                            );
                            return;
                          }

                          // Get the category ID from the map
                          String? categoryId = categoryIdMap[selectedCategory];
                          if (categoryId == null || categoryId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please select a category first')),
                            );
                            return;
                          }

                          String? imageBase64;
                          if (_selectedImage != null) {
                            final bytes = await _selectedImage!.readAsBytes();
                            final base64 = base64Encode(bytes);
                            final mimeType =
                                _selectedImage!.path.endsWith('.png')
                                    ? 'png'
                                    : 'jpeg';
                            imageBase64 = 'data:image/$mimeType;base64,$base64';
                          }

                          final payload = {
                            "name": name,
                            "description":
                                _newServiceDescController.text.trim(),
                            "category":
                                categoryId, // This must be the ObjectId string
                            if (imageBase64 != null) "image": imageBase64,
                          };

                          try {
                            final response =
                                await ApiService.createMasterService(payload);

                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              final responseData = json.decode(response.body);
                              setState(() {
                                // Add to current category services list
                                if (categoryServicesMap[selectedCategory] !=
                                    null) {
                                  categoryServicesMap[selectedCategory]!
                                      .add(responseData['name']);
                                } else {
                                  categoryServicesMap[selectedCategory!] = [
                                    responseData['name']
                                  ];
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
                                const SnackBar(
                                    content:
                                        Text('Service added successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${response.body}')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Network error: $e')),
                            );
                          }
                        },
                        child:
                            const Text("Save", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
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
