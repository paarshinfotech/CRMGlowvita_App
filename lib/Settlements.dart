import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/custom_drawer.dart';

class SettlementsPage extends StatefulWidget {
  const SettlementsPage({super.key});

  @override
  State<SettlementsPage> createState() => _SettlementsPageState();
}

class _SettlementsPageState extends State<SettlementsPage> {
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  // Summary metrics
  final double totalPaidOut = 2700;
  final double totalPending = 200;
  final int vendorsWithPending = 3;
  final int totalTransactions = 15;

  // Table data
  final List<Map<String, dynamic>> rows = [
    {
      'salon': 'Glamour Salon',
      'contact': '9876543210',
      'owner': 'Rahul Sharma',
      'adminReceive': 1500.0,
      'adminPay': 1200.0,
      'pending': 300.0,
      'totalSettlement': 1500.0,
      'status': 'Paid',
    },
    {
      'salon': 'Modern Cuts',
      'contact': '8765432109',
      'owner': 'Priya Patel',
      'adminReceive': 2500.0,
      'adminPay': 2000.0,
      'pending': 500.0,
      'totalSettlement': 2500.0,
      'status': 'Pending',
    },
    {
      'salon': 'Style Lounge',
      'contact': '7654321098',
      'owner': 'Amit Singh',
      'adminReceive': 3200.0,
      'adminPay': 3000.0,
      'pending': 200.0,
      'totalSettlement': 3200.0,
      'status': 'Pending',
    },
  ];

