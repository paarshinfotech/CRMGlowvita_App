import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_services.dart';
import 'widgets/custom_drawer.dart';

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _Services();
}

class _Services extends State<Services> {
  List<Map<String, dynamic>> services = [
    {
      'name': 'Basic Haircut',
      'category': 'Hair',
      'duration': '30 min',
      'price': 250.0,
      'discounted_price': 200.0,
      'is_active': true,
      'home_service': true,
      'event_service': false,
    },
    {
      'name': 'Manicure',
      'category': 'Nails',
      'duration': '45 min',
      'price': 350.0,
      'discounted_price': 300.0,
      'is_active': false,
      'home_service': true,
      'event_service': true,
    },
    {
      'name': 'Hair Coloring',
      'category': 'Hair',
      'duration': '2 hours',
      'price': 1200.0,
      'discounted_price': 1000.0,
      'is_active': true,
      'home_service': true,
      'event_service': true,
    },
  ];
  String? selectedCategory;
  String searchQuery = ''; // Add search query field
  final TextEditingController _searchController = TextEditingController(); // Add search controller

  final List<String> categories = [
    'All',
    'Hair',
    'Skin',
    'Nails',
    'Makeup',
    'Male Grooming',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddServicePage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        services.add(result);
      });
    }
  }

  void _deleteService(int index) {
    setState(() {
      services.removeAt(index);
    });
  }

  void _editService(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServicePage(serviceData: services[index]),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        services[index] = result;
      });
    }
  }

  void _toggleSingleRadio(int idx, bool? newVal) {
    setState(() {
      final next = newVal == true;
      services[idx]['is_active'] = next;
    });
  }

  List<Map<String, dynamic>> get filteredServices {
    return services.where((service) {
      final matchesSearch = service['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          service['category'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null || selectedCategory == 'All' || 
          service['category'].toString().toLowerCase() == selectedCategory!.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get totalServices => services.length;

  int get totalCategories {
    final categories = <String>{};
    for (var service in services) {
      if (service['category'] is String) {
        categories.add(service['category']);
      }
    }
    return categories.length;
  }

  double get averageServicePrice {
    if (services.isEmpty) return 0.0;
    double total = 0;
    for (var service in services) {
      total += (service['discounted_price'] as num?)?.toDouble() ??
          (service['price'] as num?)?.toDouble() ??
          0;
    }
    return total / services.length;
  }

  String get mostPopularService {
    if (services.isEmpty) return 'N/A';
    // For now, we'll just return the first service name
    // In a real app, this would be based on sales data
    return services.first['name'] ?? 'N/A';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 150;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color getStatusColor(bool active) =>
      active ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    selectedCategory = 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Services'),
      appBar: AppBar(
        title: Text(
          'Services',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => searchQuery = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search Services...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Count cards in 2 lines
                Column(
                  children: [
                    // First line - Total Services and Most Popular Service
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Total Services Card
                          Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.miscellaneous_services, color: Colors.blue, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Total Services',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$totalServices',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Most Popular Service Card
                          Container(
                            width: 230,
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.star, color: Colors.orange, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Top Selling',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  mostPopularService,
                                  style: GoogleFonts.poppins(
                                    fontSize:12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Second line - Average Service Price and Total Categories
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Average Service Price Card
                          Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.attach_money, color: Colors.green, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Avg. Price',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '₹${averageServicePrice.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Total Categories Card
                          Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.category, color: Colors.purple, size: 18),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Categories',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$totalCategories',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category chips (filters)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final selected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          selectedColor: Colors.blue.shade600,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: GoogleFonts.poppins(
                            color: selected ? Colors.white : Colors.black,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selected
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 5),
                
                // Add Service Button (reduced size)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddService,
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: Text(
                      "Add Service",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 7,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Services grid
                Expanded(
                  child: filteredServices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.miscellaneous_services,
                                  size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                "No services available for this category.",
                                style: GoogleFonts.poppins(
                                    fontSize: 16, color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth < 600
                                ? 1
                                : constraints.maxWidth < 900
                                    ? 2
                                    : 3;

                            return GridView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.0,
                              ),
                              itemCount: filteredServices.length,
                              itemBuilder: (context, index) {
                                final service = filteredServices[index];
                                final isActive = service['is_active'] == true;
                                final origPrice = (service['price'] as num?)?.toDouble() ?? 0.0;
                                final discPrice = (service['discounted_price'] as num?)?.toDouble() ?? origPrice;

                                return Card(
                                  elevation: 1,
                                  color: Colors.white,
                                  shadowColor: Colors.black.withOpacity(0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.grey.shade100,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _editService(index),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  service['name'] ?? '',
                                                  maxLines: crossAxisCount == 1 ? 2 : 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: crossAxisCount == 1 ? 15 : 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: crossAxisCount == 1 ? 40 : 30,
                                                    height: crossAxisCount == 1 ? 40 : 30,
                                                    child: Radio<bool>(
                                                      value: true,
                                                      groupValue: isActive ? true : null,
                                                      toggleable: true,
                                                      fillColor: WidgetStateProperty.resolveWith<Color?>(
                                                        (states) {
                                                          final selected = states.contains(WidgetState.selected);
                                                          return selected ? Colors.green.shade600 : Colors.grey.shade400;
                                                        },
                                                      ),
                                                      onChanged: (val) => _toggleSingleRadio(index, val),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: getStatusColor(isActive).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      isActive ? 'Active' : 'Inactive',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: getStatusColor(isActive),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 5),

                                          // Category, duration, and price in a single row
                                          Row(
                                            children: [
                                              // Category
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.blue.withOpacity(0.3),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  service['category'] ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Duration
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.schedule, size: 15, color: Colors.grey.shade700),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    service['duration'] ?? 'N/A',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              // Price information aligned to the right
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "₹${discPrice.toStringAsFixed(0)}",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: crossAxisCount == 1 ? 16 : 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.blue.shade700,
                                                    ),
                                                  ),
                                                  if (discPrice < origPrice)
                                                    Text(
                                                      "₹${origPrice.toStringAsFixed(0)}",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        color: Colors.grey.shade500,
                                                        decoration: TextDecoration.lineThrough,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 5),
                                          Divider(height: 1, color: Colors.grey.shade200),
                                          const SizedBox(height: 5),
                                          // Action buttons
                                          if (crossAxisCount == 1)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _editService(index),
                                                    icon: Icon(Icons.edit, size: 18),
                                                    label: Text('Edit'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      foregroundColor: Colors.blue.shade700,
                                                      padding: EdgeInsets.symmetric(vertical: 4),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _deleteService(index),
                                                    icon: Icon(Icons.delete, size: 18),
                                                    label: Text('Delete'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.red.shade700,
                                                      side: BorderSide(color: Colors.red.shade700),
                                                      padding: EdgeInsets.symmetric(vertical: 4),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => _editService(index),
                                                  icon: Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                                                  label: Text(
                                                    'Edit',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 9,
                                                      color: Colors.blue.shade700,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                TextButton.icon(
                                                  onPressed: () => _deleteService(index),
                                                  icon: Icon(Icons.delete, size: 14, color: Colors.red.shade700),
                                                  label: Text(
                                                    'Delete',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 8,
                                                      color: Colors.red.shade700,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
