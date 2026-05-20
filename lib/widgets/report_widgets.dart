import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const Color reportPrimaryColor = Color(0xFF372935);
const Color reportSecondaryColor = Color(0xFF6C3EB8);
const Color reportBorderColor = Color(0xFFE2E8F0);
const Color reportMutedColor = Color(0xFF64748B);

/// Custom premium AppBar matching Figma UI "< Title"
class ReportAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;
  final List<Widget>? actions;

  const ReportAppBar({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 16,
            ),
            onPressed: onBackPressed,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(46.h);
}

/// Custom premium Search Bar and Actions (Filters, Export) matching Figma UI
class ReportSearchBarAndButtons extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final Widget? exportMenu; // Can pass a PopupMenuButton or standard inkwell

  const ReportSearchBarAndButtons({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onFilterTap,
    this.exportMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        Container(
          height: 38.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: reportBorderColor, width: 1.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: Colors.grey.shade400,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        // Buttons: Filters and Export
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onFilterTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 74, 57, 72),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  minimumSize: Size(double.infinity, 34.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                child: Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(child: exportMenu ?? Container()),
          ],
        ),
      ],
    );
  }
}

/// Standard premium Plum/Eggplant button widget for export or generic action
class ReportPlumButton extends StatelessWidget {
  final String label;
  final IconData? suffixIcon;
  final VoidCallback? onTap;

  const ReportPlumButton({
    super.key,
    required this.label,
    this.suffixIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 74, 57, 72),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (suffixIcon != null) ...[
                  SizedBox(width: 8.w),
                  Icon(suffixIcon, color: Colors.white, size: 14.sp),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom premium Stats Card matching Figma UI exactly
class ReportStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color circleBgColor;

  const ReportStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.circleBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: circleBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 15.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    color: reportMutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats Grid to lay cards out in 2 columns
class ReportStatsGrid extends StatelessWidget {
  final List<Widget> children;

  const ReportStatsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: children[i]),
              if (i + 1 < children.length) ...[
                SizedBox(width: 10.w),
                Expanded(child: children[i + 1]),
              ] else ...[
                SizedBox(width: 10.w),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
          if (i + 2 < children.length) SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

/// Custom premium Pagination matching Figma:
/// - Left: "Show 10 [dropdown]"
/// - Right: "< Page X >"
class ReportPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onRowsPerPageChanged;

  const ReportPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Show 10 [dropdown]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Show',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: reportMutedColor,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                height: 28.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: reportBorderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: rowsPerPage,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 18.sp,
                      color: Colors.black87,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [10, 20, 50, 100].map((int val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text('$val'),
                      );
                    }).toList(),
                    onChanged: onRowsPerPageChanged,
                  ),
                ),
              ),
            ],
          ),
          // Right: < Page X >
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  size: 18.sp,
                  color: currentPage > 0
                      ? Colors.black87
                      : Colors.grey.shade300,
                ),
                onPressed: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              SizedBox(width: 8.w),
              Text(
                'Page ${currentPage + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 18.sp,
                  color: currentPage < totalPages - 1
                      ? Colors.black87
                      : Colors.grey.shade300,
                ),
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Premium styled data table decoration helper
ThemeData getReportTableTheme(BuildContext context) {
  return Theme.of(context).copyWith(
    cardColor: Colors.white,
    dividerColor: Colors.transparent,
    dataTableTheme: DataTableThemeData(
      headingRowColor: MaterialStateProperty.all(Colors.transparent),
      headingTextStyle: GoogleFonts.poppins(
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
        color: reportMutedColor,
      ),
      dataTextStyle: GoogleFonts.poppins(
        fontSize: 9.sp,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
      horizontalMargin: 8.w,
      columnSpacing: 18.w,
    ),
  );
}