  Color _statusColor(String s) {
    switch (s) {
      case 'Paid':
        return const Color(0xFF2E7D32);
      case 'Pending':
        return const Color(0xFFEF6C00);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String s) => _statusColor(s).withOpacity(0.15);

  // Demo data per vendor (replace with API)
  List<Map<String, dynamic>> _mockTransactionsFor(String salon) {
    if (salon == 'Glamour Salon') {
      return [
        {
          'title': 'Service Payment',
          'date': DateTime(2025, 8, 10),
          'amount': 500.0
        },
        {
          'title': 'Membership Fee',
          'date': DateTime(2025, 8, 5),
          'amount': 1000.0
        },
        {
          'title': 'Vendor Payout',
          'date': DateTime(2025, 8, 12),
          'amount': -1200.0
        },
      ];
    } else if (salon == 'Modern Cuts') {
      return [
        {
          'title': 'Package Sale',
          'date': DateTime(2025, 7, 28),
          'amount': 1500.0
        },
        {
          'title': 'Vendor Payout',
          'date': DateTime(2025, 7, 30),
          'amount': -1000.0
        },
        {'title': 'Adjustment', 'date': DateTime(2025, 8, 2), 'amount': -500.0},
      ];
    } else {
      return [
        {
          'title': 'Service Payment',
          'date': DateTime(2025, 8, 1),
          'amount': 800.0
        },
        {'title': 'Commission', 'date': DateTime(2025, 8, 3), 'amount': -300.0},
        {
          'title': 'Vendor Payout',
          'date': DateTime(2025, 8, 6),
          'amount': -200.0
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Settlements'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Settlements',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Metric cards
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              childAspectRatio: isMobile ? 1.5 : 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                _metricCard(
                  title: 'Total Paid Out',
                  value: currency.format(totalPaidOut),
                  subtitle: 'All-time paid to vendors',
                  icon: Icons.attach_money,
                  iconBg: Theme.of(context).primaryColor,
                ),
                _metricCard(
                  title: 'Total Pending',
                  value: currency.format(totalPending).replaceAll('.00', ''),
                  subtitle: 'Across all vendors',
                  icon: Icons.hourglass_bottom_rounded,
                  iconBg: Colors.amber.shade700,
                ),
                _metricCard(
                  title: 'Vendors with Pending',
                  value: vendorsWithPending.toString(),
                  subtitle: 'Vendors to be paid',
                  icon: Icons.group_outlined,
                  iconBg: Colors.purple,
                ),
                _metricCard(
                  title: 'Total Transactions',
                  value: totalTransactions.toString(),
                  subtitle: 'Total pay and receive entries',
                  icon: Icons.refresh_rounded,
                  iconBg: Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section header + Export
            _sectionHeader(
              title: 'Settlement Transactions',
              subtitle:
                  'Details of all settlements for online payments and platform fees.',
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined),
                label:
                    const Text('Export Report', style: TextStyle(fontSize: 10)),
              ),
            ),

            const SizedBox(height: 8),

            // Transactions list
            ListView.separated(
              itemCount: rows.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = rows[i];

                return Card(
                  elevation: 0.8,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Salon + status + action
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['salon'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r['owner'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Contact: ${r['contact']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _statusBg(r['status']),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                r['status'],
                                style: TextStyle(
                                  color: _statusColor(r['status']),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final txns = _mockTransactionsFor(r['salon']);
                                _showTransactionHistoryDialog(
                                  context,
                                  salonName: r['salon'],
                                  totalReceived: r['adminReceive'],
                                  totalPaid: r['adminPay'],
                                  pending: r['pending'],
                                  transactions: txns,
                                );
                              },
                              icon: Icon(Icons.visibility_outlined,
                                  color: Colors.grey.shade700),
                              tooltip: 'View',
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 10),

                        // Row 2: numbers grid
                        Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            _money('Admin Pay Amount (₹)', r['adminPay']),
                            _money('Pending Amount (₹)', r['pending']),
                            _money('Total Settlement (₹)', r['totalSettlement'],
                                emphasize: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// ----------- POPUP DIALOG -----------
  void _showTransactionHistoryDialog(
    BuildContext context, {
    required String salonName,
    required double totalReceived,
    required double totalPaid,
    required double pending,
    required List<Map<String, dynamic>> transactions,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final f = currency;

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$salonName - Transaction History',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Top summary chips - centered, pending on next line
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // First line: Total Received & Total Paid centered
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _summaryPill(
                              title: 'Total Received',
                              value: f.format(totalReceived),
                              bg: const Color(0xFFEAF7EF),
                            ),
                            const SizedBox(width: 8),
                            _summaryPill(
                              title: 'Total Paid',
                              value: f.format(totalPaid),
                              bg: const Color(0xFFEAF0FF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Horizontal card for Pending Amount
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6DD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6E6E6)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Amount',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    f.format(pending).replaceAll('.00', ''),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _showReceivePaymentDialog(ctx, pending);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                        color: Color(0xFFE6E6E6)),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Receive',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Transaction Details',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    // Transactions list in dialog
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          itemCount: transactions.length,
                          shrinkWrap: true,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = transactions[i];
                            final num amount = t['amount'] as num;
                            final date = t['date'] as DateTime;
                            final isCredit = amount >= 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFEAEAEA)),
                              ),
                              child: ListTile(
                                title: Text(
                                  t['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('d MMM yyyy').format(date),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  '${isCredit ? '+' : ''}${f.format(amount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isCredit
                                        ? const Color(0xFF1B5E20)
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReceivePaymentDialog(BuildContext context, double maxPending) {
    final TextEditingController amountController = TextEditingController();
    final f = currency; // reuse your NumberFormat

    // Function to validate and limit input to maxPending amount
    void _validateAmountInput() {
      final text = amountController.text;
      if (text.isNotEmpty) {
        final entered = double.tryParse(text);
        if (entered != null && entered > maxPending) {
          // Truncate to maxPending if exceeded
          amountController.value = TextEditingValue(
            text: maxPending.toStringAsFixed(2),
            selection: TextSelection.collapsed(
                offset: maxPending.toStringAsFixed(2).length),
          );
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: title + close
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Receive Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Amount label + field
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Amount (₹)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: TextField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                signed: false,
                                decimal: true,
                              ),
                              onChanged: (value) => _validateAmountInput(),
                              decoration: InputDecoration(
                                hintText: 'Max: ${f.format(maxPending)}',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                // Up/Down arrows on the right (visual only)
                                suffixIcon: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.arrow_drop_up, size: 16),
                                    Icon(Icons.arrow_drop_down, size: 16),
                                  ],
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCED4DA),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: validate and submit amount
                            // final entered = double.tryParse(amountController.text) ?? 0;
                            Navigator.pop(ctx); // close dialog after handling
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Receive',
                              style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
      },
    );
  }

// ---------- small helpers ----------

  Widget _summaryPill({
    required String title,
    required String value,
    required Color bg,
    Widget? trailing,
  }) {
    return SizedBox(
      width: 170, // keep same width so centering looks even
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
  }) {
    return Card(
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconBg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              ],
            ),
          ),
          // Export button
          SizedBox(height: 40, child: trailing),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return _cell(
      title: k,
      child: Text(
        v,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _money(String k, double v, {bool emphasize = false}) {
    return _cell(
      title: k,
      child: Text(
        currency.format(v),
        style: TextStyle(
          fontSize: emphasize ? 14 : 13,
          fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          color: emphasize ? Colors.black : Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _cell({required String title, required Widget child}) {
    return SizedBox(
      width: 170, // keeps a tidy wrap on mobile
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
