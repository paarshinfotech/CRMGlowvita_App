import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'add_wedding_package.dart';

class WeddingPackagePage extends StatefulWidget {
  const WeddingPackagePage({super.key});

  @override
  State<WeddingPackagePage> createState() => _WeddingPackagePageState();
}

class _WeddingPackagePageState extends State<WeddingPackagePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, dynamic>> packages = [
    {
      'name': 'Trial Package',
      'services': '2 services',
      'duration': '2h 0m',
      'staff': ['Test2', 'juli ware'],
      'price': '₹430',
      'status': 'pending',
      'active': true,
    },
    {
      'name': 'bridal package',
      'services': '1 services',
      'duration': '1h 0m',
      'staff': ['1 staff'],
      'price': '₹250',
      'status': 'approved',
      'active': true,
    },
  ];

  void _showCreatePackageForm() {
    showDialog(
      context: context,
      builder: (context) => const CreateWeddingPackageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(currentPage: 'Wedding Package'),
      appBar: AppBar(
        title: Text(
          'Wedding Packages',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87, size: 20),
        toolbarHeight: 50,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FilledButton.icon(
              onPressed: _showCreatePackageForm,
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                'Create',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF331F33),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid ─ Minimal
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isMobile ? 2.5 : 3.0,
                children: [
                  _buildStatCard('Total', '2', Icons.local_offer_outlined),
                  _buildStatCard('Avg Price', '₹340', Icons.attach_money),
                  _buildStatCard('Popular', 'Trial', Icons.star_outline),
                  _buildStatCard('Avg Duration.', '2h', Icons.bar_chart),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Search Bar ─ Compact
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => searchQuery = v),
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search packages...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade400),
                  prefixIcon:
                      Icon(Icons.search, size: 16, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Packages List ─ Card Based
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index];
                return _buildPackageCard(pkg);
              },
            ),

            const SizedBox(height: 16),
            // Pagination ─ Compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('2 results',
                    style:
                        GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                Row(
                  children: [
                    IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints()),
                    const SizedBox(width: 8),
                    Text('Page 1 of 1',
                        style: GoogleFonts.poppins(fontSize: 11)),
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.chevron_right, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade600)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image_outlined,
                    size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(pkg['name'],
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(pkg['price'],
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF331F33))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoTag(pkg['services'], Icons.settings_outlined),
                        const SizedBox(width: 8),
                        _buildInfoTag(pkg['duration'], Icons.access_time),
                        const SizedBox(width: 8),
                        StatusBadge(status: pkg['status']),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Active',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    width: 34,
                    child: Switch(
                      value: pkg['active'],
                      onChanged: (v) {},
                      activeColor: const Color(0xFF331F33),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _iconAction(Icons.visibility_outlined, () {}),
                  _iconAction(Icons.edit_outlined, () {}),
                  _iconAction(Icons.delete_outline, () {},
                      color: Colors.red.shade400),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(text,
            style:
                GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _iconAction(IconData icon, VoidCallback onTap, {Color? color}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color ?? Colors.grey.shade400),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status.toLowerCase() == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: isApproved ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
