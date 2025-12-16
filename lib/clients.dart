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

class Client extends StatefulWidget {
  const Client({super.key});

  @override
  State<Client> createState() => _ClientState();
}

class _ClientState extends State<Client> with SingleTickerProviderStateMixin {
  // The list now holds Customer objects, providing type safety.
  final List<Customer> customers = [];
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    
    // Add sample data
    _addSampleData();
  }

  void _addSampleData() {
    final now = DateTime.now();
    customers.addAll([
      Customer(
        id: '1',
        fullName: 'John Smith',
        mobile: '+1 234-567-8901',
        email: 'john.smith@email.com',
        dateOfBirth: '15/03/1985',
        gender: 'Male',
        country: 'United States',
        occupation: 'Software Engineer',
        address: '123 Main St, New York, NY 10001',
        note: 'Prefers morning appointments',
        lastVisit: DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 5))),
        totalBookings: 12,
        totalSpent: 1250.50,
        status: 'Active',
        createdAt: DateTime(2024, 8, 15),
        isOnline: true,
      ),
      Customer(
        id: '2',
        fullName: 'Sarah Johnson',
        mobile: '+1 234-567-8902',
        email: 'sarah.j@email.com',
        dateOfBirth: '22/07/1990',
        gender: 'Female',
        country: 'Canada',
        occupation: 'Marketing Manager',
        address: '456 Oak Ave, Toronto, ON M5H 2N2',
        note: 'Allergic to certain products',
        lastVisit: DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 15))),
        totalBookings: 8,
        totalSpent: 890.00,
        status: 'Active',
        createdAt: DateTime(2024, 9, 10),
        isOnline: false,
      ),
      Customer(
        id: '3',
        fullName: 'Michael Brown',
        mobile: '+1 234-567-8903',
        email: 'mbrown@email.com',
        dateOfBirth: '10/11/1988',
        gender: 'Male',
        country: 'United States',
        occupation: 'Doctor',
        address: '789 Pine Rd, Los Angeles, CA 90001',
        lastVisit: DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 45))),
        totalBookings: 5,
        totalSpent: 625.75,
        status: 'Active',
        createdAt: DateTime(2024, 10, 1),
        isOnline: true,
      ),
      Customer(
        id: '4',
        fullName: 'Emily Davis',
        mobile: '+1 234-567-8904',
        email: 'emily.davis@email.com',
        dateOfBirth: '05/01/1995',
        gender: 'Female',
        country: 'United Kingdom',
        occupation: 'Teacher',
        address: '321 Elm St, London, SW1A 1AA',
        note: 'VIP customer',
        lastVisit: DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 2))),
        totalBookings: 20,
        totalSpent: 2150.00,
        status: 'Active',
        createdAt: DateTime(2024, 7, 20),
        isOnline: false,
      ),
      Customer(
        id: '5',
        fullName: 'David Wilson',
        mobile: '+1 234-567-8905',
        dateOfBirth: '18/09/1982',
        gender: 'Male',
        country: 'Australia',
        occupation: 'Business Owner',
        address: '555 Beach Rd, Sydney, NSW 2000',
        totalBookings: 3,
        totalSpent: 345.00,
        status: 'Active',
        createdAt: DateTime(2024, 10, 25),
        isOnline: true,
      ),
      Customer(
        id: '6',
        fullName: 'Lisa Anderson',
        mobile: '+1 234-567-8906',
        email: 'lisa.anderson@email.com',
        dateOfBirth: '30/04/1992',
        gender: 'Female',
        country: 'United States',
        occupation: 'Nurse',
        address: '987 Maple Dr, Chicago, IL 60601',
        note: 'Referred by Emily Davis',
        totalBookings: 0,
        totalSpent: 0.00,
        status: 'Active',
        createdAt: now,
        isOnline: false,
      ),
    ]);
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
    if (_headerScrollController.hasClients && source != _headerScrollController) {
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
      setState(() {
        customers.add(newCustomer);
      });
      // Optional: Show a success message on this page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newCustomer.fullName} has been added.'),
          backgroundColor: Colors.green,
        ),
      );
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
      setState(() {
        customers[index] = editedCustomer;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${editedCustomer.fullName} has been updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteCustomer(int index) {
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(dialogBackgroundColor: Colors.white),
        child: AlertDialog(
          title: Text('Delete customer', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to delete ${customers[index].fullName}?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12))),
            TextButton(
              onPressed: () {
                setState(() => customers.removeAt(index));
                Navigator.pop(ctx);
              },
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
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
    
    final totalClientsLastMonth = customers.where((c) => c.createdAt.isBefore(lastMonth)).length;
    final newClientsThisMonth = customers.where((c) => c.createdAt.isAfter(thisMonth)).length;
    final totalBookings = customers.fold<int>(0, (sum, c) => sum + c.totalBookings);
    
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
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(fontSizeFactor: 0.85),
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
            children: [SizedBox(width: 20,),
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
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
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
                        value: '$newClientsThisMonth',
                        subtitle: 'New clients this month',
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
                        title: 'Total Bookings',
                        value: '$totalBookings',
                        subtitle: 'All client bookings',
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
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  style: GoogleFonts.poppins(fontSize: 12),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportCustomers())),
                      icon: const Icon(Icons.upload_file_outlined, size: 18, color: Colors.blue),
                      label: Text('Import', style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _navigateAndAddCustomer(context),
                      icon: const Icon(Icons.add, size: 18, color: Colors.blue),
                      label: Text('Add Customer', style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 36),
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
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black,
                    labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1)),
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
                                Text('Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 0)
                                  Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.black54),
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
                                Text('Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 1)
                                  Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.black54),
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
                                Text('Last Visit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 2)
                                  Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.black54),
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
                                Text('Total Booking', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 3)
                                  Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.black54),
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
                                Text('Total Spent', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 4)
                                  Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.black54),
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
                                Text('Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(width: 4),
                                if (_sortColumn == 5)
                                  Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Actions
                        SizedBox(
                          width: 100,
                          child: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Table rows with synchronized scrolling
                SizedBox(
                  height: 400,
                  child: rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Customers Yet',
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Click 'Add Customer' to create one.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFEFEF)),
                          itemBuilder: (context, idx) {
                            final c = rows[idx];
                            final actualIndex = customers.indexOf(c);
                            return SingleChildScrollView(
                              controller: _rowScrollControllers[idx],
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  children: [
                                    // Name + email
                                    SizedBox(
                                      width: 200,
                                      child: Row(
                                        children: [
                                          c.imagePath != null && c.imagePath!.isNotEmpty
                                              ? CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage: FileImage(File(c.imagePath!)),
                                                )
                                              : CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Colors.blue[100],
                                                  child: Text(
                                                    c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?',
                                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.blue[900]),
                                                  ),
                                                ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              c.fullName,
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (c.email != null && c.email!.isNotEmpty) ...[
                                            Text(
                                              c.email!,
                                              style: GoogleFonts.poppins(fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                          Text(
                                            c.mobile,
                                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
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
                                        style: GoogleFonts.poppins(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Total Booking
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        c.totalBookings.toString(),
                                        style: GoogleFonts.poppins(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Total Spent
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        '₹${c.totalSpent.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Status
                                    SizedBox(
                                      width: 100,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: c.status == 'Active' ? Colors.green[50] : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          c.status,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: c.status == 'Active' ? Colors.green[800] : Colors.grey[800],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Actions
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                            onPressed: () => _editCustomer(actualIndex),
                                            tooltip: 'Edit',
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                            onPressed: () => _deleteCustomer(actualIndex),
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

  const _InfoCard({required this.title, required this.value, required this.subtitle, Key? key}) : super(key: key);

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
            Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10.sp)),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10.sp)),
          ],
        ),
      ),
    );
  }
}

class CustomerDetailPopup extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPopup({Key? key, required this.customer}) : super(key: key);

  @override
  _CustomerDetailPopupState createState() => _CustomerDetailPopupState();
}

class _CustomerDetailPopupState extends State<CustomerDetailPopup> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = [
    'Overview',
    'Client Details',
    'Appointments',
    'Orders',
    'Reviews',
    'Payment History',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 550,
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                Expanded(
                  child: Row(
                    children: [
                      _buildSideMenu(),
                      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                      _buildMainContent(),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 12.0,
              top: 12.0,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 50, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: const Icon(Icons.person_outline, size: 30, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Text(
            widget.customer.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return SizedBox(
      width: 140,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return Material(
            color: isSelected ? const Color(0xFF343A40) : Colors.white,
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // UPDATED: This method now switches between different content widgets
  Widget _buildMainContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return _buildClientDetailsContent();
      default:
        return Expanded(
          child: Center(
            child: Text(
              '${_tabs[_selectedTabIndex]} Page',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        );
    }
  }

  Widget _buildOverviewContent() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        color: const Color(0xFFFAFAFA),
        child: Wrap(
          spacing: 20.0,
          runSpacing: 20.0,
          alignment: WrapAlignment.start,
          children: [
            _buildMetricCard('₹ ', 'Total Sale'),
            _buildMetricCard('0', 'Total Visits'),
            _buildMetricCard('0', 'Completed'),
            _buildMetricCard('0', 'Cancelled'),
           ],
        ),
      ),
    );
  }

  // NEW: Widget for the Client Details view
  Widget _buildClientDetailsContent() {
    final c = widget.customer;

    return Expanded(
      child: Container(
        color: const Color(0xFFFAFAFA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Basic info'),
              _buildDetailRow('Full Name', c.fullName),
              _buildDetailRow('Email ID', c.email ?? ''),
              _buildDetailRow('Phone Number', c.mobile),
              _buildDetailRow('Date of Birth', c.dateOfBirth ?? ''),
              _buildDetailRow('Gender', c.gender ?? ''),
              const SizedBox(height: 32),
              _buildSectionHeader('Additional info'),
              _buildDetailRow('Country', c.country ?? ''),
              _buildDetailRow('Occupation', c.occupation ?? ''),
              _buildDetailRow('Address', c.address ?? ''),
              _buildDetailRow('Note', c.note ?? ''),
              _buildDetailRow('Status', c.status),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Helper widget for section headers
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const Divider(height: 16, thickness: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  // NEW: Helper widget for a label-value pair
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ 
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value, // Use a dash for empty values
            style: const TextStyle(fontSize: 16,
                height: 1.4,
                color: Colors.black87,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return Container(
      width: 190,
      height: 90,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

