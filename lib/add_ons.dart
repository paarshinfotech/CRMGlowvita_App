import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'addon_model.dart';
import 'widgets/subscription_wrapper.dart';
import 'vendor_model.dart';
import 'my_Profile.dart';
import 'Notification.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddOnsPage extends StatefulWidget {
  const AddOnsPage({super.key});

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> {
  bool _isLoading = true;
  List<AddOn> _addOns = [];
  List<AddOn> _filteredAddOns = [];
  Map<String, String> _serviceNameMap = {};
  VendorProfile? _profile;

  int _currentPage = 1;
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25];

  String _searchQuery = '';
  String _statusFilter = 'All Status';
  final List<String> _statusOptions = ['All Status', 'Active', 'Inactive'];

  final TextEditingController _searchController = TextEditingController();

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

  void _applyFilters() {
    setState(() {
      _filteredAddOns = _addOns.where((addon) {
        final matchesSearch = _searchQuery.isEmpty ||
            (addon.name ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'All Status' ||
            (addon.status ?? '').toLowerCase() == _statusFilter.toLowerCase();
        return matchesSearch && matchesStatus;
      }).toList();
      _currentPage = 1;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAddOns(),
        ApiService.getServices(),
      ]);

      final addons = results[0] as List<AddOn>;
      final services = results[1] as List<Service>;

      if (mounted) {
        setState(() {
          _addOns = addons;
          _filteredAddOns = addons;
          _serviceNameMap = {
            for (var s in services) s.id ?? '': s.name ?? 'Unknown Service'
          };
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _openAddDialog([AddOn? edit]) {
    showDialog(
      context: context,
      builder: (_) => AddEditAddOnDialog(addOn: edit),
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  Future<void> _deleteConfirm(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Add-on?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await ApiService.deleteAddOn(id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add-on deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting add-on: $e')),
          );
        }
      }
    }
  }

  String _getServiceName(String id) {
    return _serviceNameMap[id] ?? 'Unknown Service';
  }

  List<AddOn> get _paginatedAddOns {
    if (_filteredAddOns.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    if (startIndex >= _filteredAddOns.length) return [];
    return _filteredAddOns.sublist(startIndex,
        endIndex > _filteredAddOns.length ? _filteredAddOns.length : endIndex);
  }

  int get _totalPages => _filteredAddOns.isEmpty
      ? 1
      : (_filteredAddOns.length / _rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Add Ons'),
      backgroundColor: Colors.white,
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
          'Add-Ons',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSearchAndFilter(),
                  Expanded(
                    child: _filteredAddOns.isEmpty
                        ? Center(
                            child: Text('No add-ons found',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey, fontSize: 12)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            itemCount: _paginatedAddOns.length,
                            itemBuilder: (context, index) {
                              return _buildAddOnCard(_paginatedAddOns[index]);
                            },
                          ),
                  ),
                  _buildPaginationControls(),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
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
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search services......',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search, size: 17, color: Colors.grey.shade400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
          // Status filter row + Add New button
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
                        _statusFilter = v;
                        _applyFilters();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Add New button
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () => _openAddDialog(),
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
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rows per page
          Row(
            children: [
              Text('Show',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 6),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    isDense: true,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade800),
                    items: _rowsPerPageOptions
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text('$v',
                                  style: GoogleFonts.poppins(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _rowsPerPage = v;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          // Page navigation
          Row(
            children: [
              _pageNavBtn(
                Icons.chevron_left,
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Page $_currentPage',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              _pageNavBtn(
                Icons.chevron_right,
                _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageNavBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  onTap != null ? Colors.grey.shade400 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildAddOnCard(AddOn addon) {
    // Get the first mapped service name as the "category" label shown in image
    final categoryLabel = (addon.mappedServices ?? []).isNotEmpty
        ? _getServiceName(addon.mappedServices!.first)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name + Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.name ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    if (categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        categoryLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(status: addon.status ?? 'active'),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Eye icon + Price + Clock + Duration | Edit + Delete
          Row(
            children: [
              // Eye icon
              Icon(Icons.remove_red_eye_outlined,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              // Price
              Text(
                '₹${(addon.price ?? 0).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
              const SizedBox(width: 12),
              // Clock + duration
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text(
                _formatDuration(addon.duration ?? 0),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              // Edit
              _iconAction(
                Icons.edit_outlined,
                () => _openAddDialog(addon),
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              // Delete
              _iconAction(
                Icons.delete_outline,
                () => _deleteConfirm(addon.id!),
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}hr' : '${h}hr ${m}min';
  }

  Widget _iconAction(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Icon(icon, size: 15, color: color ?? Colors.grey.shade400),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//                       STATUS BADGE
// ──────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//                           DIALOG
// ──────────────────────────────────────────────────────────────

class AddEditAddOnDialog extends StatefulWidget {
  final AddOn? addOn;
  final String? initialServiceId;

  const AddEditAddOnDialog({
    super.key,
    this.addOn,
    this.initialServiceId,
  });

  @override
  State<AddEditAddOnDialog> createState() => _AddEditAddOnDialogState();
}

class _AddEditAddOnDialogState extends State<AddEditAddOnDialog> {
  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _duration;

  List<String> _selected = [];
  List<Service> _availableServices = [];
  bool _isSaving = false;
  bool _isLoadingServices = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.addOn?.name);
    _price =
        TextEditingController(text: widget.addOn?.price?.toStringAsFixed(0));
    _duration = TextEditingController(text: widget.addOn?.duration?.toString());
    _selected = List.from(widget.addOn?.mappedServices ?? []);
    if (widget.addOn == null && widget.initialServiceId != null) {
      if (!_selected.contains(widget.initialServiceId)) {
        _selected.add(widget.initialServiceId!);
      }
    }
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final services = await ApiService.getServices();
      if (mounted) {
        setState(() {
          _availableServices = services;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching services: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final newAddOn = AddOn(
          id: widget.addOn?.id,
          name: _name.text.trim(),
          price: double.tryParse(_price.text.trim()),
          duration: int.tryParse(_duration.text.trim()),
          mappedServices: _selected,
          status: widget.addOn?.status ?? 'active',
        );

        bool success;
        if (widget.addOn == null) {
          success = await ApiService.createAddOn(newAddOn);
        } else {
          success = await ApiService.updateAddOn(widget.addOn!.id!, newAddOn);
        }

        if (success && mounted) {
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save add-on')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.addOn == null ? 'Create Add-On' : 'Edit Add-On',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Add extra services your customers can choose',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
                _label('Add-on Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _name,
                  style: GoogleFonts.poppins(fontSize: 12),
                  decoration: _inputDecoration(),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Price (₹)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 12),
                            decoration: _inputDecoration(),
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Duration (min)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _duration,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 12),
                            decoration: _inputDecoration(),
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _label('Mapped Services'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: _isLoadingServices
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _availableServices.isEmpty
                          ? Center(
                              child: Text("No services available",
                                  style: GoogleFonts.poppins(fontSize: 11)))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 4.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 0,
                              ),
                              itemCount: _availableServices.length,
                              itemBuilder: (context, index) {
                                final s = _availableServices[index];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (_selected.contains(s.id)) {
                                        _selected.remove(s.id);
                                      } else {
                                        if (s.id != null) _selected.add(s.id!);
                                      }
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _selected.contains(s.id),
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                if (s.id != null)
                                                  _selected.add(s.id!);
                                              } else {
                                                _selected.remove(s.id);
                                              }
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade400,
                                            width: 1.5,
                                          ),
                                          activeColor:
                                              Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          s.name ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Save Add-On',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: Colors.grey.shade800,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B4E71), width: 1.8),
      ),
    );
  }
}
