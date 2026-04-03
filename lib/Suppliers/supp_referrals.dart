import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'supp_drawer.dart';

class SuppReferralsPage extends StatelessWidget {
  const SuppReferralsPage({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Referrals'),
      appBar: AppBar(
        title: Text('Referrals', 
          style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(child: Text('Referrals Coming Soon')),
    );
  }
}
