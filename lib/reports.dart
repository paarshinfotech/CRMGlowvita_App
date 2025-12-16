import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Notification.dart';
import 'Profile.dart';
import 'widgets/custom_drawer.dart';
import 'sales_by_service.dart';
import 'sales_by_customer.dart';
import 'sales_history.dart';
import 'sales_commission.dart';
import 'staff_commission_summary.dart';
import 'staff_performance.dart';
import 'finance_summary.dart';
import 'payment_summary.dart';
import 'taxes_summary.dart';
import 'discount_summary.dart';
import 'outstanding_sales_sumary.dart';
import 'expenses_summary.dart';
import 'profit_and_loss_summary.dart';
import 'referralinvites_summary.dart';
import 'referralcommission_summary.dart';
import 'settlement_summary.dart';
import 'payout_summary.dart';
import 'allAppointments_summary.dart';
import 'appointmentsbystaff_summary.dart';
import 'appointmentsbyservice_summary.dart';
import 'appointmentsCancellation_summary.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        drawer: const CustomDrawer(currentPage: 'Reports'),
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 50.h,
          titleSpacing: 0,
          automaticallyImplyLeading: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
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
          title: Row(
            children: [
              // Back button removed since drawer provides navigation
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reports and Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Text(
                'Access all your GlowVita performance and business reports in one place.',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
            TabBar(
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              labelStyle: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Sales'),
                Tab(text: 'Staff'),
                Tab(text: 'Finance'),
                Tab(text: 'Referral'),
                Tab(text: 'Payout'),
                Tab(text: 'Appointments'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabContent(context, [
                    _CardData(
                      'Sales by Service',
                      Icons.design_services,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SalesByService()),
                        );
                      },
                    ),
                    _CardData('Sales by Customer', Icons.people,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SalesByCustomers()),
                        );
                      },
                    ),
                    _CardData('Sales History', Icons.history,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SalesHistory()),
                      );
                    }
                    ),
                    _CardData('Sales Commission', Icons.attach_money,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SalesCommission()),
                          );
                        }
                    ),
                  ]),
                  _buildTabContent(context, [
                    _CardData('Staff Commission Summary', Icons.bar_chart,

                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StaffCommissionSummary()),
                      );
                    }),
                    _CardData('Staff Performance', Icons.person_pin,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder:(context) => StaffPerformance()),
                      );
                    }
                    ),
                  ]),
                  _buildTabContent(context, [
                    _CardData('Finance Summary', Icons.pie_chart,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FinanceSummary()),
                      );
                    }
                    ),
                    _CardData('Payments Summary', Icons.payment,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context)=> PaymentSummary()),
                      );
                    }
                    ),
                    _CardData('Taxes Summary', Icons.receipt_long,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TaxesSummary()),
                      );
                    }
                    ),
                    _CardData('Discount Summary', Icons.discount,
                    onTap:(){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context)=> DiscountSummary()),
                      );
                    }
                    ),
                    _CardData('Outstanding Sales', Icons.pending_actions,
                        onTap:() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                OutstandingSaleSummary()),
                          );
                        }
                    ),
                    _CardData('Expenses Summary', Icons.money_off,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExpensesSummary()),
                      );
                    }
                    ),
                    _CardData('Profit Margin', Icons.show_chart,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfitAndLossSummary()),
                      );
                    }
                    ),
                  ]),
                  _buildTabContent(context, [
                    _CardData('Referral Invites Summary', Icons.group_add,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReferralInvitesSummary()),
                      );
                    }
                    ),
                    _CardData(
                      'Referral Commission Summary',
                      Icons.card_giftcard,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReferralCommissionSummary()),
                        );
                      },
                    ),
                  ]),
                  _buildTabContent(context, [
                    _CardData('Settlement Summary', Icons.account_balance_wallet,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettlementSummary()),
                      );
                    }
                    ),
                    _CardData('Payout Summary', Icons.payments,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PayoutSummary()),
                      );
                    }
                    ),
                  ]),
                  _buildTabContent(context, [
                    _CardData('All Appointments', Icons.event_available,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllAppointmentsSummary())
                      );
                    }
                    ),
                    _CardData('Appointments Summary by Staff', Icons.people_outline,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppointmentsbyStaffSummary()),
                      );
                    }
                    ),
                    _CardData('Appointment Summary by Services', Icons.design_services,
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AppointmentsbyServicesSummary()),
                          );
                        }
                    ),
                    _CardData('Appointment Cancellation', Icons.cancel_schedule_send,
                    onTap:(){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppointmentsCancellationSummary()),
                      );
                    }
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<_CardData> cards) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: cards.map((card) {
          return _buildSalesCard(context, card.title, card.icon, onTap: card.onTap);
        }).toList(),
      ),
    );
  }

  Widget _buildSalesCard(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150.w,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28.sp, color: Colors.black87),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _CardData {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  _CardData(this.title, this.icon, {this.onTap});
}

