import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SuppProfilePage extends StatefulWidget {
  const SuppProfilePage({super.key});

  @override
  _SuppProfilePageState createState() => _SuppProfilePageState();
}

class _SuppProfilePageState extends State<SuppProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Supplier Personal Area',
          style: GoogleFonts.poppins(fontSize: 10.sp),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Sticky Profile Header Card (visible across all tabs)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Photo
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5.w),
                  ),
                  child: CircleAvatar(
                    radius: 36.r,
                    backgroundImage:
                        const AssetImage('assets/images/profile.jpeg'),
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                SizedBox(width: 16.w),
                // Supplier Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shivani Deshmukh',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 10.sp, color: Colors.grey[600]),
                          SizedBox(width: 4.w),
                          Text(
                            'Mumbai, Maharashtra, India',
                            style: GoogleFonts.poppins(
                                fontSize: 10.sp, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            'Supplier ID: ',
                            style: GoogleFonts.poppins(
                                fontSize: 10.sp, color: Colors.grey[600]),
                          ),
                          Text(
                            'SUP-20250048',
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // TabBar after profile info
          Container(
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Subscription'),
                Tab(text: 'Documents'),
                Tab(text: 'SMS Packages'),
              ],
              labelStyle: GoogleFonts.poppins(
                  fontSize: 10.sp, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10.sp),
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
            ),
          ),
          // Tab Content (scrollable)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildSubscriptionTab(),
                _buildDocumentsTab(),
                _buildSmsPackagesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Profile',
            style: GoogleFonts.poppins(
                fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          _buildTextField('First Name'),
          SizedBox(height: 8.h),
          _buildTextField('Last Name'),
          SizedBox(height: 8.h),
          _buildTextField('Shop Name'),
          SizedBox(height: 8.h),
          _buildTextField('Supplier Type'),
          SizedBox(height: 8.h),
          _buildTextField('Description', maxLines: 3),
          SizedBox(height: 8.h),
          _buildTextField('Email'),
          SizedBox(height: 8.h),
          _buildTextField('Mobile Number'),
          SizedBox(height: 8.h),
          _buildTextField('Country'),
          SizedBox(height: 8.h),
          _buildTextField('State'),
          SizedBox(height: 8.h),
          _buildTextField('City'),
          SizedBox(height: 8.h),
          _buildTextField('Pincode'),
          SizedBox(height: 8.h),
          _buildTextField('Address', maxLines: 2),
          SizedBox(height: 8.h),
          _buildTextField('Business Registration Number'),
          SizedBox(height: 8.h),
          _buildTextField('Referral Code'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              // Save profile logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Save Changes',
                style: GoogleFonts.poppins(fontSize: 12.sp)),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    // Current date: January 02, 2026
    const String planName = 'Premium Supplier Plan';
    const String status = 'Active';
    const String startDate = '2025-07-01';
    const String endDate = '2026-07-01';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Subscription',
            style: GoogleFonts.poppins(
                fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'Current plan details',
            style:
                GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Plan Name', planName),
                  SizedBox(height: 8.h),
                  _infoRow('Status', status, valueColor: Colors.green),
                  SizedBox(height: 8.h),
                  _infoRow('Start Date', startDate),
                  SizedBox(height: 8.h),
                  _infoRow('End Date', endDate),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Renew subscription logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text('Renew Plan',
                              style: GoogleFonts.poppins(fontSize: 12.sp)),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Subscription History',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold)),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: const [
                                      ListTile(
                                          title: Text(
                                              'Premium Plan - Jul 2024 to Jul 2025')),
                                      ListTile(
                                          title: Text(
                                              'Basic Plan - Jan 2024 to Jul 2024')),
                                      ListTile(
                                          title: Text(
                                              'Trial Plan - Dec 2023 to Jan 2024')),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close')),
                                ],
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text('View History',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).primaryColor)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[700])),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black)),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    final List<String> uploadedDocuments = [
      'GST_Certificate.pdf',
      'Shop_License.jpeg',
      'PAN_Card.pdf'
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Documents',
            style: GoogleFonts.poppins(
                fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'Manage documents',
            style:
                GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              // Implement file picker / upload
            },
            child: Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey[400]!,
                    style: BorderStyle.solid,
                    width: 2),
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 40.sp, color: Colors.grey[600]),
                  SizedBox(height: 6.h),
                  Text('Drop documents here or browse to upload',
                      style: GoogleFonts.poppins(
                          fontSize: 11.sp, color: Colors.grey[700])),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Uploaded Documents',
              style: GoogleFonts.poppins(
                  fontSize: 15.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          ...uploadedDocuments.map((doc) => Card(
                margin: EdgeInsets.only(bottom: 8.h),
                child: ListTile(
                  leading: Icon(Icons.description, color: Colors.grey[700]),
                  title: Text(doc, style: GoogleFonts.poppins(fontSize: 11.sp)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // Delete document logic
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSmsPackagesTab() {
    const int activeSmsCount = 842;

    final List<Map<String, dynamic>> purchaseHistory = [
      {
        'packageName': 'Starter Pack',
        'smsCount': 500,
        'price': 25.00,
        'purchaseDate': '2025-08-15',
        'expiryDate': '2026-08-15',
        'status': 'Active'
      },
      {
        'packageName': 'Basic Pack',
        'smsCount': 200,
        'price': 10.00,
        'purchaseDate': '2025-03-10',
        'expiryDate': '2025-09-10',
        'status': 'Expired'
      },
      {
        'packageName': 'Pro Pack',
        'smsCount': 1000,
        'price': 45.00,
        'purchaseDate': '2024-12-01',
        'expiryDate': '2025-12-01',
        'status': 'Expired'
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMS Packages',
            style: GoogleFonts.poppins(
                fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'Manage SMS credits',
            style:
                GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remaining SMS Credits',
                      style: GoogleFonts.poppins(fontSize: 12.sp)),
                  Text('$activeSmsCount',
                      style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor))
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Purchase History',
              style: GoogleFonts.poppins(
                  fontSize: 15.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40.h,
              dataRowHeight: 44.h,
              columnSpacing: 20.w,
              columns: [
                DataColumn(
                    label: Text('Package',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('SMS Count',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Price',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Purchase Date',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Expiry Date',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Status',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold))),
              ],
              rows: purchaseHistory.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item['packageName'],
                      style: GoogleFonts.poppins(fontSize: 11.sp))),
                  DataCell(Text(item['smsCount'].toString(),
                      style: GoogleFonts.poppins(fontSize: 11.sp))),
                  DataCell(Text('\$${item['price'].toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 11.sp))),
                  DataCell(Text(item['purchaseDate'],
                      style: GoogleFonts.poppins(fontSize: 11.sp))),
                  DataCell(Text(item['expiryDate'],
                      style: GoogleFonts.poppins(fontSize: 11.sp))),
                  DataCell(
                    Chip(
                      label: Text(item['status'],
                          style: GoogleFonts.poppins(
                              fontSize: 10.sp, color: Colors.white)),
                      backgroundColor: item['status'] == 'Active'
                          ? Colors.green
                          : Colors.red[700],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
