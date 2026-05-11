import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'add_wedding_package.dart';
import 'services/api_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'widgets/subscription_wrapper.dart';
import 'my_Profile.dart';
import 'Notification.dart';
import 'vendor_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WeddingPackagePage extends StatefulWidget {
  const WeddingPackagePage({super.key});

  @override
  State<WeddingPackagePage> createState() => _WeddingPackagePageState();
}

class _WeddingPackagePageState extends State<WeddingPackagePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String _statusFilter = 'All Status';
  final List<String> _statusOptions = [
    'All Status',
    'Approved',
    'Rejected',
    'Pending'
  ];

  List<WeddingPackage> _allPackages = [];
  List<WeddingPackage> _filteredPackages = [];
  List<StaffMember> _allStaff = [];
  bool _isLoading = true;
  VendorProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.businessName ?? 'H').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPackages = _allPackages.where((p) {
        final matchesSearch = searchQuery.isEmpty ||
            (p.name?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                false) ||
            (p.description?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                false);
        final matchesStatus = _statusFilter == 'All Status' ||
            (p.status?.toLowerCase() == _statusFilter.toLowerCase());
        return matchesSearch && matchesStatus;
      }).toList();
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

  // ── Stats helpers ──────────────────────────────────────────
  int get _totalPackages => _allPackages.length;

  double get _avgPrice => _allPackages.isEmpty
      ? 0
      : _allPackages
              .map((e) => e.discountedPrice ?? e.totalPrice ?? 0)
              .reduce((a, b) => a + b) /
          _allPackages.length;

  String get _popularPackage =>
      _allPackages.isEmpty ? '-' : (_allPackages.first.name ?? '-');

  double get _avgDurationHours => _allPackages.isEmpty
      ? 0
      : _allPackages.map((e) => e.duration ?? 0).reduce((a, b) => a + b) /
          (_allPackages.length * 60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(currentPage: 'Wedding Package'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Wedding Packages',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const My_Profile()),
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: ClipOval(
                  child: (_profile != null && _profile!.profileImage.isNotEmpty)
                      ? Image.network(
                          _profile!.profileImage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => _buildInitialAvatar(),
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                                  ? child
                                  : const CircularProgressIndicator(),
                        )
                      : _buildInitialAvatar(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SubscriptionWrapper(
        child: Column(
          children: [
            // ── Search + Filter + Add ──────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  // Search bar
                  SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(fontSize: 12),
                      onChanged: (v) {
                        searchQuery = v;
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or description....',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search,
                            size: 17, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor, width: 1.2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter + Add New
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey.shade800),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 1.2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: Colors.grey.shade500),
                            dropdownColor: Colors.white,
                            items: _statusOptions
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s,
                                          style: GoogleFonts.poppins(fontSize: 12)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _statusFilter = v);
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: _showCreatePackageForm,
                          icon: const Icon(Icons.add_rounded,
                              size: 16, color: Colors.white),
                          label: Text(
                            'Add New',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        children: [
                          // Stat Cards 2×2
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.6,
                            children: [
                              _buildStatCard(
                                emoji: '🏷️',
                                label: 'Total Packages',
                                value: '$_totalPackages',
                              ),
                              _buildStatCard(
                                emoji: '💰',
                                label: 'Average\nPackage Price',
                                value: '₹ ${_avgPrice.toStringAsFixed(0)}',
                              ),
                              _buildStatCard(
                                emoji: '👑',
                                label: 'Services in Top\nPackage',
                                value: _popularPackage,
                                valueSize: 11,
                              ),
                              _buildStatCard(
                                emoji: '⏱️',
                                label: 'Average Package\nDuration',
                                value:
                                    '${_avgDurationHours.toStringAsFixed(1)} Hours',
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Package list
                          if (_filteredPackages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text('No packages found',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey, fontSize: 12)),
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
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat Card ────────────────────────────────────────────────
  Widget _buildStatCard({
    required String emoji,
    required String label,
    required String value,
    double valueSize = 14,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey.shade500, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: valueSize,
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

  // ── Package Card ─────────────────────────────────────────────
  Widget _buildPackageCard(WeddingPackage pkg) {
    final staffIds = pkg.assignedStaff ?? [];
    final firstStaff = staffIds.isNotEmpty
        ? _allStaff.firstWhere((s) => s.id == staffIds.first,
            orElse: () => StaffMember(fullName: 'Unknown'))
        : null;
    final extraStaffCount = staffIds.length > 1 ? staffIds.length - 1 : 0;

    // Build service subtitle: first service name + remaining count
    final serviceCount = pkg.services?.length ?? 0;
    String firstServiceName = 'Service';
    if (serviceCount > 0) {
      final first = pkg.services!.first;
      if (first is Map) {
        firstServiceName = first['serviceName'] ?? 'Service';
      } else {
        firstServiceName = first.toString();
      }
    }
    final serviceSubtitle = serviceCount > 0
        ? '$firstServiceName +${serviceCount - 1}'
        : '$serviceCount services';

    final durationH = (pkg.duration ?? 0) ~/ 60;
    final durationM = (pkg.duration ?? 0) % 60;
    final durationStr =
        durationM == 0 ? '${durationH}hr' : '${durationH}hr ${durationM}min';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: image + info + toggle ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey.shade200,
                    child: pkg.image != null
                        ? Image.network(pkg.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.image_outlined,
                                size: 22,
                                color: Colors.grey.shade400))
                        : Icon(Icons.image_outlined,
                            size: 22, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + subtitle + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              pkg.name ?? 'Unnamed',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹ ${(pkg.discountedPrice ?? pkg.totalPrice ?? 0).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serviceSubtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Status badge + duration + toggle ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Row(
              children: [
                // Push content to align with text (after image)
                const SizedBox(width: 62),
                _StatusBadge(status: pkg.status ?? 'pending'),
                const SizedBox(width: 8),
                Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Icon(Icons.access_time, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(
                  durationStr,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
                const Spacer(),
                // Toggle
                Transform.scale(
                  scale: 0.75,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: pkg.isActive ?? false,
                    onChanged: (v) => _toggleStatus(pkg, v),
                    activeColor: Theme.of(context).primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),

          // ── Bottom row: staff + actions ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 6, 10),
            child: Row(
              children: [
                // Staff name
                if (firstStaff != null) ...[
                  Text(
                    firstStaff.fullName ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                  if (extraStaffCount > 0)
                    Text(
                      ' +$extraStaffCount',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                ] else
                  Text(
                    '0 staff',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                const Spacer(),
                // Eye icon
                _iconBtn(Icons.remove_red_eye_outlined, () {},
                    color: Colors.grey.shade500),
                // Edit icon
                _iconBtn(
                  Icons.edit_outlined,
                  () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) =>
                          CreateWeddingPackageDialog(package: pkg),
                    );
                    if (result == true) _loadData();
                  },
                  color: Colors.grey.shade500,
                ),
                // Delete icon
                _iconBtn(
                  Icons.delete_outline,
                  () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Package'),
                        content: const Text(
                            'Are you sure you want to delete this wedding package?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        final success =
                            await ApiService.deleteWeddingPackage(pkg.id!);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Wedding package deleted successfully')),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
                          );
                        }
                      }
                    }
                  },
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Icon(icon, size: 16, color: color ?? Colors.grey.shade400),
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    if (s == 'approved' || s == 'active') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (s == 'reject' || s == 'rejected') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade600;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
    }

    String label = status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// Keep public StatusBadge for backward compatibility
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return _StatusBadge(status: status);
  }
}
