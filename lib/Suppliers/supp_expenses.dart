import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import './supp_drawer.dart';
import '../services/api_service.dart';
import '../widgets/subscription_wrapper.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'supp_profile.dart';
import 'supp_notifications.dart';
import '../supplier_model.dart';

class SuppExpensesPage extends StatefulWidget {
  const SuppExpensesPage({super.key});
  @override
  State<SuppExpensesPage> createState() => _SuppExpensesPageState();
}

class _SuppExpensesPageState extends State<SuppExpensesPage> {
  static const double _radius = 14, _gap = 15;

  List<Map<String, dynamic>> expenses = [];
  bool _isLoading = true;
  SupplierProfile? _profile;

  String _searchQuery = '';
  String _selectedPaymentMode = 'All Payment Modes';
  DateTime? _startDate, _endDate;
  double? _minAmount = 0, _maxAmount;
  final TextEditingController _searchController = TextEditingController();
  List<String> _apiExpenseTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _fetchProfile();
    _loadExpenseTypes();
  }

  Future<void> _loadExpenseTypes() async {
    try {
      final types = await ApiService.fetchExpenseTypes();
      if (mounted) {
        setState(() {
          _apiExpenseTypes = types.map((e) => e['name'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading expense types: $e');
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getSupplierProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  Widget _buildInitialAvatar() {
    return Text(
      (_profile?.shopName ?? 'S').substring(0, 1).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final fetchedExpenses = await ApiService.getExpenses();
      setState(() {
        expenses = fetchedExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  int get totalRecords => expenses.length;
  double get totalExpenses =>
      expenses.fold(0.0, (sum, e) => sum + (e['amount'] as num? ?? 0));
  int get currentMonthExpenses {
    final now = DateTime.now();
    return expenses
        .where((expense) {
          try {
            final dt = DateTime.parse(expense['date'] ?? "");
            return dt.month == now.month && dt.year == now.year;
          } catch (_) {
            return false;
          }
        })
        .fold(0, (sum, e) => sum + (e['amount'] as num? ?? 0).toInt());
  }

  List<Map<String, dynamic>> get filteredExpenses => expenses.where((expense) {
    final matchesSearch =
        _searchQuery.isEmpty ||
        (expense['_id']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false) ||
        ((expense['expenseType'] ?? expense['type'])?.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ??
            false) ||
        (expense['note']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false);
    final matchesPaymentMode =
        _selectedPaymentMode == 'All Payment Modes' ||
        expense['paymentMode'] == _selectedPaymentMode;
    bool matchesDateRange = true;
    if (_startDate != null || _endDate != null) {
      try {
        final dt = DateTime.parse(expense['date']);
        if (_startDate != null && dt.isBefore(_startDate!))
          matchesDateRange = false;
        if (_endDate != null && dt.isAfter(_endDate!)) matchesDateRange = false;
      } catch (_) {}
    }
    final minAmt = _minAmount ?? 0;
    final maxAmt = _maxAmount ?? double.infinity;
    final matchesAmount =
        (expense['amount'] as num? ?? 0) >= minAmt &&
        (expense['amount'] as num? ?? 0) <= maxAmt;
    return matchesSearch &&
        matchesPaymentMode &&
        matchesDateRange &&
        matchesAmount;
  }).toList();

  void _openFilterDialog() async {
    final result = await showDialog(
      context: context,
      builder: (_) => FilterOptionsDialog(
        paymentMode: _selectedPaymentMode,
        fromDate: _startDate,
        toDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
      ),
    );
    if (result is Map) {
      setState(() {
        _selectedPaymentMode = result["paymentMode"] ?? _selectedPaymentMode;
        _startDate = result["fromDate"] ?? _startDate;
        _endDate = result["toDate"] ?? _endDate;
        _minAmount = result["minAmount"] ?? 0;
        _maxAmount = result["maxAmount"];
      });
    }
  }

  void _openAddExpenseDialog() async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddExpenseDialog(
        expenseTypes: _apiExpenseTypes.isNotEmpty
            ? _apiExpenseTypes
            : const [
                "Customs Charges",
                "Equipment Purchase",
                "Freight Charges",
                "Handling Charges",
                "Import/Export Duty",
                "Logistics & Shipping",
                "Machine Maintenance",
                "Office Rent",
                "Raw Material Purchase",
                "Repair Charges",
                "Salaries & Wages",
                "Stock Purchase",
                "Product Packaging",
                "Marketing & Ads",
                "Lab Testing",
                "Utilities",
                "Software Subscriptions",
                "Insurance",
                "Travel",
                "Office Supplies",
                "Others",
              ],
      ),
    );
    if (result == true) {
      _fetchExpenses();
    }
  }

  void _openEditExpenseDialog(Map<String, dynamic> expense) async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddExpenseDialog(
        expense: expense,
        isEdit: true,
        expenseTypes: _apiExpenseTypes.isNotEmpty
            ? _apiExpenseTypes
            : const [
                "Customs Charges",
                "Equipment Purchase",
                "Freight Charges",
                "Handling Charges",
                "Import/Export Duty",
                "Logistics & Shipping",
                "Machine Maintenance",
                "Office Rent",
                "Raw Material Purchase",
                "Repair Charges",
                "Salaries & Wages",
                "Stock Purchase",
                "Product Packaging",
                "Marketing & Ads",
                "Lab Testing",
                "Utilities",
                "Software Subscriptions",
                "Insurance",
                "Travel",
                "Office Supplies",
                "Others",
              ],
      ),
    );
    if (result == true) {
      _fetchExpenses();
    }
  }

  void _openViewExpenseDialog(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (_) => ExpenseDetailsDialog(expense: expense),
    );
  }

  void _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ApiService.deleteExpense(id);
        if (success) {
          _fetchExpenses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final List<List<dynamic>> rows = [];
      rows.add([
        "ID",
        "Date",
        "Expense Type",
        "Amount",
        "Payment Mode",
        "Invoice No",
        "Note",
        "Status",
      ]);

      for (var expense in filteredExpenses) {
        rows.add([
          expense['_id'] ?? "",
          expense['date'] ?? "",
          expense['expenseType'] ?? expense['type'] ?? "",
          expense['amount'] ?? 0,
          expense['paymentMode'] ?? "",
          expense['invoiceNo'] ?? "",
          expense['note'] ?? "",
          expense['status'] ?? "",
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path =
          "${directory.path}/expenses_export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
        OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Expenses'),
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
          'Expenses',
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
              MaterialPageRoute(builder: (_) => const SuppNotificationsPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuppProfilePage()),
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
        child: Padding(
          padding: const EdgeInsets.all(_gap),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Track and manage your business expenses related to product supply",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Total Expenses',
                      value: '₹${totalExpenses.toStringAsFixed(0)}',
                      subtitle: 'All-time expenses',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'This Month',
                      value: '₹$currentMonthExpenses',
                      subtitle: 'Current month expenses',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      title: 'Total Records',
                      value: '$totalRecords',
                      subtitle: 'Total expense entries',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Business Expenses',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Track costs for raw materials, packaging, marketing, and more',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalRecords',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search Expenses...',
                        hintStyle: GoogleFonts.poppins(fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_radius),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_radius),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.black87,
                          size: 18,
                        ),
                        onPressed: _openFilterDialog,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportToCSV,
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(
                      "Export",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 33),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  ElevatedButton.icon(
                    onPressed: _openAddExpenseDialog,
                    icon: const Icon(Icons.add, size: 17),
                    label: Text(
                      "Add Expense",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 33),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredExpenses.isEmpty
                    ? Center(
                        child: Text(
                          'No expenses found',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchExpenses,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 11, top: 3),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (ctx, idx) => ExpenseCard(
                            expense: filteredExpenses[idx],
                            onView: () =>
                                _openViewExpenseDialog(filteredExpenses[idx]),
                            onEdit: () =>
                                _openEditExpenseDialog(filteredExpenses[idx]),
                            onDelete: () => _deleteExpense(
                              filteredExpenses[idx]['_id'] ?? '',
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final double fontSize;
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.fontSize = 13,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: const Color(0xFFF3F4F6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense['expenseType'] ?? expense['type'] ?? "Expense",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize + 2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      expense['paymentMode'] ?? "Online",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4338CA),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    "Invoice No.: ${expense['invoiceNo'] ?? 'N/A'}",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: fontSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("•", style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(expense['date']),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Amount : ",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: fontSize + 2,
                      ),
                    ),
                    TextSpan(
                      text: "₹${expense['amount'] ?? '0'}",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize + 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onView,
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blue,
                  size: 22,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_note_outlined,
                  color: Colors.grey,
                  size: 22,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFB91C1C),
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String title, value, subtitle;
  final double fontSize;
  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.fontSize = 12,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: fontSize - 3,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: fontSize + 3,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: fontSize - 4,
            color: Colors.grey[500],
          ),
        ),
      ],
    ),
  );
}

class FilterOptionsDialog extends StatefulWidget {
  final String paymentMode;
  final DateTime? fromDate, toDate;
  final double? minAmount, maxAmount;
  const FilterOptionsDialog({
    Key? key,
    this.paymentMode = 'All Payment Modes',
    this.fromDate,
    this.toDate,
    this.minAmount,
    this.maxAmount,
  }) : super(key: key);
  @override
  State<FilterOptionsDialog> createState() => _FilterOptionsDialogState();
}

class _FilterOptionsDialogState extends State<FilterOptionsDialog> {
  late String _selectedPaymentMode;
  DateTime? _fromDate, _toDate;
  late TextEditingController _minAmountCtrl, _maxAmountCtrl;
  @override
  void initState() {
    super.initState();
    _selectedPaymentMode = widget.paymentMode;
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
    _minAmountCtrl = TextEditingController(
      text: widget.minAmount?.toString() ?? "0",
    );
    _maxAmountCtrl = TextEditingController(
      text: widget.maxAmount?.toString() ?? "",
    );
  }

  @override
  void dispose() {
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) => dt == null
      ? 'dd-mm-yyyy'
      : "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";

  @override
  Widget build(BuildContext context) {
    final fontSize = 13.0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Filter Options",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment Mode",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _selectedPaymentMode,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize - 1,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 0,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDEDEDE),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items:
                                      [
                                            'All Payment Modes',
                                            'Cash',
                                            'UPI',
                                            'Debit Card',
                                            'Net Banking',
                                          ]
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e,
                                                style: GoogleFonts.poppins(
                                                  fontSize: fontSize - 1,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) => setState(
                                    () => _selectedPaymentMode =
                                        v ?? "All Payment Modes",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "From Date",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _fromDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null)
                                    setState(() => _fromDate = picked);
                                },
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFDEDEDE),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatDate(_fromDate),
                                          style: GoogleFonts.poppins(
                                            fontSize: fontSize - 1,
                                            color: _fromDate == null
                                                ? Colors.grey[500]
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                    ],
                                  ),
                                ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "To Date",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _toDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null)
                                    setState(() => _toDate = picked);
                                },
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFDEDEDE),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatDate(_toDate),
                                          style: GoogleFonts.poppins(
                                            fontSize: fontSize - 1,
                                            color: _toDate == null
                                                ? Colors.grey[500]
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Min Amount (₹)",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                child: TextFormField(
                                  controller: _minAmountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: fontSize - 3,
                                      color: Colors.grey[500],
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDEDEDE),
                                      ),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize - 1,
                                  ),
                                ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Max Amount (₹)",
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                child: TextFormField(
                                  controller: _maxAmountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "No limit",
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: fontSize - 3,
                                      color: Colors.grey[500],
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDEDEDE),
                                      ),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize - 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      "Reset",
                      style: GoogleFonts.poppins(fontSize: fontSize - 1),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedPaymentMode = 'All Payment Modes';
                        _fromDate = null;
                        _toDate = null;
                        _minAmountCtrl.text = "0";
                        _maxAmountCtrl.text = "";
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      textStyle: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Apply'),
                    onPressed: () {
                      Navigator.pop(context, {
                        "paymentMode": _selectedPaymentMode,
                        "fromDate": _fromDate,
                        "toDate": _toDate,
                        "minAmount":
                            double.tryParse(_minAmountCtrl.text.trim()) ?? 0,
                        "maxAmount": double.tryParse(
                          _maxAmountCtrl.text.trim(),
                        ),
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final Map<String, dynamic>? expense;
  final bool isEdit;
  final List<String> expenseTypes;
  final List<String> paymentModes;
  final String? invoiceNumber;
  final DateTime? initialDate;

  const AddExpenseDialog({
    Key? key,
    this.expense,
    this.isEdit = false,
    this.expenseTypes = const [
      "Customs Charges",
      "Equipment Purchase",
      "Freight Charges",
      "Handling Charges",
      "Import/Export Duty",
      "Logistics & Shipping",
      "Machine Maintenance",
      "Office Rent",
      "Raw Material Purchase",
      "Repair Charges",
      "Salaries & Wages",
      "Stock Purchase",
      "Product Packaging",
      "Marketing & Ads",
      "Lab Testing",
      "Utilities",
      "Software Subscriptions",
      "Insurance",
      "Travel",
      "Office Supplies",
      "Others",
    ],
    this.paymentModes = const ["UPI", "Bank Transfer", "online"],
    this.invoiceNumber,
    this.initialDate,
  }) : super(key: key);

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  String? _expenseType, _paymentMode;
  final TextEditingController _amountCtrl = TextEditingController(text: "0.00");
  final TextEditingController _invoiceCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteCtrl = TextEditingController();
  String? _fileName;
  String? _invoiceBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.expense != null) {
      String? rawType =
          widget.expense!['expenseType'] ?? widget.expense!['type'];
      if (rawType != null) {
        final matches = widget.expenseTypes.where(
          (e) => e.toLowerCase() == rawType.toLowerCase(),
        );
        if (matches.isNotEmpty) {
          _expenseType = matches.first;
        } else {
          _expenseType = "Others";
        }
      }

      String? rawMode = widget.expense!['paymentMode'];
      if (rawMode != null) {
        final matches = widget.paymentModes.where(
          (e) => e.toLowerCase() == rawMode.toLowerCase(),
        );
        _paymentMode = matches.isNotEmpty ? matches.first : null;
      }
      _amountCtrl.text = (widget.expense!['amount'] ?? 0).toString();
      _invoiceCtrl.text = widget.expense!['invoiceNo'] ?? "";
      _noteCtrl.text = widget.expense!['note'] ?? "";
      if (widget.expense!['date'] != null) {
        try {
          _selectedDate = DateTime.parse(widget.expense!['date']);
        } catch (_) {
          _selectedDate = DateTime.now();
        }
      }
    } else {
      _invoiceCtrl.text = widget.invoiceNumber ?? "";
      _selectedDate = widget.initialDate ?? DateTime.now();
    }
  }

  Future<void> _pickInvoice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
      );

      if (result != null) {
        final file = result.files.first;
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();

        String mimeType = "image/${file.extension ?? 'jpeg'}";
        if (file.extension?.toLowerCase() == 'pdf') {
          mimeType = "application/pdf";
        }

        final base64String = "data:$mimeType;base64,${base64Encode(bytes)}";

        setState(() {
          _invoiceBase64 = base64String;
          _fileName = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _handleSave() async {
    if (_expenseType == null ||
        _paymentMode == null ||
        _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      if (widget.isEdit && widget.expense != null)
        "_id": widget.expense!['_id'],
      "expenseType": _expenseType,
      "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "amount": double.tryParse(_amountCtrl.text) ?? 0,
      "paymentMode": _paymentMode,
      "invoiceNo": _invoiceCtrl.text,
      "note": _noteCtrl.text,
      "invoice":
          _invoiceBase64 ?? (widget.isEdit ? widget.expense!['invoice'] : ""),
      "status": "Active",
    };

    try {
      bool success;
      if (widget.isEdit && widget.expense != null) {
        success = await ApiService.updateExpense(
          widget.expense!['_id'],
          payload,
        );
      } else {
        success = await ApiService.addExpense(payload);
      }

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        throw Exception("Unknown error occurred");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final minFont = 10.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEdit ? "Edit Expense" : "Add New Expense",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 2),
                    child: Text(
                      widget.isEdit
                          ? "Update expense details below"
                          : "Fill in the details to add a new expense",
                      style: GoogleFonts.poppins(
                        fontSize: minFont,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: RichText(
                      text: TextSpan(
                        text: "Expense Type ",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: minFont,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "*",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: minFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _expenseType,
                    onChanged: (v) => setState(() => _expenseType = v),
                    items: widget.expenseTypes
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: GoogleFonts.poppins(fontSize: minFont),
                            ),
                          ),
                        )
                        .toList(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Select expense type",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: minFont,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: minFont,
                      color: Colors.black,
                    ),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: "Date ",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: minFont,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "*",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: minFont,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () async {
                                  var date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (date != null)
                                    setState(() => _selectedDate = date);
                                },
                                child: Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}",
                                          style: GoogleFonts.poppins(
                                            fontSize: minFont,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.grey[600],
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: "Amount (₹) ",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: minFont,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "*",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: minFont,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 32,
                                child: TextFormField(
                                  controller: _amountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: minFont,
                                      color: Colors.grey,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: minFont),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 9, bottom: 2),
                    child: RichText(
                      text: TextSpan(
                        text: "Payment Mode ",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: minFont,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "*",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: minFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    onChanged: (v) => setState(() => _paymentMode = v),
                    items: widget.paymentModes
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: GoogleFonts.poppins(fontSize: minFont),
                            ),
                          ),
                        )
                        .toList(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Select payment mode",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: minFont,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: minFont,
                      color: Colors.black,
                    ),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text(
                      "Invoice Number (Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: minFont,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: TextFormField(
                      controller: _invoiceCtrl,
                      decoration: InputDecoration(
                        hintText: 'INV-001',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: minFont,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: minFont),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 9, bottom: 3),
                    child: Text(
                      "Expense Invoice (Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: minFont,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickInvoice,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: const Color(0xFFE8EAF1),
                          elevation: 0,
                          minimumSize: const Size(0, 26),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        child: Text(
                          "Choose File",
                          style: GoogleFonts.poppins(
                            fontSize: minFont,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _fileName ?? "No file chosen",
                                style: GoogleFonts.poppins(
                                  fontSize: minFont - 1,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_fileName != null &&
                                _fileName != "No file chosen")
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _invoiceBase64 = null;
                                    _fileName = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 2, bottom: 2),
                    child: Text(
                      "Accepted formats: Images, PDF (Max 5MB)",
                      style: GoogleFonts.poppins(
                        fontSize: minFont - 2,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 7, bottom: 2),
                    child: Text(
                      "Note (Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: minFont,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _noteCtrl,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          "Add any additional notes about this expense...",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: minFont - 1,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: minFont),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(68, 29),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: minFont - 1,
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 5),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            minimumSize: const Size(74, 29),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 7,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: minFont - 1,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(widget.isEdit ? "Update" : "Add Expense"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class ExpenseDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> expense;
  const ExpenseDetailsDialog({super.key, required this.expense});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = expense['invoice'];
    final expenseType = expense['expenseType'] ?? expense['type'] ?? "Expense";
    final amount = (expense['amount'] ?? 0).toString();
    final date = _formatDate(expense['date']);
    final paymentMode = expense['paymentMode'] ?? "N/A";
    final invoiceNo = expense['invoiceNo'] ?? "N/A";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: Container(
        width: 600.w,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side: Image preview
              Expanded(
                flex: 1,
                child: Container(
                  color: const Color(0xFFF3F4F6),
                  child: invoice != null && invoice.toString().isNotEmpty
                      ? _buildInvoicePreview(invoice.toString())
                      : _buildNoImage(),
                ),
              ),
              // Right side: Details
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "EXPENSE DETAILS",
                            style: GoogleFonts.poppins(
                              fontSize: 6.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 1.2,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, size: 18.sp),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            expenseType,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Amount",
                              style: GoogleFonts.poppins(
                                fontSize: 9.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "₹$amount",
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        "Transaction Date",
                        date,
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        Icons.payment_outlined,
                        "Payment Mode",
                        paymentMode,
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(Icons.tag, "Invoice No.", invoiceNo),
                      const Spacer(),
                      SizedBox(height: 16.h),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E7EB),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          child: Text(
                            "Close",
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicePreview(String invoice) {
    if (invoice.startsWith('http')) {
      return Image.network(
        invoice,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildNoImage(),
      );
    } else if (invoice.contains('base64,')) {
      try {
        return Image.memory(
          base64Decode(invoice.split('base64,').last),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildNoImage(),
        );
      } catch (e) {
        return _buildNoImage();
      }
    }
    return _buildNoImage();
  }

  Widget _buildNoImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 42.sp,
          color: Colors.grey[400],
        ),
        SizedBox(height: 10.h),
        Text(
          "No invoice image attached",
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 14.sp, color: Colors.grey[600]),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 7.sp,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
