import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AddSuppProductPage extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;

  const AddSuppProductPage({super.key, this.existingProduct});

  @override
  State<AddSuppProductPage> createState() => _AddSuppProductPageState();
}

class _AddSuppProductPageState extends State<AddSuppProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _productTypeController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _sizeMetricController = TextEditingController();
  final TextEditingController _bodyPartController = TextEditingController();
  final TextEditingController _bodyPartTypeController = TextEditingController();
  final TextEditingController _keyIngredientsController =
      TextEditingController();

  String? selectedCategoryId;
  String? selectedCategoryName;
  bool _showOnWebsite = true;
  List<XFile> images = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    if (widget.existingProduct != null) {
      final product = widget.existingProduct!;
      _nameController.text =
          (product['name'] ?? product['productName'] ?? '').toString();
      _descriptionController.text = (product['description'] ?? '').toString();
      _priceController.text = (product['price'] ?? '').toString();
      _salePriceController.text =
          (product['salePrice'] ?? product['sale_price'] ?? '').toString();
      _stockController.text =
          (product['stock'] ?? product['stock_quantity'] ?? '').toString();
      _brandController.text = (product['brand'] ?? '').toString();
      _productTypeController.text =
          (product['productForm'] ?? product['product_type'] ?? '').toString();
      _sizeController.text = (product['size'] ?? '').toString();
      _sizeMetricController.text =
          (product['sizeMetric'] ?? product['size_metric'] ?? '').toString();
      _bodyPartController.text =
          (product['forBodyPart'] ?? product['body_part'] ?? '').toString();
      _bodyPartTypeController.text =
          (product['bodyPartType'] ?? product['body_part_type'] ?? '')
              .toString();
      _keyIngredientsController.text = (product['keyIngredients'] is List
          ? (product['keyIngredients'] as List).join(', ')
          : (product['keyIngredients'] ?? product['key_ingredients'] ?? '')
              .toString());

      selectedCategoryId = product['category'] is Map
          ? product['category']['_id']
          : product['category'];
      selectedCategoryName =
          product['category'] is Map ? product['category']['name'] : null;
      _showOnWebsite = product['showOnWebsite'] ?? true;

      final existingImages =
          product['productImages'] ?? product['images'] ?? [];
      if (existingImages is List) {
        images = existingImages
            .where((item) => item != null)
            .map((item) => item is XFile ? item : XFile(item.toString()))
            .toList();
      }
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final cats = await ApiService.getCRMProductCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;

        if (selectedCategoryId != null) {
          final match =
              _categories.any((c) => c['_id'].toString() == selectedCategoryId);
          if (!match) {
            // Try matching by name if ID doesn't work (useful if name was stored as ID)
            final nameMatch = _categories.firstWhere(
                (c) =>
                    c['name'] == selectedCategoryId ||
                    c['name'] == selectedCategoryName,
                orElse: () => {});
            if (nameMatch.isNotEmpty) {
              selectedCategoryId = nameMatch['_id'].toString();
            } else {
              // If still no match and it's not a valid ID, we might need to null it to avoid crash
              // But we can also keep it and let the DropdownButton value check handle it
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _productTypeController.dispose();
    _sizeController.dispose();
    _sizeMetricController.dispose();
    _bodyPartController.dispose();
    _bodyPartTypeController.dispose();
    _keyIngredientsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage();
    if (pickedImages.length + images.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can upload up to 5 images only.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      images.addAll(pickedImages);
    });
  }

  Future<String> _imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  final newCat = await ApiService.addCRMProductCategory(
                    nameController.text,
                    descController.text,
                  );
                  await _fetchCategories();
                  setState(() {
                    selectedCategoryId = newCat['_id'];
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Category "${nameController.text}" added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding category: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor),
            child: Text('Add', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty ||
        _salePriceController.text.isEmpty ||
        _brandController.text.isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill in all required fields (*) including Category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Find category name instead of ID for the payload
      final categoryMap = _categories.firstWhere(
        (c) => c['_id'].toString() == selectedCategoryId,
        orElse: () => {},
      );
      final categoryName = categoryMap['name'] ?? selectedCategoryId;

      // Convert new local images to base64 and combine with existing URLs
      final List<String> finalImages = [];

      for (var img in images) {
        if (img.path.startsWith('http')) {
          finalImages.add(img.path);
        } else {
          finalImages.add(await _imageToBase64(File(img.path)));
        }
      }

      final Map<String, dynamic> productData = {
        'productName': _nameController.text,
        'description': _descriptionController.text,
        'category': categoryName,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'salePrice': double.tryParse(_salePriceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'brand': _brandController.text,
        'productForm': _productTypeController.text,
        'size': _sizeController.text,
        'sizeMetric': _sizeMetricController.text,
        'forBodyPart': _bodyPartController.text,
        'bodyPartType': _bodyPartTypeController.text,
        'keyIngredients': _keyIngredientsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'showOnWebsite': _showOnWebsite,
        'isActive': _showOnWebsite,
        'productImages': finalImages,
      };

      bool success;
      if (widget.existingProduct == null) {
        success = await ApiService.createProduct(productData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Product created successfully'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        final id =
            widget.existingProduct!['_id'] ?? widget.existingProduct!['id'];
        success = await ApiService.updateProduct(id.toString(), productData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Product updated successfully'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProduct == null
              ? 'Add Supplier Product'
              : 'Edit Supplier Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name *
            _buildSectionTitle('Product Name *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _nameController,
              hint: 'Enter product name',
              icon: Icons.inventory_2,
            ),
            const SizedBox(height: 16),

            // Product Images
            _buildSectionTitle('Product Images (Max 5)'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  if (images.isEmpty)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Click to upload images',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...images.map((img) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: img.path.startsWith('http')
                                      ? Image.network(
                                          img.path,
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 75,
                                            height: 75,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.error,
                                                size: 20),
                                          ),
                                        )
                                      : Image.file(
                                          File(img.path),
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        images.remove(img);
                                      });
                                    },
                                    icon: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                )
                              ],
                            )),
                        if (images.length < 5)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                Icons.add_photo_alternate,
                                color: Colors.grey.shade600,
                                size: 25,
                              ),
                            ),
                          )
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            _buildSectionTitle('Description'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Enter product description',
              icon: Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Category
            _buildSectionTitle('Category'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (_categories.any((cat) =>
                                cat['_id'].toString() == selectedCategoryId))
                            ? selectedCategoryId
                            : null,
                        hint: Text(
                          _isLoadingCategories
                              ? 'Loading...'
                              : 'Select Category',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        isExpanded: true,
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat['_id'].toString(),
                                  child: Text(cat['name'] ?? '',
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCategoryId = value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Brand *
            _buildSectionTitle('Brand *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _brandController,
              hint: 'Enter brand name',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),

            // Product Type
            _buildSectionTitle('Product Type'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _productTypeController,
              hint: 'e.g., Serum, Cream, Oil, Powder',
              icon: Icons.spa,
            ),
            const SizedBox(height: 16),

            // Size + Size Metric
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Size'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _sizeController,
                        hint: 'e.g., 30, 50, 100',
                        icon: Icons.straighten,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Size Metric'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _sizeMetricController,
                        hint: 'e.g., ml, grams, litre, pieces',
                        icon: Icons.scale,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Body Part
            _buildSectionTitle('For Body Part'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _bodyPartController,
              hint: 'e.g., Face, Body Skin, Hair, Nails',
              icon: Icons.accessibility,
            ),
            const SizedBox(height: 16),

            // Skin/Hair Type
            _buildSectionTitle('Suitable For (Skin/Hair Type)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _bodyPartTypeController,
              hint: 'e.g., Oily Skin, Dry Skin, Sensitive Skin',
              icon: Icons.face,
            ),
            const SizedBox(height: 16),

            // Key Ingredients
            _buildSectionTitle('Key Ingredients'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _keyIngredientsController,
              hint: 'e.g., Vitamin C, Hyaluronic Acid, Niacinamide',
              icon: Icons.science,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Pricing
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Regular Price (₹)'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _priceController,
                        hint: '0.00',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Sale Price (₹) *'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _salePriceController,
                        hint: '0.00',
                        icon: Icons.local_offer,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock Quantity
            _buildSectionTitle('Stock Quantity'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _stockController,
              hint: 'Enter stock quantity',
              icon: Icons.inventory,
              keyboardType: TextInputType.number,
            ),
            // Show on Website
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Show on Website',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Switch(
                        value: _showOnWebsite,
                        onChanged: (v) => setState(() => _showOnWebsite = v),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  Text(
                    'Decide whether this product should be displayed on the public website.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  widget.existingProduct == null
                      ? 'Save Product'
                      : 'Update Product',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        filled: true,
        fillColor: Colors.white,
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
              BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 13)),
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: GoogleFonts.poppins(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
