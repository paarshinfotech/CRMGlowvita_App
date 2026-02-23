import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_model.dart';
import 'import_customers.dart';
import 'add_customer.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appointment_model.dart';
import 'billing_invoice_model.dart';
import 'widgets/customer_detail_popup.dart';

class Client extends StatefulWidget {
  const Client({super.key});

  @override
  State<Client> createState() => _ClientState();
}

class _ClientState extends State<Client> with SingleTickerProviderStateMixin {
  // The list now holds Customer objects, providing type safety.
  List<Customer> customers = [];
  int _selectedIndex = 0;
  String _searchQuery = '';

  // Sort state
  int? _sortColumn;
  bool _sortAsc = true;

  // Scroll controllers for synchronized scrolling
  final ScrollController _headerScrollController = ScrollController();
  final List<ScrollController> _rowScrollControllers = [];
  bool _isScrolling = false;

  // TabController for Offline/Online filter
  late TabController _tabController;
  int _currentTabIndex = 0;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        if (_currentTabIndex == 1) {
          _loadOnlineCustomers();
        } else {
          _loadCustomers();
        }
      }
    });

    // Load customers from API
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loadedCustomers = await ApiService.getClients();
      setState(() {
        customers = loadedCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;

        // Check if it's an auth token error
        if (e.toString().contains('No authentication token found')) {
          print('Please log in to access customer data.');
        } else {
          print('Error loading customers: ${e.toString()}');
        }
      });
      // Log error to console only, don't show on screen
      print('Error loading customers: ${e.toString()}');
    }
  }

  Future<void> _loadOnlineCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loadedCustomers = await ApiService.getOnlineClients();
      setState(() {
        customers = loadedCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;

        // Check if it's an auth token error
        if (e.toString().contains('No authentication token found')) {
          print('Please log in to access customer data.');
        } else {
          print('Error loading online customers: ${e.toString()}');
        }
      });
      // Log error to console only, don't show on screen
      print('Error loading online customers: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerScrollController.dispose();
    for (var controller in _rowScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncScroll(double offset, ScrollController source) {
    if (_isScrolling) return;
    _isScrolling = true;

    // Sync header
    if (_headerScrollController.hasClients &&
        source != _headerScrollController) {
      _headerScrollController.jumpTo(offset);
    }

    // Sync all rows
    for (var controller in _rowScrollControllers) {
      if (controller.hasClients && controller != source) {
        controller.jumpTo(offset);
      }
    }

    _isScrolling = false;
  }

  // Async function to handle navigation and receiving data
  void _navigateAndAddCustomer(BuildContext context) async {
    // Wait for the AddCustomer page to return a result
    final newCustomer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomer()),
    );

    // If the user saved a customer (and didn't just press back),
    // add it to the list and refresh the UI.
    if (newCustomer != null) {
      try {
        // Add to API
        final addedCustomer = await ApiService.addClient(newCustomer);
        setState(() {
          customers.add(addedCustomer);
        });
        // Log success to console only, don't show on screen
        print('${addedCustomer.fullName} has been added.');
      } catch (e) {
        // Log error to console only, don't show on screen
        String errorMessage = e.toString();
        print('Error adding customer: $errorMessage');
        if (errorMessage.contains('No authentication token found')) {
          print('Please log in to add customers.');
        }
      }
    }
  }

  void _editCustomer(int index) async {
    final editedCustomer = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomer(existing: customers[index]),
      ),
    );

    if (editedCustomer != null) {
      try {
        // Update via API
        final updatedCustomer = await ApiService.updateClient(editedCustomer);
        setState(() {
          customers[index] = updatedCustomer;
        });
        // Log success to console only, don't show on screen
        print('${updatedCustomer.fullName} has been updated.');
      } catch (e) {
        // Log error to console only, don't show on screen
        String errorMessage = e.toString();
        print('Error updating customer: $errorMessage');
        if (errorMessage.contains('No authentication token found')) {
          print('Please log in to update customers.');
        }
      }
    }
  }

  void _deleteCustomer(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(dialogBackgroundColor: Colors.white),
        child: AlertDialog(
          title: Text('Delete customer',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to delete ${customers[index].fullName}?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text('Cancel', style: GoogleFonts.poppins(fontSize: 12))),
            TextButton(
              onPressed: () async {
                try {
                  // Store the customer name before deletion
                  final customerName = customers[index].fullName;
                  // Delete from API
                  final success =
                      await ApiService.deleteClient(customers[index].id!);
                  if (success) {
                    setState(() {
                      customers.removeAt(index);
                    });
                    Navigator.pop(ctx);
                    // Log success to console only, don't show on screen
                    print('$customerName has been deleted.');
                  }
                } catch (e) {
                  // Log error to console only, don't show on screen
                  Navigator.pop(ctx);
                  String errorMessage = e.toString();
                  print('Error deleting customer: $errorMessage');
                  if (errorMessage.contains('No authentication token found')) {
                    print('Please log in to delete customers.');
                  }
                }
              },
              child: Text('Delete',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  List<Customer> get _filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    List<Customer> filtered = List<Customer>.from(customers);

    // Filter by tab (Offline/Online)
    if (_currentTabIndex == 0) {
      // Offline clients
      filtered = filtered.where((c) => !c.isOnline).toList();
    } else {
      // Online clients
      filtered = filtered.where((c) => c.isOnline).toList();
    }

    // Filter by search query
    if (q.isEmpty) return filtered;
    return filtered.where((c) {
      final name = c.fullName.toLowerCase();
      final mobile = c.mobile.toLowerCase();
      final email = (c.email ?? '').toLowerCase();
      return name.contains(q) || mobile.contains(q) || email.contains(q);
    }).toList();
  }

  void _sortBy(int columnIndex) {
    setState(() {
      _sortAsc = (_sortColumn == columnIndex) ? !_sortAsc : true;
      _sortColumn = columnIndex;
    });
  }

  List<Customer> _applySort(List<Customer> input) {
    if (_sortColumn == null) return input;
    final list = List<Customer>.from(input);
    int cmp(String x, String y) => _sortAsc ? x.compareTo(y) : y.compareTo(x);
    int cmpNum(num x, num y) => _sortAsc ? x.compareTo(y) : y.compareTo(x);

    list.sort((a, b) {
      switch (_sortColumn) {
        case 0: // Name
          return cmp(a.fullName.toLowerCase(), b.fullName.toLowerCase());
        case 1: // Contact
          return cmp(a.mobile, b.mobile);
        case 2: // Last Visit
          return cmp(a.lastVisit ?? '', b.lastVisit ?? '');
        case 3: // Total Booking
          return cmpNum(a.totalBookings, b.totalBookings);
        case 4: // Total Spent
          return cmpNum(a.totalSpent, b.totalSpent);
        case 5: // Status
          return cmp(a.status, b.status);
        default:
          return 0;
      }
    });
    return list;
  }

  // Method to show the customer details pop-up
  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Dimmed background
      builder: (BuildContext context) {
        return CustomerDetailPopup(customer: customer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = customers.length;
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final thisMonth = DateTime(now.year, now.month, 1);
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final totalClientsLastMonth = customers
        .where((c) => c.createdAt != null && c.createdAt!.isBefore(lastMonth))
        .length;
    final newClientsThisMonth = customers
        .where((c) => c.createdAt != null && c.createdAt!.isAfter(thisMonth))
        .length;
    final totalBookings =
        customers.fold<int>(0, (sum, c) => sum + c.totalBookings);
    final totalSpent =
        customers.fold<double>(0.0, (sum, c) => sum + c.totalSpent);

    // Count new clients based on status
    final newClients = customers.where((c) => c.status == 'New').length;

    // Calculate change from last month for Total Clients
    final changeFromLastMonth = total - totalClientsLastMonth;
    final changeText = changeFromLastMonth >= 0
        ? '+$changeFromLastMonth from last month'
        : '$changeFromLastMonth from last month';

    // Inactive clients: no lastVisit or lastVisit is older than 30 days
    final inactiveClients = customers.where((c) {
      if (c.lastVisit == null || c.lastVisit!.isEmpty) return true;
      try {
        final lastVisitDate = DateFormat('dd/MM/yyyy').parse(c.lastVisit!);
        return lastVisitDate.isBefore(thirtyDaysAgo);
      } catch (e) {
        return true;
      }
    }).length;

    final rows = _applySort(_filteredCustomers);

    // Ensure we have enough controllers for all rows
    while (_rowScrollControllers.length < rows.length) {
      final controller = ScrollController();
      controller.addListener(() {
        if (controller.hasClients) {
          _syncScroll(controller.offset, controller);
        }
      });
      _rowScrollControllers.add(controller);
    }

    // Remove extra controllers
    while (_rowScrollControllers.length > rows.length) {
      final controller = _rowScrollControllers.removeLast();
      controller.dispose();
    }

    // Add listener to header
    if (!_headerScrollController.hasListeners) {
      _headerScrollController.addListener(() {
        if (_headerScrollController.hasClients) {
          _syncScroll(_headerScrollController.offset, _headerScrollController);
        }
      });
    }
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(fontSizeFactor: 0.85),
      ),
      child: Scaffold(
        drawer: const CustomDrawer(currentPage: 'Clients'),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 50.h,
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              SizedBox(
                width: 20,
              ),
              Expanded(
                child: Text(
                  'Customers List',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationPage()),
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.w,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/images/profile.jpeg'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards - Row 1: Total Clients and New Clients
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'Total Clients',
                        value: '$total',
                        subtitle: changeText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'New Clients',
                        value: '$newClients',
                        subtitle: 'New clients with status New',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Statistics Cards - Row 2: Total Bookings and Inactive Clients
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'Total Spent',
                        value: '₹${totalSpent.toStringAsFixed(2)}',
                        subtitle: 'Total amount spent',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'Inactive Clients',
                        value: '$inactiveClients',
                        subtitle: 'No recent activities',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search by name, email, or phone...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  style: GoogleFonts.poppins(fontSize: 12),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ImportCustomers())),
                      icon: Icon(Icons.upload_file_outlined,
                          size: 14, color: Theme.of(context).primaryColor),
                      label: Text('Import',
                          style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                              fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black, width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _navigateAndAddCustomer(context),
                      icon: Icon(Icons.add,
                          size: 14, color: Theme.of(context).primaryColor),
                      label: Text('Add Customer',
                          style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                              fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black, width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loadCustomers,
                      icon: Icon(Icons.refresh,
                          size: 14, color: Theme.of(context).primaryColor),
                      label: Text('Refresh',
                          style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                              fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black, width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // TabBar for Offline/Online clients
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black,
                    labelStyle: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                    tabs: const [
                      Tab(text: 'Offline Clients'),
                      Tab(text: 'Online Clients'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Header row with synchronized scrolling
                SingleChildScrollView(
                  controller: _headerScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFEAEAEA), width: 1)),
                    ),
                    child: Row(
                      children: [
                        // Name
                        SizedBox(
                          width: 200,
                          child: InkWell(
                            onTap: () => _sortBy(0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Name',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 0)
                                  Icon(
                                      _sortAsc
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Contact
                        SizedBox(
                          width: 140,
                          child: InkWell(
                            onTap: () => _sortBy(1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Contact',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 1)
                                  Icon(
                                      _sortAsc
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Last Visit
                        SizedBox(
                          width: 120,
                          child: InkWell(
                            onTap: () => _sortBy(2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Last Visit',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 2)
                                  Icon(
                                      _sortAsc
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Total Booking
                        SizedBox(
                          width: 130,
                          child: InkWell(
                            onTap: () => _sortBy(3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Total Booking',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 3)
                                  Icon(
                                      _sortAsc
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Total Spent
                        SizedBox(
                          width: 110,
                          child: InkWell(
                            onTap: () => _sortBy(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Total Spent',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 4)
                                  Icon(
                                      _sortAsc
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status
                        SizedBox(
                          width: 100,
                          child: InkWell(
                            onTap: () => _sortBy(5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Status',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 5)
                                  Icon(
                                      _sortAsc
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Actions
                        SizedBox(
                          width: 160, // Increased from 130 to fix overflow
                          child: Text('Actions',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 80, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading customers',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCustomers,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                // Table rows with synchronized scrolling
                else
                  SizedBox(
                    height: 400,
                    child: rows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No Customers Yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Click 'Add Customer' to create one.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Color(0xFFEFEFEF)),
                            itemBuilder: (context, idx) {
                              final c = rows[idx];
                              final actualIndex = customers.indexOf(c);
                              return SingleChildScrollView(
                                controller: _rowScrollControllers[idx],
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  child: Row(
                                    children: [
                                      // Name + email
                                      SizedBox(
                                        width: 200,
                                        child: Row(
                                          children: [
                                            c.imagePath != null &&
                                                    c.imagePath!.isNotEmpty
                                                ? CircleAvatar(
                                                    radius: 16,
                                                    backgroundImage: c
                                                            .imagePath!
                                                            .startsWith('http')
                                                        ? NetworkImage(
                                                                c.imagePath!)
                                                            as ImageProvider
                                                        : FileImage(
                                                            File(c.imagePath!)),
                                                  )
                                                : CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(0.1),
                                                    child: Text(
                                                      c.fullName.isNotEmpty
                                                          ? c.fullName[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .blue[900]),
                                                    ),
                                                  ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                c.fullName,
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Contact - Email and Phone
                                      SizedBox(
                                        width: 140,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (c.email != null &&
                                                c.email!.isNotEmpty) ...[
                                              Text(
                                                c.email!,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                            ],
                                            Text(
                                              c.mobile,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Last Visit
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          c.lastVisit ?? 'Never',
                                          style:
                                              GoogleFonts.poppins(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Total Booking
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          c.totalBookings.toString(),
                                          style:
                                              GoogleFonts.poppins(fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Total Spent
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          '₹${c.totalSpent.toStringAsFixed(2)}',
                                          style:
                                              GoogleFonts.poppins(fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Status
                                      SizedBox(
                                        width: 100,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: c.status == 'Active'
                                                ? Colors.green[50]
                                                : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            c.status,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: c.status == 'Active'
                                                  ? Colors.green[800]
                                                  : Colors.grey[800],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Actions
                                      SizedBox(
                                        width:
                                            160, // Increased from 130 to fix overflow
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                  minWidth: 40, minHeight: 40),
                                              onPressed: () =>
                                                  _showCustomerDetails(
                                                      context, c),
                                              tooltip: 'View Details',
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                  minWidth: 40, minHeight: 40),
                                              onPressed: () =>
                                                  _editCustomer(actualIndex),
                                              tooltip: 'Edit',
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.red),
                                              padding: const EdgeInsets.all(8),
                                              constraints: const BoxConstraints(
                                                  minWidth: 40, minHeight: 40),
                                              onPressed: () =>
                                                  _deleteCustomer(actualIndex),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
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
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InfoCard(
      {required this.title,
      required this.value,
      required this.subtitle,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontSize: 10.sp)),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16.sp, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontSize: 10.sp)),
          ],
        ),
      ),
    );
  }
}
