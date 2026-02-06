import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'addon_model.dart';
// Service class is defined in api_service.dart

class AddOnsPage extends StatefulWidget {
  const AddOnsPage({super.key});

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> {
  bool _isLoading = true;
  List<AddOn> _addOns = [];
  Map<String, String> _serviceNameMap = {};

  int _currentPage = 1;
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25];

  @override
  void initState() {
    super.initState();
    _loadData();
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
          _serviceNameMap = {
            for (var s in services) s.id ?? '': s.name ?? 'Unknown Service'
          };
          _isLoading = false;
        });
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
      builder: (_) => AddEditAddOnDialog(
        addOn: edit,
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
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
    if (_addOns.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    if (startIndex >= _addOns.length) return [];
    return _addOns.sublist(
        startIndex, endIndex > _addOns.length ? _addOns.length : endIndex);
  }

  int get _totalPages => (_addOns.length / _rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Add Ons'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add-Ons',
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
              onPressed: () => _openAddDialog(),
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                'Create',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_addOns.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No add-ons found',
                                  style:
                                      GoogleFonts.poppins(color: Colors.grey)),
                            ),
                          )
                        else
                          ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _paginatedAddOns.length,
                              itemBuilder: (context, index) {
                                final addon = _paginatedAddOns[index];
                                return _buildAddOnCard(addon);
                              }),
                      ],
                    ),
                  ),
                ),
                _buildPaginationControls(),
              ],
            ),
    );
  }

  Widget _buildPaginationControls() {
    if (_addOns.isEmpty) return const SizedBox.shrink();

    final startIndex = (_currentPage - 1) * _rowsPerPage + 1;
    final endIndex = (_currentPage * _rowsPerPage) > _addOns.length
        ? _addOns.length
        : (_currentPage * _rowsPerPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            'Showing $startIndex to $endIndex of ${_addOns.length} results',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rows per page',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    items: _rowsPerPageOptions.map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value',
                            style: GoogleFonts.poppins(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _rowsPerPage = newValue;
                          _currentPage = 1;
                        });
                      }
                    },
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'Page $_currentPage of $_totalPages',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnCard(AddOn addon) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(addon.name ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('₹${(addon.price ?? 0).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoTag(
                            '${addon.duration ?? 0} min', Icons.access_time),
                        const SizedBox(width: 8),
                        StatusBadge(status: addon.status ?? 'active'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildServiceChips(addon.mappedServices ?? []),
              ),
              const SizedBox(width: 8),
              _iconAction(Icons.edit_outlined, () => _openAddDialog(addon),
                  color: Theme.of(context).primaryColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              _iconAction(Icons.delete_outline, () => _deleteConfirm(addon.id!),
                  color: Colors.red.shade300),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 16, color: color ?? Colors.grey.shade400),
      ),
    );
  }

  Widget _buildServiceChips(List<String> serviceIds) {
    if (serviceIds.isEmpty) {
      return Text('No services mapped',
          style:
              GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400));
    }
    // Limit to showing first 3 services to avoid overflow, or wrap all
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: serviceIds.map((id) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            _getServiceName(id),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: isApproved ? Colors.green.shade700 : Colors.orange.shade700,
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
                        fontSize: 18,
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                _label('Add-on Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  decoration: _inputDecoration(),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Price (₹)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(),
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Duration (min)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _duration,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(),
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _label('Mapped Services'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: _isLoadingServices
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _availableServices.isEmpty
                          ? const Center(child: Text("No services available"))
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
                                        width: 24,
                                        height: 24,
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
                                                BorderRadius.circular(4),
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade400,
                                            width: 1.5,
                                          ),
                                          activeColor:
                                              Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          s.name ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
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
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey.shade800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Save Add-On',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
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
        fontSize: 13,
        color: Colors.grey.shade800,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
