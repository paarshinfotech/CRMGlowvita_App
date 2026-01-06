import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_services.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  List<Service> services = [];
  bool isLoading = true;
  String? errorMessage;

  String? selectedCategory;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Set<String> get dynamicCategories {
    final cats = services.map((s) => s.category).whereType<String>().toSet();
    cats.add('All');
    return cats;
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = 'All';
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedServices = await ApiService.getServices();
      setState(() {
        services = fetchedServices;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
    if (result != null) _fetchServices();
  }

  void _editService(int index) async {
    final service = filteredServices[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServicePage(serviceData: service.toJson()),
      ),
    );
    if (result != null) _fetchServices();
  }

  void _deleteService(int index) {
    final service = filteredServices[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Service', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${service.name}"?', style: GoogleFonts.poppins(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final success = await ApiService.deleteService(service.id!);
                if (success) {
                  // Refresh the services list from the API
                  _fetchServices();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Service deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete service: ' + e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }



  void _showServiceDetails(Service service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: service.image?.isNotEmpty == true ? NetworkImage(service.image!) : null,
              backgroundColor: Colors.grey.shade100,
              child: service.image?.isNotEmpty != true ? Icon(Icons.spa, size: 24, color: Colors.grey.shade600) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                service.name ?? 'Service Details',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (service.image?.isNotEmpty == true)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      service.image!,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _detailRow('Service Name', service.name ?? 'N/A'),
              _detailRow('Category', service.category ?? 'N/A'),
              _detailRow('Price', '₹${service.price ?? 0}'),
              if (service.discountedPrice != null && service.discountedPrice! < (service.price ?? 0))
                _detailRow('Discounted Price', '₹${service.discountedPrice}', color: Colors.green.shade700),
              _detailRow('Duration', service.duration != null ? '${service.duration} min' : 'N/A'),
              _detailRow('Gender', service.gender ?? 'unisex'),
              _detailRow('Booking Interval', service.bookingInterval != null ? '${service.bookingInterval} min' : 'N/A'),
              _detailRow('Online Booking', service.onlineBooking == true ? 'Enabled' : 'Disabled'),
              _detailRow('Commission', service.commission == true ? 'Enabled' : 'Disabled'),
              _detailRow('Status', service.status ?? 'N/A'),
              _detailRow('Home Service', service.homeService == true ? 'Available' : 'Not Available'),
              _detailRow('Wedding Service', service.eventService == true ? 'Available' : 'Not Available'),
              _detailRow('Tax', service.tax != null ? service.tax.toString() : 'N/A'),
              _detailRow('Created At', service.createdAt != null ? service.createdAt.toString() : 'N/A'),
              _detailRow('Updated At', service.updatedAt != null ? service.updatedAt.toString() : 'N/A'),
              _detailRow('Prep Time', service.prepTime != null ? '${service.prepTime} min' : 'N/A'),
              _detailRow('Cleanup Time', service.setupCleanupTime != null ? '${service.setupCleanupTime} min' : 'N/A'),
              const SizedBox(height: 16),
              Text('Description', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                service.description?.isNotEmpty == true ? service.description! : 'No description provided.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins(fontSize: 15, color: Colors.blue.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 14, color: color ?? Colors.black87)),
          ),
        ],
      ),
    );
  }

  List<Service> get filteredServices {
    return services.where((service) {
      final matchesSearch = (service.name ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (service.category ?? '').toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All' || (service.category ?? '').toLowerCase() == selectedCategory!.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get totalServices => services.length;
  int get totalCategories => services.map((s) => s.category).whereType<String>().toSet().length;

  double get averageServicePrice {
    if (services.isEmpty) return 0.0;
    return services.fold(0.0, (sum, s) => sum + (s.discountedPrice ?? s.price ?? 0)) / services.length;
  }

  String get mostPopularService => services.isEmpty ? 'N/A' : (services.first.name ?? 'N/A');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      drawer: const CustomDrawer(currentPage: 'Services'),
      appBar: AppBar(
        title: Text('Services', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        surfaceTintColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 20),
                    Text('Failed to load services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _fetchServices,
                      child: Text('Retry', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar - Minimal
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Grid - 2 cards per row
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _minimalStatCard('Total', '$totalServices', Colors.blue.shade600);
                        case 1:
                          return _minimalStatCard('Categories', '$totalCategories', Colors.purple.shade600);
                        case 2:
                          return _minimalStatCard('Avg Price', '₹${averageServicePrice.toStringAsFixed(0)}', Colors.green.shade600);
                        case 3:
                          return _minimalStatCard('Top', mostPopularService, Colors.orange.shade600);
                        default:
                          return Container();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Category Chips - Clean
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dynamicCategories.map((cat) {
                      final selected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat, style: GoogleFonts.poppins(fontSize: 13)),
                          selected: selected,
                          onSelected: (_) => setState(() => selectedCategory = cat),
                          selectedColor: Colors.blue.shade50,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: selected ? Colors.blue.shade400 : Colors.transparent),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Header + Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('All Services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: _navigateToAddService,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Add Service', style: GoogleFonts.poppins(fontSize: 14)),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Services Grid - Clean & Minimal Cards
                Expanded(
                  child: filteredServices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.spa_outlined, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No services found',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : (constraints.maxWidth < 1000 ? 2 : 3),
                            childAspectRatio: isMobile ? 2.8 : 1.4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            final isOnlineBooking = service.onlineBooking ?? false;
                            final origPrice = (service.price ?? 0).toDouble();
                            final discPrice = (service.discountedPrice ?? origPrice).toDouble();
                            final duration = service.duration != null ? '${service.duration} min' : '—';

                            return Card(
                              elevation: 0,
                              color: Colors.grey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Small Circular Image
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: service.image?.isNotEmpty == true ? NetworkImage(service.image!) : null,
                                      child: service.image?.isNotEmpty != true
                                          ? Icon(Icons.spa, size: 24, color: Colors.grey.shade600)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Service Name with Status
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  service.name ?? 'Unnamed Service',
                                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (service.status?.toLowerCase() == 'approved') ? Colors.green.shade100 : Colors.orange.shade100,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: (service.status?.toLowerCase() == 'approved') ? Colors.green.shade300 : Colors.orange.shade300, width: 0.5),
                                                ),
                                                child: Text(
                                                  service.status ?? 'Pending',
                                                  style: GoogleFonts.poppins(fontSize: 10, color: (service.status?.toLowerCase() == 'approved') ? Colors.green.shade700 : Colors.orange.shade700),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Category and Duration
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.blue.shade200, width: 0.5),
                                                ),
                                                child: Text(
                                                  service.category ?? 'Category',
                                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue.shade700),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade700),
                                                    const SizedBox(width: 2),
                                                    Text(duration, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                '₹${origPrice.toStringAsFixed(0)}',
                                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blue.shade700),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Switch(
                                          value: isOnlineBooking,
                                          onChanged: (val) {
                                            setState(() {
                                              final originalIndex = services.indexOf(filteredServices[index]);
                                              if (originalIndex != -1) {
                                                services[originalIndex].onlineBooking = val;
                                              }
                                            });
                                          },
                                          activeColor: Colors.green.shade600,
                                          thumbColor: WidgetStateProperty.all(Colors.white),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const SizedBox(height: 8),
                                        PopupMenuButton<String>(
                                          color: Colors.white, // White background for menu
                                          icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                                          onSelected: (String result) {
                                            if (result == 'View') {
                                              _showServiceDetails(service);
                                            } else if (result == 'Edit') {
                                              _editService(index);
                                            } else if (result == 'Delete') {
                                              _deleteService(index);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                            PopupMenuItem<String>(
                                              value: 'View',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility, color: Colors.blue.shade600, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('View', style: GoogleFonts.poppins(fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, color: Colors.orange.shade600, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('Edit', style: GoogleFonts.poppins(fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'Delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red.shade600, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('Delete', style: GoogleFonts.poppins(fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _minimalStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
