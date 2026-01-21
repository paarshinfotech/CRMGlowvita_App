import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'add_wedding_package.dart';
import 'services/api_service.dart';

class WeddingPackagePage extends StatefulWidget {
  const WeddingPackagePage({super.key});

  @override
  State<WeddingPackagePage> createState() => _WeddingPackagePageState();
}

class _WeddingPackagePageState extends State<WeddingPackagePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  List<WeddingPackage> _allPackages = [];
  List<WeddingPackage> _filteredPackages = [];
  List<StaffMember> _allStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getWeddingPackages(),
        ApiService.getStaff(),
      ]);
      setState(() {
        _allPackages = results[0] as List<WeddingPackage>;
        _allStaff = results[1] as List<StaffMember>;
        _filteredPackages = _allPackages;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterPackages(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        _filteredPackages = _allPackages;
      } else {
        _filteredPackages = _allPackages
            .where((p) =>
                (p.name?.toLowerCase().contains(query.toLowerCase()) ??
                    false) ||
                (p.description?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  void _showCreatePackageForm() {
    showDialog(
      context: context,
      builder: (context) => const CreateWeddingPackageDialog(),
    ).then((_) => _loadData());
  }

  Future<void> _toggleStatus(WeddingPackage pkg, bool val) async {
    final success = await ApiService.toggleWeddingPackageStatus(pkg.id!, val);
    if (success) _loadData();
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
                  _buildStatCard('Total', '${_allPackages.length}',
                      Icons.local_offer_outlined),
                  _buildStatCard(
                      'Avg Price',
                      '₹${_allPackages.isEmpty ? 0 : (_allPackages.map((e) => e.discountedPrice ?? e.totalPrice ?? 0).reduce((a, b) => a + b) / _allPackages.length).toStringAsFixed(0)}',
                      Icons.attach_money),
                  _buildStatCard(
                      'Popular',
                      _allPackages.isEmpty ? '-' : _allPackages.first.name!,
                      Icons.star_outline),
                  _buildStatCard(
                      'Avg Duration.',
                      '${_allPackages.isEmpty ? 0 : (_allPackages.map((e) => e.duration ?? 0).reduce((a, b) => a + b) / (_allPackages.length * 60)).toStringAsFixed(1)}h',
                      Icons.bar_chart),
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
                onChanged: _filterPackages,
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

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredPackages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No packages found',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredPackages.length,
                itemBuilder: (context, index) {
                  final pkg = _filteredPackages[index];
                  return _buildPackageCard(pkg);
                },
              ),

            const SizedBox(height: 16),
            // Pagination ─ Compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_filteredPackages.length} results',
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

  Widget _buildPackageCard(WeddingPackage pkg) {
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
                  image: pkg.image != null
                      ? DecorationImage(
                          image: NetworkImage(pkg.image!), fit: BoxFit.cover)
                      : null,
                ),
                child: pkg.image == null
                    ? const Icon(Icons.image_outlined,
                        size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(pkg.name ?? 'Unnamed',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                            '₹${(pkg.discountedPrice ?? pkg.totalPrice ?? 0).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF331F33))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoTag('${pkg.services?.length ?? 0} services',
                            Icons.settings_outlined),
                        const SizedBox(width: 8),
                        _buildInfoTag(
                            '${(pkg.duration ?? 0) ~/ 60}h ${(pkg.duration ?? 0) % 60}m',
                            Icons.access_time),
                        const SizedBox(width: 8),
                        StatusBadge(status: pkg.status ?? 'pending'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStaffChips(pkg.assignedStaff),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text('Active',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.6,
                        child: SizedBox(
                          height: 20,
                          width: 34,
                          child: Switch(
                            value: pkg.isActive ?? false,
                            onChanged: (v) => _toggleStatus(pkg, v),
                            activeColor: const Color(0xFF331F33),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
        ],
      ),
    );
  }

  Widget _buildStaffChips(List<dynamic>? staffIds) {
    if (staffIds == null || staffIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15)),
        child: Text('0 staff',
            style:
                GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE0D8E0),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text('${staffIds.length} staff',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF424242))),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: staffIds.map((id) {
            final staff = _allStaff.firstWhere((s) => s.id == id,
                orElse: () => StaffMember(fullName: 'Unknown'));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(staff.fullName ?? '?',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6A1B9A))),
            );
          }).toList(),
        ),
      ],
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
