import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supp_drawer.dart'; 

class SuppExpensesPage extends StatefulWidget {
  const SuppExpensesPage({super.key});

  @override
  State<SuppExpensesPage> createState() => _SuppExpensesPageState();
}

class _SuppExpensesPageState extends State<SuppExpensesPage> {
  static const double _radius = 14, _gap = 15;

  // Supplier-specific expense types and sample data
  final List<Map<String, dynamic>> expenses = [
    {
      'id': 'EXP-101',
      'type': 'Product Packaging',
      'date': '2025-12-20',
      'amount': 450.0,
      'paymentMode': 'UPI',
      'invoiceNo': 'INV-2101',
      'note': 'Custom boxes for serum bottles',
    },
    {
      'id': 'EXP-102',
      'type': 'Raw Materials',
      'date': '2025-12-18',
      'amount': 12500.0,
      'paymentMode': 'Net Banking',
      'invoiceNo': 'INV-2102',
      'note': 'Bulk purchase of hyaluronic acid & vitamin C',
    },
    {
      'id': 'EXP-103',
      'type': 'Marketing & Ads',
      'date': '2025-12-15',
      'amount': 8900.0,
      'paymentMode': 'Debit Card',
      'invoiceNo': 'INV-2103',
      'note': 'Social media ads for new product launch',
    },
    {
      'id': 'EXP-104',
      'type': 'Shipping Supplies',
      'date': '2025-12-12',
      'amount': 1200.0,
      'paymentMode': 'Cash',
      'invoiceNo': 'INV-2104',
      'note': 'Bubble wrap and courier bags',
    },
    {
      'id': 'EXP-105',
      'type': 'Lab Testing',
      'date': '2025-12-10',
      'amount': 3500.0,
      'paymentMode': 'UPI',
      'invoiceNo': 'INV-2105',
      'note': 'Quality testing for new cream batch',
    },
    {
      'id': 'EXP-106',
      'type': 'Utilities',
      'date': '2025-12-05',
      'amount': 2800.0,
      'paymentMode': 'Net Banking',
      'invoiceNo': 'INV-2106',
      'note': 'Electricity bill for production unit',
    },
  ];

  String _searchQuery = '';
  String _selectedPaymentMode = 'All Payment Modes';
  DateTime? _startDate, _endDate;
  double? _minAmount = 0, _maxAmount;
  final TextEditingController _searchController = TextEditingController();

