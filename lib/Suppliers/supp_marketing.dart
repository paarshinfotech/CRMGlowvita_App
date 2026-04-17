import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'supp_drawer.dart';
import '../widgets/subscription_wrapper.dart';

class SuppMarketingPage extends StatelessWidget {
  const SuppMarketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Marketing'),
      appBar: AppBar(
        title: Text('Marketing', 
          style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SubscriptionWrapper(
        child: const Center(child: Text('Marketing Coming Soon')),
      ),
    );
  }
}
