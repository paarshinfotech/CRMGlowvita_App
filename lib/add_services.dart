import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddServicePage extends StatefulWidget {
  final Map<String, dynamic>? serviceData;
  const AddServicePage({super.key, this.serviceData});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _categoryDescController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountedPriceController = TextEditingController();
  final TextEditingController _newCategoryNameController = TextEditingController();
  final TextEditingController _newCategoryDescController = TextEditingController();
  final TextEditingController _newServiceNameController = TextEditingController();
  final TextEditingController _newServiceDescController = TextEditingController();

  late TabController _tabController;
  String? selectedCategory;
  String? selectedServiceName;
  String? _selectedDuration;
  String? _bookingInterval;
  String? _taxRate;
  String? selectedStaff;

  bool homeService = false;
  bool weddingService = false;
  bool allowCommission = false;

  List<String> categories = [
    "Hair","Skin","Nails","Makeup","Male Grooming","Beauty Tools","Spa & Wellness",
    "Hair Coloring","Hair Styling","Facial Treatments","Threading","Body Treatments",
    "Bridal Packages","Manicure","Pedicure","Laser Treatment","Eyebrows & Eyelashes",
    "Tattoo Services","Hair Extensions",
  ];

  List<String> serviceNames = [
    "Basic Haircut","Deluxe Facial","Manicure","Pedicure","Full Body Massage",
  ];

  List<String> staffMembers = [
    "All Staff","John Doe","Jane Smith","Michael Johnson","Sarah Williams",
  ];

  final List<String> durations = [
    for (int i = 5; i <= 720; i += 5)
      if (i < 60) "$i min"
      else if (i % 60 == 0) "${i ~/ 60} hour${i == 60 ? '' : 's'}"
      else "${i ~/ 60} hour ${i % 60} min"
  ];

  final List<String> bookingIntervals = [for (int i = 5; i <= 120; i += 5) "$i"];
  final List<String> taxRates = ["Tax Free","5%","10%","15%","18%"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.serviceData != null) {
      _serviceNameController.text = widget.serviceData!['name'] ?? '';
      selectedCategory = widget.serviceData!['category'];
      _descriptionController.text = widget.serviceData!['description'] ?? '';
      _priceController.text = widget.serviceData!['price']?.toString() ?? '';
      _discountedPriceController.text = widget.serviceData!['discounted_price']?.toString() ?? '';
      _selectedDuration = widget.serviceData!['duration'];
      homeService = widget.serviceData!['home_service'] ?? false;
      weddingService = widget.serviceData!['wedding_service'] ?? false;
      allowCommission = widget.serviceData!['allow_commission'] ?? false;
      selectedStaff = widget.serviceData!['staff'];
      _bookingInterval = widget.serviceData!['booking_interval'];
      _taxRate = widget.serviceData!['tax_rate'];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceNameController.dispose();
    _categoryDescController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _newCategoryNameController.dispose();
    _newCategoryDescController.dispose();
    _newServiceNameController.dispose();
    _newServiceDescController.dispose();
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
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _dec(label: label, hint: hint, helper: helper),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _dropdown(
    List<String> items,
    String? selected,
    ValueChanged<String?> onChanged, {
    String? label,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _dec(label: label, hint: hint, helper: helper),
      isExpanded: true,
      borderRadius: BorderRadius.circular(8),
      menuMaxHeight: 300,
      dropdownColor: Colors.white,
    );
  }

  void _showAddCategoryForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Add Category", 
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )
                    )
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
                hint: "e.g. Hair Coloring"
              ),
              const SizedBox(height: 12),
              _input(
                _newCategoryDescController, 
                label: "Description", 
                hint: "Optional", 
                maxLines: 2
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: pick image
                },
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text("Add Image", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
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
                      onPressed: () {
                        if (_newCategoryNameController.text.trim().isNotEmpty) {
                          setState(() {
                            categories.add(_newCategoryNameController.text.trim());
                            selectedCategory = _newCategoryNameController.text.trim();
                          });
                          _newCategoryNameController.clear();
                          _newCategoryDescController.clear();
                          Navigator.pop(context);
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
      },
    );
  }

  void _showAddServiceForm() {
    showDialog(
      context: context,
      builder: (context) {
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
                      )
                    )
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
                hint: "e.g. Deluxe Facial"
              ),
              const SizedBox(height: 12),
              _input(
                _newServiceDescController, 
                label: "Description", 
                hint: "Optional", 
                maxLines: 2
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: pick image
                },
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text("Add Image", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
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
                      onPressed: () {
                        if (_newServiceNameController.text.trim().isNotEmpty) {
                          setState(() {
                            serviceNames.add(_newServiceNameController.text.trim());
                            selectedServiceName = _newServiceNameController.text.trim();
                          });
                          _newServiceNameController.clear();
                          _newServiceDescController.clear();
                          Navigator.pop(context);
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
      },
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? "Required" : null;

  String? _priceValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Required";
    final value = double.tryParse(v);
    if (value == null) return "Enter a valid number";
    if (value < 0) return "Cannot be negative";
    return null;
  }

  String? _discountedPriceValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final disc = double.tryParse(v);
    final base = double.tryParse(_priceController.text);
    if (disc == null) return "Enter a valid number";
    if (disc < 0) return "Cannot be negative";
    if (base != null && disc > base) return "Must be ≤ price";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 12),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 11),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 12),
      ),
      visualDensity: VisualDensity.compact,
    );

    Widget spacer([double h = 18]) => SizedBox(height: h);

    // Enhanced section header with smaller font
    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        text, 
        style: theme.textTheme.titleSmall?.copyWith(
          color: Colors.blue.shade900,
          fontSize: 14,
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.serviceData == null ? 'Add Service' : 'Edit Service',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: "Basic Info"),
              Tab(text: "Advanced"),
              Tab(text: "Booking & Tax"),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Basic info
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header("Service Category"),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown(
                                  categories,
                                  selectedCategory,
                                  (val) => setState(() => selectedCategory = val),
                                  label: "Category",
                                  hint: "Select category",
                                  validator: _required,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _showAddCategoryForm,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          spacer(6),
                          _input(
                            _categoryDescController,
                            maxLines: 2,
                            label: "Category Description",
                            hint: "Optional",
                          ),
                          spacer(12),
                          header("Service Name"),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown(
                                  serviceNames,
                                  selectedServiceName,
                                  (val) => setState(() => selectedServiceName = val),
                                    label: "Service",
                                  hint: "Select service",
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _showAddServiceForm,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom( 
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          spacer(6),
                          _input(
                            _descriptionController,
                            maxLines: 3,
                            label: "Service Description",
                            hint: "Describe the service",
                          ),
                          spacer(6),
                          _input(
                            _serviceNameController,
                            label: "Custom Service Name",
                            hint: "Optional",
                          ),
                          spacer(12),
                          header("Pricing"),
                          _dropdown(
                            durations,
                            _selectedDuration,
                            (val) => setState(() => _selectedDuration = val),
                            label: "Duration",
                            hint: "Select duration",
                            validator: _required,
                          ),
                          spacer(12),
                          Row(
                            children: [
                              Expanded(
                                child: _input(
                                  _priceController,
                                  label: "Price (₹)", 
                                  hint: "0.00",
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],  
                                  validator: _priceValidator,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _input(
                                  _discountedPriceController,
                                  label: "Discounted Price (₹)",
                                  hint: "Optional",
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  validator: _discountedPriceValidator,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Advanced
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header("Staff Assignment"),
                          _dropdown(
                            staffMembers,
                            selectedStaff,
                            (val) => setState(() => selectedStaff = val),
                            label: "Select Staff",
                            hint: "Assign staff to this service",
                          ),
                          spacer(6),
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
                          spacer(12),
                          header("Service Options"),
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
                                    value: homeService,
                                    onChanged: (val) => setState(() => homeService = val),
                                    title: const Text("Enable Home Service", style: TextStyle(fontSize: 13)),
                                    activeColor: Colors.blue,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                  const Divider(height: 16),
                                  SwitchListTile(
                                    value: weddingService,
                                    onChanged: (val) => setState(() => weddingService = val),
                                    title: const Text("Enable Wedding Service", style: TextStyle(fontSize: 13)),
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

                    // Booking & tax
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header("Booking Settings"),
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
                          spacer(12),
                          header("Tax Settings"),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: _dropdown(
                                taxRates,
                                _taxRate,
                                (val) => setState(() => _taxRate = val),
                                label: "Tax Rate",
                                hint: "Select tax rate",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
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
                          'home_service': homeService,
                          'wedding_service': weddingService,
                          'allow_commission': allowCommission,
                          'staff': selectedStaff,
                          'booking_interval': _bookingInterval,
                          'tax_rate': _taxRate,
                        };
                        Navigator.pop(context, serviceData);
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
            ],
          ),
        ),
      ),
    );
  }
}