  int get totalRecords => expenses.length;
  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + (e['amount'] as num? ?? 0));
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

  List<Map<String, dynamic>> get filteredExpenses {
    return expenses.where((expense) {
      final matchesSearch = _searchQuery.isEmpty ||
          (expense['id']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (expense['type']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (expense['note']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesPaymentMode = _selectedPaymentMode == 'All Payment Modes' ||
          expense['paymentMode'] == _selectedPaymentMode;

      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        try {
          final dt = DateTime.parse(expense['date']);
          if (_startDate != null && dt.isBefore(_startDate!)) matchesDateRange = false;
          if (_endDate != null && dt.isAfter(_endDate!)) matchesDateRange = false;
        } catch (_) {}
      }

      final minAmt = _minAmount ?? 0;
      final maxAmt = _maxAmount ?? double.infinity;
      final matchesAmount = (expense['amount'] as num? ?? 0) >= minAmt &&
          (expense['amount'] as num? ?? 0) <= maxAmt;

      return matchesSearch && matchesPaymentMode && matchesDateRange && matchesAmount;
    }).toList();
  }

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
    await showDialog(
      context: context,
      builder: (_) => SuppAddExpenseDialog(),
    );
  }

  void _deleteExpense(String id) {
    setState(() {
      expenses.removeWhere((e) => e['id'] == id);
    });
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Expense', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this expense?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(
            onPressed: () {
              _deleteExpense(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Expenses",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(_gap),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Track and manage your business expenses related to product supply",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(child: _InfoCard(title: 'Total Expenses', value: '₹${totalExpenses.toStringAsFixed(0)}', subtitle: 'All-time business expenses')),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(title: 'This Month', value: '₹$currentMonthExpenses', subtitle: 'Current month spending')),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(title: 'Total Records', value: '$totalRecords', subtitle: 'Total expense entries')),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_radius), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('My Business Expenses', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Track costs for raw materials, packaging, marketing, and more', style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600)),
                    ]),
                  ),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)), child: Text('$totalRecords', style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 11))),
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
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: _searchQuery.isEmpty ? null : IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: Container(height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_radius), border: Border.all(color: Colors.grey.shade300)), child: IconButton(icon: const Icon(Icons.filter_list, color: Colors.black87, size: 18), onPressed: _openFilterDialog))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: Text("Export", style: GoogleFonts.poppins(fontSize: 13)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 13),
                ElevatedButton.icon(
                  onPressed: _openAddExpenseDialog,
                  icon: const Icon(Icons.add, size: 17),
                  label: Text("Add Expense", style: GoogleFonts.poppins(fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Expanded(
              child: filteredExpenses.isEmpty
                  ? Center(child: Text('No expenses found', style: GoogleFonts.poppins(fontSize: 13)))
                  : ListView.builder(
                      itemCount: filteredExpenses.length,
                      itemBuilder: (_, i) => SuppExpenseCard(
                        expense: filteredExpenses[i],
                        onView: () {},
                        onDelete: () => _confirmDelete(filteredExpenses[i]['id']),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuppExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  const SuppExpenseCard({super.key, required this.expense, this.onView, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("#${expense['id']}", style: GoogleFonts.poppins(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(expense['date'], style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 9)),
                    ],
                  ),
                ),
                Text("₹${expense['amount']}", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text(expense['type'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(expense['paymentMode'], style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text("Invoice: ${expense['invoiceNo']}", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
            if (expense['note']?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(expense['note'], style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]), overflow: TextOverflow.ellipsis, maxLines: 2),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onView, child: Text("View", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12))),
                const SizedBox(width: 8),
                TextButton(onPressed: onDelete, child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, value, subtitle;
  const _InfoCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500])),
      ]),
    );
  }
}

// New simplified Add Expense Dialog for Supplier
class SuppAddExpenseDialog extends StatefulWidget {
  const SuppAddExpenseDialog({super.key});

  @override
  State<SuppAddExpenseDialog> createState() => _SuppAddExpenseDialogState();
}

class _SuppAddExpenseDialogState extends State<SuppAddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  String? _selectedPaymentMode;
  final _invoiceController = TextEditingController();
  final _noteController = TextEditingController();

  final List<String> _expenseTypes = [
    'Raw Materials',
    'Product Packaging',
    'Shipping Supplies',
    'Marketing & Ads',
    'Lab Testing',
    'Utilities',
    'Equipment',
    'Software Subscriptions',
    'Insurance',
    'Rent',
    'Travel',
    'Office Supplies',
  ];

  final List<String> _paymentModes = ['Cash', 'UPI', 'Debit Card', 'Net Banking'];

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Expense', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(labelText: 'Expense Type *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: _expenseTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: 'Date *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMode,
                  decoration: InputDecoration(labelText: 'Payment Mode *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: _paymentModes.map((mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
                  onChanged: (v) => setState(() => _selectedPaymentMode = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _invoiceController,
                  decoration: InputDecoration(labelText: 'Invoice Number (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Add expense logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added successfully')));
            }
          },
          child: Text('Add Expense', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}

// Filter dialog remains the same (you can keep the original one)
class FilterOptionsDialog extends StatefulWidget {
  final String paymentMode;
  final DateTime? fromDate, toDate;
  final double? minAmount, maxAmount;
  const FilterOptionsDialog({Key? key, this.paymentMode = 'All Payment Modes', this.fromDate, this.toDate, this.minAmount, this.maxAmount}) : super(key: key);
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
    _minAmountCtrl = TextEditingController(text: widget.minAmount?.toString() ?? "0");
    _maxAmountCtrl = TextEditingController(text: widget.maxAmount?.toString() ?? "");
  }

  @override
  void dispose() {
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) => dt == null ? 'dd-mm-yyyy' : "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Filter Options", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedPaymentMode,
                decoration: InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                items: ['All Payment Modes', 'Cash', 'UPI', 'Debit Card', 'Net Banking']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaymentMode = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: InkWell(onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _fromDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
                    if (picked != null) setState(() => _fromDate = picked);
                  }, child: InputDecorator(decoration: InputDecoration(labelText: 'From Date', border: OutlineInputBorder()), child: Text(_formatDate(_fromDate))))),
                  const SizedBox(width: 8),
                  Expanded(child: InkWell(onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _toDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
                    if (picked != null) setState(() => _toDate = picked);
                  }, child: InputDecorator(decoration: InputDecoration(labelText: 'To Date', border: OutlineInputBorder()), child: Text(_formatDate(_toDate))))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _minAmountCtrl, decoration: InputDecoration(labelText: 'Min Amount (₹)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _maxAmountCtrl, decoration: InputDecoration(labelText: 'Max Amount (₹)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        TextButton(onPressed: () {
          setState(() {
            _selectedPaymentMode = 'All Payment Modes';
            _fromDate = null;
            _toDate = null;
            _minAmountCtrl.text = "0";
            _maxAmountCtrl.clear();
          });
        }, child: Text('Reset')),
        ElevatedButton(onPressed: () {
          Navigator.pop(context, {
            "paymentMode": _selectedPaymentMode,
            "fromDate": _fromDate,
            "toDate": _toDate,
            "minAmount": double.tryParse(_minAmountCtrl.text) ?? 0,
            "maxAmount": double.tryParse(_maxAmountCtrl.text),
          });
        }, child: Text('Apply')),
      ],
    );
  }
}