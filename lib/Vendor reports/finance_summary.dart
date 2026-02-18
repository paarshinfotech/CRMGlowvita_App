import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../Notification.dart';
import '../Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class FinanceSummary extends StatefulWidget {
  @override
  State<FinanceSummary> createState() => _FinanceSummaryState();
}

class _FinanceSummaryState extends State<FinanceSummary> {
  DateTimeRange? _selectedDateRange;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterData();
      });
    }
  }

  final List<Map<String, dynamic>> financeSummary = [
    {
      'grossSales': 7000.00,
      'discountsAndOffers': 920.00,
      'netSales': 6080.00,
      'tax': 0.00,
      'totalSales': 6080.00,
      'cash': 3000.00,
      'qr': 2000.00,
      'link': 1080.00,
      'totalPayments': 6080.00,
    },
    {
      'grossSales': 7000.00,
      'discountsAndOffers': 920.00,
      'netSales': 6080.00,
      'tax': 0.00,
      'totalSales': 6080.00,
      'cash': 3000.00,
      'qr': 2000.00,
      'link': 1080.00,
      'totalPayments': 6080.00,
    }
  ];

  List<Map<String, dynamic>> filteredServices = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    filteredServices = List.from(financeSummary);
  }

  void _filterData() {
    setState(() {
      filteredServices = financeSummary.where((service) {
        final matchesSearch = service['staffName']
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase());

        return matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals from the list
    double grossSalesTotal = 0;
    double discountsAndOffersTotal = 0;
    double netSalesTotal = 0;
    double taxTotal = 0;
    double totalSalesTotal = 0;
    double cashTotal = 0;
    double qrTotal = 0;
    double linkTotal = 0;
    double totalPaymentsTotal = 0;

    for (var data in financeSummary) {
      grossSalesTotal += data['grossSales'];
      discountsAndOffersTotal += data['discountsAndOffers'];
      netSalesTotal += data['netSales'];
      taxTotal += data['tax'];
      totalSalesTotal += data['totalSales'];
      cashTotal += data['cash'];
      qrTotal += data['qr'];
      linkTotal += data['link'];
      totalPaymentsTotal += data['totalPayments'];
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 50.h,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Finance Summary',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()));
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
              child: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.w),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                   onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 20),
                  label: Text(
                    _selectedDateRange != null
                        ? "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}"
                        : "Pick Range",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black54),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sales Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    const Divider(),
                    _infoRow('Gross Sales', '₹ ${grossSalesTotal.toStringAsFixed(2)}'),
                    _infoRow('Discounts + Offers', '₹ ${discountsAndOffersTotal.toStringAsFixed(2)}'),
                    _infoRow('Net Sales', '₹ ${netSalesTotal.toStringAsFixed(2)}'),
                    _infoRow('Taxes', '₹ ${taxTotal.toStringAsFixed(2)}'),
                   Divider(),
                    _infoRow('Total Sales', '₹ ${totalSalesTotal.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
            ),

            // Payments Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8, color: Colors.white,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payments', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    const Divider(),
                    _infoRow('Cash', '₹ ${cashTotal.toStringAsFixed(2)}'),
                    _infoRow('QR', '₹ ${qrTotal.toStringAsFixed(2)}'),
                    _infoRow('Link', '₹ ${linkTotal.toStringAsFixed(2)}'),
                    Divider(),
                    _infoRow('Total Payments', '₹ ${totalPaymentsTotal.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _infoRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
