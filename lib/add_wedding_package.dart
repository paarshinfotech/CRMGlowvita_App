import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class CreateWeddingPackageDialog extends StatefulWidget {
  final WeddingPackage? package;
  const CreateWeddingPackageDialog({super.key, this.package});

  @override
  State<CreateWeddingPackageDialog> createState() =>
      _CreateWeddingPackageDialogState();
}

class _CreateWeddingPackageDialogState
    extends State<CreateWeddingPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _staffCountController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  List<Map<String, dynamic>> selectedServices = [];
  List<Service> availableServices = [];
  List<StaffMember> availableStaff = [];
  bool isLoading = true;
  String? errorMessage;
  Service? selectedServiceForAdd;
  final _qtyControllerForAdd = TextEditingController(text: '1');
  bool _reqStaffForAdd = true;

  // Image & Multi-Staff State
  File? _coverImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  List<StaffMember> _selectedStaff = [];
  bool _submitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String? imageBase64;
      if (_coverImage != null) {
        final bytes = await _coverImage!.readAsBytes();
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (widget.package != null && _existingImageUrl == null) {
        // If editing and existing image was removed, send empty string or null to indicate removal
        // Depending on backend, might need to send a specific flag or empty string.
        // Assuming sending 'image': null or empty string updates it.
        imageBase64 =
            ''; // Or null, try empty string first or based on API behavior
      }

      final Map<String, dynamic> packageData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'services': selectedServices.map((item) {
          final service = item['service'] as Service;
          return {
            'serviceId': service.id,
            'serviceName': service.name,
            'quantity': item['qty'],
            'staffRequired': item['requiresStaff'],
            'price': service.discountedPrice ?? service.price,
          };
        }).toList(),
        'totalPrice': totalPrice,
        'discountedPrice': double.tryParse(_priceController.text) ?? totalPrice,
        'duration': totalDuration,
        'staffCount': int.tryParse(_staffCountController.text) ?? 0,
        'assignedStaff': _selectedStaff.map((s) => s.id).toList(),
      };

      if (_coverImage != null) {
        packageData['image'] = imageBase64;
      } else if (widget.package != null && _existingImageUrl == null) {
        // Image was removed
        packageData['image'] = null;
      }

      final success = widget.package == null
          ? await ApiService.createWeddingPackage(packageData)
          : await ApiService.updateWeddingPackage(
              widget.package!.id, packageData);

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.package == null
                  ? 'Wedding package created successfully'
                  : 'Wedding package updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _nameController.text = widget.package!.name ?? '';
      _descController.text = widget.package!.description ?? '';
      _staffCountController.text = (widget.package!.staffCount ?? 1).toString();
      _priceController.text = (widget.package!.discountedPrice ?? 0).toString();
      _existingImageUrl = widget.package!.image;
    }
    _fetchInitialData();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          _coverImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        ApiService.getServices(),
        ApiService.getStaff(),
      ]);
      if (mounted) {
        setState(() {
          availableServices = results[0] as List<Service>;
          availableStaff = results[1] as List<StaffMember>;

          if (widget.package != null) {
            // Pre-fill Services
            selectedServices = (widget.package!.services ?? []).map((s) {
              final serviceId = s['serviceId'];
              final avaService = availableServices.firstWhere(
                  (as) => as.id == serviceId,
                  orElse: () => Service(name: s['serviceName'] ?? 'Unknown'));
              return {
                'service': avaService,
                'qty': s['quantity'] ?? 1,
                'requiresStaff': s['staffRequired'] ?? false,
              };
            }).toList();

            // Pre-fill Staff
            _selectedStaff = (widget.package!.assignedStaff ?? []).map((id) {
              return availableStaff.firstWhere((st) => st.id == id,
                  orElse: () => StaffMember(fullName: 'Unknown'));
            }).toList();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: $e';
          isLoading = false;
        });
      }
    }
  }

  double get totalPrice {
    return selectedServices.fold(0.0, (sum, item) {
      final service = item['service'] as Service;
      final qty = item['qty'] as int;
      final price = service.discountedPrice ?? service.price ?? 0.0;
      return sum + (price * qty);
    });
  }

  int get totalDuration {
    return selectedServices.fold(0, (sum, item) {
      final service = item['service'] as Service;
      final qty = item['qty'] as int;
      return sum + ((service.duration ?? 0) * qty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLarge = size.width > 900;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: isLarge ? 880 : size.width * 0.90,
          maxWidth: isLarge ? 880 : size.width * 0.90,
          maxHeight: size.height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Package',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                          ? Center(
                              child: Text(errorMessage!,
                                  style:
                                      GoogleFonts.poppins(color: Colors.red)))
                          : SingleChildScrollView(
                              child: isLarge
                                  ? _buildDesktopLayout()
                                  : _buildMobileLayout(),
                            ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submitting ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF331F33),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Create',
                              style: GoogleFonts.poppins(fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Package Name', 'e.g. Bridal Glow', _nameController),
              _buildField('Description', 'Details...', _descController,
                  maxLines: 3),
              _buildImageUpload(),
              const SizedBox(height: 14),
              _buildServiceSelection(),
              const SizedBox(height: 16),
              _buildAddedServicesList(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryBox(),
              const SizedBox(height: 16),
              _buildField('Staff Required', '1', _staffCountController,
                  keyboardType: TextInputType.number,
                  helperText:
                      'Number of professionals needed to perform this package'),
              _buildField('Discount Price', '₹0', _priceController,
                  keyboardType: TextInputType.number),
              _buildStaffDropdown(
                  'Assign Staff (Optional)', 'Select staff members'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryBox(),
        const SizedBox(height: 16),
        _buildField('Package Name', 'e.g. Bridal Glow', _nameController),
        _buildField('Description', 'Details...', _descController, maxLines: 3),
        _buildImageUpload(),
        _buildField('Staff Required', '1', _staffCountController,
            keyboardType: TextInputType.number,
            helperText:
                'Number of professionals needed to perform this package'),
        _buildStaffDropdown('Assign Staff (Optional)', 'Select staff members'),
        _buildField('Discount Price', '₹0', _priceController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildServiceSelection(),
        const SizedBox(height: 16),
        _buildAddedServicesList(),
      ],
    );
  }

  Widget _buildField(
      String label, String hint, TextEditingController controller,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800)),
        const SizedBox(height: 3),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                fontSize: 12.5, color: Colors.grey.shade600),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide:
                    const BorderSide(color: Color(0xFF331F33), width: 1)),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText,
              style: GoogleFonts.poppins(
                  fontSize: 10.5, color: Colors.grey.shade500)),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStaffDropdown(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: Colors.grey.shade600)),
              items: availableStaff
                  .where(
                      (staff) => !_selectedStaff.any((s) => s.id == staff.id))
                  .map((staff) {
                return DropdownMenuItem<String>(
                  value: staff.id,
                  child: Text(staff.fullName ?? 'Unknown',
                      style: GoogleFonts.poppins(fontSize: 13)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  final staff = availableStaff.firstWhere((s) => s.id == v);
                  setState(() {
                    _selectedStaff.add(staff);
                  });
                }
              },
            ),
          ),
        ),
        if (_selectedStaff.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedStaff.map((staff) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(staff.fullName ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF331F33),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStaff.removeWhere((s) => s.id == staff.id);
                        });
                      },
                      child: const Icon(Icons.close,
                          size: 14, color: Color(0xFF331F33)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 5),
        Text(
            '${availableStaff.length} staff members available. Select those who can perform this package.',
            style:
                GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cover Image',
            style: GoogleFonts.poppins(
                fontSize: 11.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(7),
              color: Colors.grey.shade50,
              image: _coverImage != null
                  ? DecorationImage(
                      image: FileImage(_coverImage!),
                      fit: BoxFit.cover,
                    )
                  : (_existingImageUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(_existingImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: (_coverImage == null && _existingImageUrl == null)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 24, color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text('Add image',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5, color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _coverImage = null;
                              _existingImageUrl = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSummaryBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary',
            style: GoogleFonts.poppins(
                fontSize: 11.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(7)),
          child: Column(
            children: [
              _buildSummaryLine('Services', '${selectedServices.length}'),
              _buildSummaryLine('Duration',
                  '${totalDuration ~/ 60} h ${totalDuration % 60} m'),
              ValueListenableBuilder(
                  valueListenable: _staffCountController,
                  builder: (context, value, child) {
                    return _buildSummaryLine('Staff', value.text);
                  }),
              const Divider(height: 15, thickness: 0.5),
              _buildSummaryLine(
                  'Service Total', '₹${totalPrice.toStringAsFixed(2)}'),
              ValueListenableBuilder(
                  valueListenable: _priceController,
                  builder: (context, value, child) {
                    final customPrice = double.tryParse(value.text);
                    if (customPrice != null) {
                      return _buildSummaryLine(
                        'Discounted Price',
                        '₹${customPrice.toStringAsFixed(2)}',
                        bold: true,
                        valueColor: Colors.green.shade700,
                      );
                    }
                    return _buildSummaryLine(
                        'Package Price', '₹${totalPrice.toStringAsFixed(2)}',
                        bold: true);
                  }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryLine(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey.shade700)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: valueColor,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Add Services to Package',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                if (selectedServiceForAdd != null) {
                  setState(() {
                    // Check if already exists, then increment qty instead of adding new?
                    // For now, just add.
                    selectedServices.add({
                      'service': selectedServiceForAdd,
                      'qty': int.tryParse(_qtyControllerForAdd.text) ?? 1,
                      'requiresStaff': _reqStaffForAdd,
                    });
                    selectedServiceForAdd = null;
                    _qtyControllerForAdd.text = '1';
                    _reqStaffForAdd = true;
                  });
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text('Add Service',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF331F33),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Service>(
                        isExpanded: true,
                        value: selectedServiceForAdd,
                        hint: Text('Select service…',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: Colors.grey.shade600)),
                        items: availableServices.map((service) {
                          return DropdownMenuItem<Service>(
                            value: service,
                            child: Text(service.name ?? 'Unknown',
                                style: GoogleFonts.poppins(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() => selectedServiceForAdd = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildField('Quantity', '1', _qtyControllerForAdd,
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  Checkbox(
                      value: _reqStaffForAdd,
                      activeColor: const Color(0xFF331F33),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) {
                        setState(() => _reqStaffForAdd = v ?? true);
                      }),
                  Text('Staff Required',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade800)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddedServicesList() {
    final size = MediaQuery.of(context).size;
    final isLarge = size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Package Services',
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (selectedServices.isEmpty)
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(7)),
            child: Center(
              child: Text('No services added',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500)),
            ),
          )
        else
          ...selectedServices.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final service = item['service'] as Service;
            final qty = item['qty'] as int;
            final price = service.discountedPrice ?? service.price ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLarge) ...[
                          Row(
                            children: [
                              Text(service.name ?? 'Unknown',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              _buildCategoryChip(service.category),
                            ],
                          ),
                        ] else ...[
                          Text(service.name ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          _buildCategoryChip(service.category),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quantity Controls
                  _buildQtyControls(qty, index),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => selectedServices.removeAt(index)),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${(price * qty).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${(service.duration ?? 0) * qty} min',
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildCategoryChip(String? category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(category ?? 'Uncategorized',
          style: GoogleFonts.poppins(
              fontSize: 9,
              color: const Color(0xFF331F33),
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildQtyControls(int qty, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyBtn(Icons.remove, () {
            if (qty > 1) {
              setState(() => selectedServices[index]['qty'] = qty - 1);
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$qty',
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          _buildQtyBtn(Icons.add, () {
            setState(() => selectedServices[index]['qty'] = qty + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 12, color: Colors.grey.shade700),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _staffCountController.dispose();
    _priceController.dispose();
    _qtyControllerForAdd.dispose();
    super.dispose();
  }
}
