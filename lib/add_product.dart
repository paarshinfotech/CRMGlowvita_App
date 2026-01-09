import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'services/api_service.dart';
import 'dart:async';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;

  const AddProductPage({super.key, this.existingProduct});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _categoryDescController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productFormController = TextEditingController();
  final TextEditingController _sizeMetricController = TextEditingController();
  final TextEditingController _bodyPartController = TextEditingController();
  final TextEditingController _bodyPartTypeController = TextEditingController();

  String? selectedCategoryId;

  bool isLoadingCategories = true;
  bool isSubmitting = false;

  List<XFile> images = [];
  List<Map<String, dynamic>> categoryObjects = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    if (widget.existingProduct != null) {
      final product = widget.existingProduct!;
      _nameController.text = product['name'] ?? product['productName'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = product['price']?.toString() ?? '';
      _salePriceController.text = product['sale_price']?.toString() ??
          product['salePrice']?.toString() ??
          '';
      _stockController.text = product['stock_quantity']?.toString() ??
          product['stock']?.toString() ??
          '';
      _brandController.text = product['brand'] ?? '';
      _sizeController.text = product['size'] ?? '';
      _categoryDescController.text = product['categoryDescription'] ?? '';

      // Handle keyIngredients (can be string or list)
      final ingredients = product['keyIngredients'];
      if (ingredients is List) {
        _ingredientsController.text = ingredients.join(', ');
      } else {
        _ingredientsController.text = ingredients?.toString() ?? '';
      }

      _categoryController.text = product['category'] ?? '';
      _productFormController.text = product['productForm'] ?? '';
      _sizeMetricController.text = product['sizeMetric'] ?? '';
      _bodyPartController.text = product['forBodyPart'] ?? '';
      _bodyPartTypeController.text = product['bodyPartType'] ?? '';

      // Handle both XFile objects and file paths
      final existingImages =
          product['images'] ?? product['productImages'] ?? [];
      if (existingImages is List<XFile>) {
        images = List<XFile>.from(existingImages);
      } else if (existingImages is List<String>) {
        // Convert file paths back to XFile objects for display
        images = existingImages.map((path) => XFile(path)).toList();
      } else if (existingImages is List) {
        // Handle mixed list or other formats
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
    _sizeController.dispose();
    _ingredientsController.dispose();
    _categoryDescController.dispose();
    _categoryController.dispose();
    _productFormController.dispose();
    _sizeMetricController.dispose();
    _bodyPartController.dispose();
    _bodyPartTypeController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories = await ApiService.getProductCategories();
      setState(() {
        categoryObjects = fetchedCategories;
        isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<String> _imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage(
      maxWidth: 1080,
      imageQuality: 85,
    );
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

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Category Description',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
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
                await ApiService.addProductCategory(
                  nameController.text,
                  descController.text,
                );
                if (mounted) {
                  await _fetchCategories();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Category "${nameController.text}" added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty || _salePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final stockQuantity = int.tryParse(_stockController.text) ?? 0;
      final price = int.tryParse(_priceController.text) ?? 0;
      final salePrice = int.tryParse(_salePriceController.text) ?? 0;

      // Convert images to base64
      List<String> base64Images = [];
      for (var image in images) {
        // If it's a network image (URL), we might need to handle it differently
        // but for now we assume they are local files from picker
        if (image.path.startsWith('http')) {
          base64Images.add(image.path); // Keep the URL if it's already a URL
        } else {
          base64Images.add(await _imageToBase64(File(image.path)));
        }
      }

      final productData = {
        'productName': _nameController.text,
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'categoryDescription': _categoryDescController.text,
        'price': price,
        'salePrice': salePrice,
        'stock': stockQuantity,
        'productImages': base64Images,
        'isActive': true,
        'size': _sizeController.text,
        'sizeMetric': _sizeMetricController.text,
        'keyIngredients': _ingredientsController.text,
        'forBodyPart': _bodyPartController.text,
        'bodyPartType': _bodyPartTypeController.text,
        'productForm': _productFormController.text,
        'brand': _brandController.text,
        if (widget.existingProduct != null &&
            widget.existingProduct!['status'] != null)
          'status': widget.existingProduct!['status'].toString().toLowerCase(),
      };

      bool success;
      if (widget.existingProduct != null) {
        final productId =
            widget.existingProduct!['_id'] ?? widget.existingProduct!['id'];
        success = await ApiService.updateProduct(productId, productData);
      } else {
        success = await ApiService.createProduct(productData);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingProduct == null
                  ? 'Product created successfully'
                  : 'Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to trigger refresh
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Request timed out. Images might be too large or the internet is slow.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProduct == null ? 'Add Product' : 'Edit Product',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
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
                                              errorBuilder: (ctx, err, st) =>
                                                  Container(
                                                width: 75,
                                                height: 75,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                    Icons.broken_image),
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
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
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
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                            value: categoryObjects.any((cat) =>
                                    cat['name'] == _categoryController.text)
                                ? _categoryController.text
                                : null,
                            hint: Text(
                              isLoadingCategories
                                  ? 'Loading...'
                                  : 'Select Category',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                            isExpanded: true,
                            items: categoryObjects
                                .map((cat) => DropdownMenuItem(
                                      value: cat['name'].toString(),
                                      child: Text(cat['name'].toString(),
                                          style: GoogleFonts.poppins(
                                              fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _categoryController.text = value ?? '';
                                final selectedCat = categoryObjects.firstWhere(
                                  (cat) => cat['name'] == value,
                                  orElse: () => {},
                                );
                                _categoryDescController.text =
                                    selectedCat['description'] ?? '';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Add',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Description (Auto-filled or manual)
                _buildSectionTitle('Category Description'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _categoryDescController,
                  hint: 'Category description...',
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 16),

                // Brand & Product Form
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Brand Name'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _brandController,
                            hint: 'e.g. GlowVita',
                            icon: Icons.branding_watermark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Product Form'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _productFormController,
                            hint: 'e.g. Serum',
                            icon: Icons.bubble_chart,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Price (₹)'),
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

                // Size and Size Metric
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
                            hint: 'e.g. 100',
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
                          _buildSectionTitle('Metric'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _sizeMetricController,
                            hint: 'e.g. ml',
                            icon: Icons.scale,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Body Part & Type
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('For Body Part'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _bodyPartController,
                            hint: 'e.g. Face',
                            icon: Icons.accessibility,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Body Part Type'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _bodyPartTypeController,
                            hint: 'e.g. Oily Skin',
                            icon: Icons.opacity,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Key Ingredients
                _buildSectionTitle('Key Ingredients (comma separated)'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _ingredientsController,
                  hint: 'e.g. Neem, Aloe Vera',
                  icon: Icons.list_alt,
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
                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
          if (isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
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
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
