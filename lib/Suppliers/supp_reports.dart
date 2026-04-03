import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'supp_drawer.dart';

class SuppReportsPage extends StatelessWidget {
  const SuppReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Reports'),
      appBar: AppBar(
        title: Text('Reports', 
          style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(child: Text('Reports Coming Soon')),
    );
  }
}
