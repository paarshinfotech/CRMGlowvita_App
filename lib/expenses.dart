import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  static const double _radius = 14, _gap = 15;

  // Sample, start with at least one so user sees structure
  final List<Map<String, dynamic>> expenses = [
    {
      'id': 'EXP-001',
      'type': 'Office Supplies',
      'date': '2025-11-22',
      'amount': 150.0,
      'paymentMode': 'Debit Card',
      'invoiceNo': 'INV-001',
      'note': 'Purchased stationery items',
    },
  ];

  String _searchQuery = '';
  String _selectedPaymentMode = 'All Payment Modes';
  DateTime? _startDate, _endDate;
  double? _minAmount = 0, _maxAmount;
  final TextEditingController _searchController = TextEditingController();

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
          } catch (_) { return false;}
        })
        .fold(0, (sum, e) => sum + (e['amount'] as num? ?? 0).toInt());
  }

  List<Map<String, dynamic>> get filteredExpenses => expenses.where((expense) {
    final matchesSearch = _searchQuery.isEmpty
        || (expense['id']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        || (expense['type']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        || (expense['note']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    final matchesPaymentMode =
      _selectedPaymentMode == 'All Payment Modes'
      || expense['paymentMode'] == _selectedPaymentMode;
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
    final matchesAmount = (expense['amount'] as num? ?? 0) >= minAmt
        && (expense['amount'] as num? ?? 0) <= maxAmt;
    return matchesSearch && matchesPaymentMode && matchesDateRange && matchesAmount;
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
    await showDialog(
      context: context,
      builder: (_) => AddExpenseDialog(invoiceNumber: 'INV-001'),
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
      drawer: const CustomDrawer(currentPage: 'Expenses'),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Expenses",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
          ),
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
              child: Text("Track and manage all your expenses in one place",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(child: _InfoCard(title: 'Total Expenses', value: '₹${totalExpenses.toStringAsFixed(0)}', subtitle: 'All-time expenses', fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(title: 'This Month', value: '₹$currentMonthExpenses', subtitle: 'Current month expenses', fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(child: _InfoCard(title: 'Total Records', value: '$totalRecords', subtitle: 'Total expense entries', fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All Expenses', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('View, add, and manage your personal expenses', style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$totalRecords', style: GoogleFonts.poppins(
                          color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 11)),
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
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: _searchQuery.isEmpty ? null
                        : IconButton(icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            }),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                      icon: const Icon(Icons.filter_list, color: Colors.black87, size: 18),
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
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: Text("Export", style: GoogleFonts.poppins(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  label: Text("Add Expense", style: GoogleFonts.poppins(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(0, 33),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Expanded(
              child: filteredExpenses.isEmpty
                  ? Center(child: Text('No expenses found', style: GoogleFonts.poppins(fontSize: 13)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 11, top: 3),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (ctx, idx) => ExpenseCard(
                        expense: filteredExpenses[idx],
                        onView: () {},
                        onDelete: () {},
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback? onView;
  final VoidCallback? onDelete;
  final double fontSize;
  const ExpenseCard({super.key, required this.expense, this.onView, this.onDelete, this.fontSize = 13});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("#${expense['id'] ?? ''}",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2563EB), fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline, fontSize: fontSize - 2),
                    ),
                    const SizedBox(height: 2),
                    Text(expense['date'] ?? "",
                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: fontSize - 5),
                    ),
                  ],
                ),
              ),
              Text("₹${expense['amount'] ?? ''}",
                style: GoogleFonts.poppins(
                  color: Colors.black, fontWeight: FontWeight.w600, fontSize: fontSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense['type'] ?? "",
                      style: GoogleFonts.poppins(
                        color: Colors.black, fontWeight: FontWeight.w500, fontSize: fontSize - 2),
                    ),
                    const SizedBox(height: 2),
                    Text(expense['paymentMode'] ?? "",
                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: fontSize - 4),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Invoice: ${expense['invoiceNo'] ?? ''}",
                      style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: fontSize - 4),
                    ),
                    const SizedBox(height: 2),
                    Text(expense['note'] ?? "",
                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: fontSize - 5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(textStyle: GoogleFonts.poppins(fontSize: fontSize - 4)),
                child: Text("View", style: GoogleFonts.poppins(color: Colors.blue, fontSize: fontSize - 4, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(textStyle: GoogleFonts.poppins(fontSize: fontSize - 4)),
                child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red, fontSize: fontSize - 4, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String title, value, subtitle;
  final double fontSize;
  const _InfoCard({required this.title, required this.value, required this.subtitle, this.fontSize = 12});
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
        Text(title, style: GoogleFonts.poppins(fontSize: fontSize - 3, fontWeight: FontWeight.w500, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: fontSize + 3, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 1),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: fontSize - 4, color: Colors.grey[500])),
      ],
    ),
  );
}

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
  void dispose() { _minAmountCtrl.dispose(); _maxAmountCtrl.dispose(); super.dispose();}
  String _formatDate(DateTime? dt) => dt == null ? 'dd-mm-yyyy' : "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
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
              Text("Filter Options", style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: fontSize,
              )),
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
                              Text("Payment Mode", style: GoogleFonts.poppins(fontSize: fontSize-2, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _selectedPaymentMode,
                                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                                  style: GoogleFonts.poppins(fontSize: fontSize-1, color: Colors.black87),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
                                    ),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  items: ['All Payment Modes', 'Cash', 'Debit Card', 'Net Banking']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins(fontSize: fontSize-1))))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedPaymentMode = v ?? "All Payment Modes"),
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
                              Text("From Date", style: GoogleFonts.poppins(fontSize: fontSize-2, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _fromDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) setState(() => _fromDate = picked);
                                },
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFDEDEDE)),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 9),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(_formatDate(_fromDate),
                                            style: GoogleFonts.poppins(fontSize: fontSize-1, color: _fromDate == null ? Colors.grey[500] : Colors.black)),
                                      ),
                                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[500]),
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
                              Text("To Date", style: GoogleFonts.poppins(fontSize: fontSize-2, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _toDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) setState(() => _toDate = picked);
                                },
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFDEDEDE)),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 9),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(_formatDate(_toDate),
                                            style: GoogleFonts.poppins(fontSize: fontSize-1, color: _toDate == null ? Colors.grey[500] : Colors.black)),
                                      ),
                                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[500]),
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
                              Text("Min Amount (₹)", style: GoogleFonts.poppins(fontSize: fontSize-2, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                child: TextFormField(
                                  controller: _minAmountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    hintStyle: GoogleFonts.poppins(fontSize: fontSize-3, color: Colors.grey[500]),
                                    filled: true, fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: fontSize-1),
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
                              Text("Max Amount (₹)", style: GoogleFonts.poppins(fontSize: fontSize-2, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 38,
                                child: TextFormField(
                                  controller: _maxAmountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "No limit",
                                    hintStyle: GoogleFonts.poppins(fontSize: fontSize-3, color: Colors.grey[500]),
                                    filled: true, fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: fontSize-1),
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
                    child: Text("Reset", style: GoogleFonts.poppins(fontSize: fontSize-1)),
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
                      foregroundColor: Colors.white, backgroundColor: Colors.blue,
                      textStyle: GoogleFonts.poppins(fontSize: fontSize, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Apply'),
                    onPressed: () {
                      Navigator.pop(context, {
                        "paymentMode": _selectedPaymentMode,
                        "fromDate": _fromDate,
                        "toDate": _toDate,
                        "minAmount": double.tryParse(_minAmountCtrl.text.trim()) ?? 0,
                        "maxAmount": double.tryParse(_maxAmountCtrl.text.trim()) ?? null,
                      });
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final List<String> expenseTypes;
  final List<String> paymentModes;
  final String? invoiceNumber;
  final DateTime? initialDate;

  const AddExpenseDialog({
    Key? key,
    this.expenseTypes = const [
      "Office Supplies", "Travel", "Marketing", "Utilities", "Maintenance",
      "Salaries", "Rent", "Insurance", "Training", "Software", "Meals", "Equipment"
    ],
    this.paymentModes = const [ "Cash", "Debit Card", "Net Banking" ],
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

  @override
  void initState() {
    super.initState();
    _invoiceCtrl.text = widget.invoiceNumber ?? "";
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final minFont = 11.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add New Expense", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 2),
                child: Text("Fill in the details to add a new expense", style: GoogleFonts.poppins(fontSize: minFont, color: Colors.grey[600])),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: RichText(
                  text: TextSpan(
                    text: "Expense Type ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: minFont, color: Colors.black),
                    children: [ TextSpan(text: "*", style: TextStyle(color: Colors.red, fontSize: minFont)), ],
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _expenseType,
                onChanged: (v) => setState(() => _expenseType = v),
                items: widget.expenseTypes.map((e) => DropdownMenuItem(
                  value: e, child: Text(e, style: GoogleFonts.poppins(fontSize: minFont))
                )).toList(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Select expense type",
                  hintStyle: GoogleFonts.poppins(fontSize: minFont, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                ),
                style: GoogleFonts.poppins(fontSize: minFont, color: Colors.black),
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
                            text: TextSpan(text: "Date ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: minFont, color: Colors.black), children: [TextSpan(text: "*", style: TextStyle(color: Colors.red, fontSize: minFont))]),
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
                              if (date != null) setState(() => _selectedDate = date);
                            },
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Expanded(child: Text("${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year}", style: GoogleFonts.poppins(fontSize: minFont))),
                                  Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 14),
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
                            text: TextSpan(text: "Amount (₹) ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: minFont, color: Colors.black), children: [TextSpan(text: "*", style: TextStyle(color: Colors.red, fontSize: minFont))]),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 32,
                            child: TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: GoogleFonts.poppins(fontSize: minFont, color: Colors.grey),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade400)),
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
                    text: "Payment Mode ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: minFont, color: Colors.black),
                    children: [TextSpan(text: "*", style: TextStyle(color: Colors.red, fontSize: minFont))],
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _paymentMode,
                onChanged: (v) => setState(() => _paymentMode = v),
                items: widget.paymentModes.map((e) => DropdownMenuItem(
                  value: e, child: Text(e, style: GoogleFonts.poppins(fontSize: minFont)),
                )).toList(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Select payment mode",
                  hintStyle: GoogleFonts.poppins(fontSize: minFont, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                ),
                style: GoogleFonts.poppins(fontSize: minFont, color: Colors.black),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text("Invoice Number (Optional)", style: GoogleFonts.poppins(fontSize: minFont, fontWeight: FontWeight.w500)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: TextFormField(
                  controller: _invoiceCtrl,
                  decoration: InputDecoration(
                    hintText: 'INV-001',
                    hintStyle: GoogleFonts.poppins(fontSize: minFont, color: Colors.grey),
                    filled: true, fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade400)),
                  ),
                  style: GoogleFonts.poppins(fontSize: minFont),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9, bottom: 3),
                child: Text("Expense Invoice (Optional)", style: GoogleFonts.poppins(fontSize: minFont, fontWeight: FontWeight.w500)),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () { setState(() => _fileName = "No file chosen"); },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: const Color(0xFFE8EAF1), elevation: 0,
                      minimumSize: const Size(0, 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: BorderSide(color: Colors.grey.shade400)),
                    ),
                    child: Text("Choose File", style: GoogleFonts.poppins(fontSize: minFont, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 7),
                  Flexible(child: Text(_fileName ?? "No file chosen", style: GoogleFonts.poppins(fontSize: minFont-1, color: Colors.grey[700]))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 2, bottom: 2),
                child: Text("Accepted formats: Images, PDF (Max 5MB)", style: GoogleFonts.poppins(fontSize: minFont-2, color: Colors.grey[600])),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 7, bottom: 2),
                child: Text("Note (Optional)", style: GoogleFonts.poppins(fontSize: minFont, fontWeight: FontWeight.w500)),
              ),
              TextFormField(
                controller: _noteCtrl,
                minLines: 2, maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Add any additional notes about this expense...",
                  hintStyle: GoogleFonts.poppins(fontSize: minFont-1, color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade400)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        textStyle: GoogleFonts.poppins(fontSize: minFont-1),
                      ),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () { Navigator.of(context).pop(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(74, 29),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                        textStyle: GoogleFonts.poppins(fontSize: minFont-1, fontWeight: FontWeight.w500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      child: const Text("Add Expense"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
