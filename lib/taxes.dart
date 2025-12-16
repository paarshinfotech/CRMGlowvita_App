import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Taxes extends StatefulWidget {
  const Taxes({super.key});

  @override
  State<Taxes> createState() => _TaxesState();
}

class _TaxesState extends State<Taxes> {
  List<Map<String, dynamic>> taxes = [];

  void _openAddEditDialog({Map<String, dynamic>? tax, int? index}) {
    final nameController = TextEditingController(text: tax?['name'] ?? '');
    final rateController =
    TextEditingController(text: tax != null ? tax['rate'].toString() : '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          title: Text(
            tax == null ? 'Add Tax' : 'Edit Tax',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set the tax name and percentage rate. To apply this to your products and services, adjust your tax defaults settings.',
                  style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade600),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Tax Name'),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Tax Rate (%)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                rateController.dispose();
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final rate = double.tryParse(rateController.text.trim());

                if (name.isEmpty || rate == null || rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Enter a valid name and rate'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                setState(() {
                  if (tax == null) {
                    taxes.add({'name': name, 'rate': rate});
                  } else {
                    taxes[index!] = {'name': name, 'rate': rate};
                  }
                });

                nameController.dispose();
                rateController.dispose();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openTaxesPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tax Rates',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: const Color(0xFF6B7280), size: 24.sp),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (taxes.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Text(
                    'No taxes added yet.',
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: const Color(0xFF6B7280)),
                  ),
                ),
              ...taxes.asMap().entries.map((entry) {
                final index = entry.key;
                final tax = entry.value;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  color: const Color(0xFFF7F9FD),
                  child: ListTile(
                    title: Text(
                      tax['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    subtitle: Text(
                      '${tax['rate']}%',
                      style: GoogleFonts.poppins(fontSize: 14.sp, color: const Color(0xFF6B7280)),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.settings, color: const Color(0xFF457BFF), size: 20.sp),
                      onSelected: (value) {
                        if (value == 'Edit') {
                          Navigator.pop(context); // close main dialog before edit
                          _openAddEditDialog(tax: tax, index: index);
                        } else if (value == 'Delete') {
                          setState(() {
                            taxes.removeAt(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tax deleted successfully!',
                                  style: GoogleFonts.poppins(fontSize: 14.sp),
                                ),
                                backgroundColor: const Color(0xFF457BFF),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          });
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'Edit',
                          child: Text('Edit', style: GoogleFonts.poppins(fontSize: 14.sp)),
                        ),
                        PopupMenuItem(
                          value: 'Delete',
                          child: Text('Delete', style: GoogleFonts.poppins(fontSize: 14.sp)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF457BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close main dialog
                    _openAddEditDialog(); // open add dialog
                  },
                  child: Text(
                    'Add New',
                    style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        title: Text(
          'Tax Settings',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF1F6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _openTaxesPopup,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF457BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            elevation: 2,
          ),
          child: Text(
            'Manage Taxes',
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
