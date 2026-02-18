import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'Vendor reports/sales_by_service.dart';
import 'Vendor reports/sales_by_customer.dart';
import 'Vendor reports/sales_history.dart';
import 'Vendor reports/sales_commission.dart';
import 'Vendor reports/staff_commission_summary.dart';
import 'Vendor reports/staff_performance.dart';
import 'Vendor reports/finance_summary.dart';
import 'Vendor reports/payment_summary.dart';
import 'Vendor reports/taxes_summary.dart';
import 'Vendor reports/discount_summary.dart';
import 'Vendor reports/outstanding_sales_sumary.dart';
import 'Vendor reports/expenses_summary.dart';
import 'Vendor reports/profit_and_loss_summary.dart';
import 'Vendor reports/referralinvites_summary.dart';
import 'Vendor reports/referralcommission_summary.dart';
import 'Vendor reports/settlement_summary.dart';
import 'Vendor reports/payout_summary.dart';
import 'Vendor reports/allAppointments_summary.dart';
import 'Vendor reports/appointmentsbystaff_summary.dart';
import 'Vendor reports/appointmentsbyservice_summary.dart';
import 'Vendor reports/appointmentsCancellation_summary.dart';

const Color _primaryDark = Color(0xFF372935);

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Reports'),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Reports',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Generate and download detailed reports for various components of the platform.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    SizedBox(width: 32.w),
                    SizedBox(
                      width: 240.w,
                      child: _buildSearchBar(),
                    ),
                  ],
                ],
              );
            }),
            if (MediaQuery.of(context).size.width <= 800) ...[
              SizedBox(height: 12.h),
              _buildSearchBar(),
            ],
            SizedBox(height: 32.h),

            // Appointment Summary Section
            _buildSectionHeader('Appointment Summary'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'All Appointments Report',
                description:
                    'Complete record of all appointments with detailed information.',
                details: [
                  'Client Name, Service Type, Staff Member',
                  'Date & Time, Duration, Amount',
                  'Status, Payment Status',
                  'Booking Type, Notes',
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AllAppointmentsSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Appointment Summary by Service',
                description:
                    'Aggregated view showing appointment counts, revenue, and popularity by service type.',
                details: [
                  'Service Name, Total Appointments',
                  'Revenue Generated, Average Duration',
                  'Distribution %, Completion Rate',
                  'Staff Performance Metrics',
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AppointmentsbyServicesSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Completed Appointments Report',
                description:
                    'Detailed listing of all successfully completed appointments.',
                details: [
                  'Client Name, Service, Staff Member',
                  'Completion Date & Time, Duration',
                  'Amount Charged, Payment Method',
                  'Rating/Review, Booking Type',
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AllAppointmentsSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Cancelled Appointments Report',
                description:
                    'Comprehensive analysis of cancelled appointments with reasons and impact.',
                details: [
                  'Client Name, Service, Staff Member',
                  'Cancellation Date & Time, Reason',
                  'Refund Status, Revenue Impact',
                  'Status, Booking Type',
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AppointmentsCancellationSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'All Appointments by Staff',
                description:
                    'Detailed report showing appointment statistics aggregated by staff member.',
                details: [
                  'Staff Name, Total Appointments',
                  'Total Duration, Average Duration',
                  'Total Sales, Average Sale',
                  'Performance Metrics',
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AppointmentsbyStaffSummary())),
                onDownload: () {},
              ),
            ]),

            SizedBox(height: 32.h),

            // Finance & Sales Section
            _buildSectionHeader('Finance & Sales'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'Sales by Service',
                description:
                    'Detailed revenue breakdown generated by each service offering.',
                details: [
                  'Service Category',
                  'Gross Revenue',
                  'Net Sales',
                  'Volume'
                ],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SalesByService())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Sales by Customer',
                description:
                    'Revenue breakdown by customer to identify high-value clients.',
                details: [
                  'Customer Name',
                  'Total Spend',
                  'Visit Frequency',
                  'Last Visit'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SalesByCustomers())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Sales History',
                description:
                    'Historical record of all sales transactions over time.',
                details: ['Date', 'Invoice ID', 'Client Name', 'Payment Mode'],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SalesHistory())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Sales Commission',
                description:
                    'Tracking commissions earned from sales transactions.',
                details: [
                  'Sales ID',
                  'Commission Earned',
                  'Staff Name',
                  'Status'
                ],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SalesCommission())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Finance Summary',
                description:
                    'High-level overview of business financial health.',
                details: ['Total Revenue', 'Expenses', 'Net Profit', 'Growth'],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => FinanceSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Payments Summary',
                description:
                    'Summary of payments received across different channels.',
                details: [
                  'Payment Mode',
                  'Total Collected',
                  'Processing Fees',
                  'Net Amount'
                ],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PaymentSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Taxes Summary',
                description:
                    'Comprehensive report on taxes collected and liabilities.',
                details: [
                  'CGST/SGST Breakdown',
                  'Taxable Amount',
                  'Tax Percentage',
                  'Period'
                ],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TaxesSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Discount Summary',
                description:
                    'Analysis of discounts given and their impact on revenue.',
                details: [
                  'Discount Code',
                  'Usage Count',
                  'Total Discount Amount',
                  'Campaign'
                ],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => DiscountSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Outstanding Sales',
                description: 'Tracking unpaid invoices and overdue payments.',
                details: ['Invoice ID', 'Due Amount', 'Customer Name', 'Aging'],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OutstandingSaleSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Expenses Summary',
                description:
                    'Detailed record of business expenditures and overheads.',
                details: ['Expense Category', 'Amount', 'Date', 'Vendor'],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ExpensesSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Profit Margin',
                description:
                    'Calculating the profitability of services and overall business.',
                details: [
                  'Net Margin %',
                  'Service Cost',
                  'Operating Cost',
                  'Revenue'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfitAndLossSummary())),
                onDownload: () {},
              ),
            ]),

            SizedBox(height: 32.h),

            // Staff Performance Section
            _buildSectionHeader('Staff Performance'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'Staff Commission Summary',
                description: 'Overview of commissions earned by staff members.',
                details: [
                  'Staff Name',
                  'Total Sales',
                  'Commission Rate',
                  'Earned Amount'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StaffCommissionSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Staff Performance',
                description:
                    'Detailed metrics tracking individual staff efficiency and customer ratings.',
                details: [
                  'Appointment Count',
                  'Revenue Contribution',
                  'Customer Rating',
                  'Utilization %'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StaffPerformance())),
                onDownload: () {},
              ),
            ]),

            SizedBox(height: 32.h),

            // Referral & Payouts Section
            _buildSectionHeader('Referral & Payouts'),
            SizedBox(height: 16.h),
            _buildTwoColumnGrid(context, [
              _ReportCard(
                title: 'Referral Invites Summary',
                description:
                    'Tracking status of referral invitations sent by users.',
                details: [
                  'Inviter Name',
                  'Invitee Status',
                  'Sign-up Date',
                  'Reward Status'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReferralInvitesSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Referral Commission',
                description:
                    'Summary of commissions earned through the referral program.',
                details: [
                  'Commission Earned',
                  'Payout Status',
                  'Reference ID',
                  'Date'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReferralCommissionSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Settlement Summary',
                description:
                    'Overview of fund settlements between vendors and the platform.',
                details: [
                  'Settlement ID',
                  'Vendor Name',
                  'Transfer Amount',
                  'Status'
                ],
                onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SettlementSummary())),
                onDownload: () {},
              ),
              _ReportCard(
                title: 'Payout Summary',
                description:
                    'Detailed listing of all completed payouts to staff and vendors.',
                details: [
                  'Payout Date',
                  'Recipient',
                  'Method',
                  'Transaction Ref'
                ],
                onView: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PayoutSummary())),
                onDownload: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: _border),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          Icon(Icons.search, color: _muted, size: 15),
          SizedBox(width: 6.w),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search reports...',
                hintStyle: GoogleFonts.poppins(fontSize: 11.sp, color: _muted),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.poppins(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  /// 1 card per row — list layout
  Widget _buildTwoColumnGrid(BuildContext context, List<Widget> children) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, __) => SizedBox(height: 7.h),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> details;
  final VoidCallback onView;
  final VoidCallback onDownload;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.details,
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5.sp,
                    color: const Color(0xFF94A3B8),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 7.h),
                ...details.map(
                  (d) => Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 3.5.h, right: 5.w),
                          child: Container(
                            width: 3.w,
                            height: 3.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            d,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Right: buttons stacked
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                onPressed: onView,
                isPrimary: false,
              ),
              SizedBox(height: 5.h),
              _cardButton(
                icon: Icons.file_download_outlined,
                label: 'Download',
                onPressed: onDownload,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final bgColor = isPrimary ? _primaryDark : Colors.white;
    final fgColor = isPrimary ? Colors.white : const Color(0xFF1E293B);
    final borderColor =
        isPrimary ? Colors.transparent : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: 76.w,
        padding: EdgeInsets.symmetric(vertical: 5.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 9.sp, color: fgColor),
            SizedBox(width: 3.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
