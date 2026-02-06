import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  String? selectedCategory;
  List<XFile> images = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [
    'Skin Care',
    'Body Care',
    'Hair Care',
    'Makeup',
    'Nails Care',
    'Males Grooming',
    'Beauty Tools and Accessories'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final product = widget.existingProduct!;
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = product['price'] ?? '';
      _salePriceController.text = product['sale_price'] ?? '';
      _stockController.text = product['stock_quantity']?.toString() ?? '';
      _brandController.text = product['brand'] ?? '';
      _productTypeController.text = product['product_type'] ?? '';
      _sizeController.text = product['size'] ?? '';
      _sizeMetricController.text = product['size_metric'] ?? '';
      _bodyPartController.text = product['body_part'] ?? '';
      _bodyPartTypeController.text = product['body_part_type'] ?? '';
      _keyIngredientsController.text = product['key_ingredients'] ?? '';
      selectedCategory = product['category'];

      final existingImages = product['images'] ?? [];
      if (existingImages is List) {
        images = existingImages
            .where((item) => item != null)
            .map((item) => item is XFile ? item : XFile(item.toString()))
            .toList();
      }
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

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Category Name',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  categories.add(nameController.text);
                  selectedCategory = nameController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Category "${nameController.text}" added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
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

  void _submitProduct() {
    if (_nameController.text.isEmpty ||
        _salePriceController.text.isEmpty ||
        _brandController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final stockQuantity = int.tryParse(_stockController.text) ?? 0;
    final imagePaths = images.map((image) => image.path).toList();

    Navigator.pop(context, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text,
      'description': _descriptionController.text,
      'category': selectedCategory,
      'images': imagePaths,
      'price': _priceController.text,
      'sale_price': _salePriceController.text,
      'stock_quantity': stockQuantity,
      'rating': 4.4,
      'brand': _brandController.text,
      'product_type': _productTypeController.text,
      'size': _sizeController.text,
      'size_metric': _sizeMetricController.text,
      'body_part': _bodyPartController.text,
      'body_part_type': _bodyPartTypeController.text,
      'key_ingredients': _keyIngredientsController.text,
    });
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                                  child: Image.file(
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
                        value: selectedCategory,
                        hint: Text(
                          'Select Category',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        isExpanded: true,
                        items: categories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category,
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCategory = value),
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
            const SizedBox(height: 24),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitProduct,
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
