import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfitAndLossSummary extends StatefulWidget {
  @override
  State<ProfitAndLossSummary> createState() => _ProfitAndLossSummaryState();
}

class _ProfitAndLossSummaryState extends State<ProfitAndLossSummary> {
  DateTimeRange? _selectedDateRange;

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
      'grossSales': 8500.00,
      'discountsAndOffers': 1000.00,
      'netSales': 7500.00,
      'tax': 300.00,
      'totalSales': 7800.00,
      'cash': 2000.00,
      'qr': 3000.00,
      'link': 2800.00,
      'totalPayments': 7800.00,
    }
  ];

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
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  String _currency(num v) => '₹${NumberFormat('#,##0.00').format(v)}';

  void _showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('OK', style: GoogleFonts.poppins()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalRevenue = financeSummary.fold<double>(0, (sum, e) => sum + e['totalSales']);
    final cogs = 0.0;
    final totalExpenses = 0.0;
    final totalOpex = cogs + totalExpenses;
    final profit = totalRevenue - totalOpex;
    final profitPct = totalRevenue > 0 ? (profit / totalRevenue * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title:
        Text('Profit & Loss', style: GoogleFonts.poppins(color: Colors.black, fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage())),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/profile.jpeg'),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20.r),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Controls
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectDateRange,
                    icon: Icon(Icons.date_range, color: Colors.black),
                    label: Text(
                      _selectedDateRange != null
                          ? "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}"
                          : "Pick Range",
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black26),
                      elevation: 0,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        icon: Icon(Icons.download, color: Colors.black),
                        items: ['CSV', 'PDF', 'Excel', 'Print']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        hint: Text('Export', style: GoogleFonts.poppins()),
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Profit & Loss card
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profit – Loss statement',
                          style:
                          GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4.h),
                      Text(
                        _selectedDateRange != null
                            ? "For ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} to ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}"
                            : "Select a date range",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16.h),

                      _pnlRow(
                        'Total Revenue',
                        _currency(totalRevenue),
                        pct: '100 %',
                      ),

                      _pnlRow(
                        'COGS',
                        _currency(cogs),
                        pct: '0 %',
                        infoTitle: 'COGS',
                        infoMessage:
                        'Cost Of Goods Sold\nFormula: COGS = % of Total Revenue',
                      ),

                      _pnlRow(
                        'Total Expenses',
                        _currency(totalExpenses),
                        pct: '0 %',
                        infoTitle: 'Total Expenses',
                        infoMessage:
                        'Sum of all operating expenses\nFormula: Total Expenses = % of Total Revenue',
                      ),

                      _pnlRow(
                        'Total Opex',
                        _currency(totalOpex),
                        pct: '0 %',
                        infoTitle: 'Operating Expenses',
                        infoMessage: 'Formula: COGS + Total Expenses',
                      ),

                      SizedBox(height: 12.h),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        padding: EdgeInsets.all(12.r),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('Profit Margin (EBITA)',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700])),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: () => _showInfo('Profit Margin (EBITA)',
                                      'Earnings Before Interest, Taxes & Amortization\nProfit Margin (EBITA) = Total Revenue - Total Opex'),
                                  child:
                                  Icon(Icons.info_outline, size: 18, color: Colors.green[700]),
                                ),
                              ],
                            ),
                            // Centered amount & pct
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(_currency(profit),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700])),
                                Text('$profitPct %',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pnlRow(
      String label,
      String value, {
        required String pct,
        String? infoTitle,
        String? infoMessage,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 14)),
              if (infoTitle != null && infoMessage != null) ...[
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: () => _showInfo(infoTitle, infoMessage),
                  child: Icon(Icons.info_outline, size: 18, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
          // Center-aligned amount + pct
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 14)),
              Text(pct, style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
