import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'social_media_editor.dart';

class SocialMediaMarketingPage extends StatefulWidget {
  const SocialMediaMarketingPage({super.key});

  @override
  State<SocialMediaMarketingPage> createState() =>
      _SocialMediaMarketingPageState();
}

class _SocialMediaMarketingPageState extends State<SocialMediaMarketingPage> {
  final TextEditingController _searchController = TextEditingController();

  // Dummy template data — replace with real data source
  final List<Map<String, dynamic>> _templates = [
    {
      'title': 'Birthday Bash',
      'tag': 'Happy Birthday',
      'tagColor': Colors.purple,
      'image': 'https://picsum.photos/seed/bday/300/300',
    },
    {
      'title': 'Sale Promo',
      'tag': 'Sale',
      'tagColor': Colors.red,
      'image': 'https://picsum.photos/seed/sale/300/300',
    },
    {
      'title': 'New Arrival',
      'tag': 'New',
      'tagColor': Colors.teal,
      'image': 'https://picsum.photos/seed/new/300/300',
    },
    {
      'title': 'Holiday Special',
      'tag': 'Holiday',
      'tagColor': Colors.green,
      'image': 'https://picsum.photos/seed/holiday/300/300',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _templates;
    return _templates
        .where(
          (t) =>
              t['title'].toString().toLowerCase().contains(q) ||
              t['tag'].toString().toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1A1A2E),
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Templates',
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          SizedBox(height: 10.h),
          Text(
            '${_filtered.length} template${_filtered.length == 1 ? '' : 's'} found',
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2F7),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search templates...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 11.sp,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 18,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 8.h),
            Text(
              'No templates found',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(14.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildTemplateCard(items[index]),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final tagColor = template['tagColor'] as Color;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SocialMediaEditorPage()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thumbnail ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14.r),
                  ),
                  child: Image.network(
                    template['image'] as String,
                    height: 130.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130.h,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade300,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: tagColor.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      template['tag'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 7.sp,
                        color: tagColor.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // --- Info ---
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    height: 30.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SocialMediaEditorPage(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B2D3D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Customize',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
