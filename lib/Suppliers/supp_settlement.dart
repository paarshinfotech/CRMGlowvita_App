import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supp_drawer.dart';

class SuppSettlementsPage extends StatefulWidget {
  const SuppSettlementsPage({super.key});

  @override
  State<SuppSettlementsPage> createState() => _SuppSettlementsPageState();
}

class _SuppSettlementsPageState extends State<SuppSettlementsPage> {
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  // Supplier-focused metrics
  final double totalPaidOut = 16200.0; // Amount received by supplier
  final double totalPending = 2250.0; // Amount platform still owes
  final int vendorsWithPending = 1; // Only one "vendor" = the platform
  final int totalTransactions = 18; // Total settlement entries

  // Settlement rows (platform = GlowVita)
  final List<Map<String, dynamic>> rows = [
    {
      'salon': 'GlowVita Platform',
      'contact': 'support@glowvita.com',
      'owner': 'Platform Admin',
      'adminReceive': 9850.0, // Gross sales
      'adminPay': 8372.5, // Net paid to supplier
      'pending': 1477.5, // Commission deducted
      'totalSettlement': 9850.0,
      'status': 'Paid',
    },
    {
      'salon': 'GlowVita Platform',
      'contact': 'support@glowvita.com',
      'owner': 'Platform Admin',
      'adminReceive': 7200.0,
      'adminPay': 6120.0,
      'pending': 1080.0,
      'totalSettlement': 7200.0,
      'status': 'Paid',
    },
    {
      'salon': 'GlowVita Platform',
      'contact': 'support@glowvita.com',
      'owner': 'Platform Admin',
      'adminReceive': 5400.0,
      'adminPay': 4590.0,
      'pending': 810.0,
      'totalSettlement': 5400.0,
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

  // Mock transaction history for each settlement period
  List<Map<String, dynamic>> _mockTransactionsFor(String salon) {
    if (salon == 'GlowVita Platform') {
      // First settlement
      if (rows[0]['status'] == 'Paid') {
        return [
          {
            'title': 'Product Sales (18 orders)',
            'date': DateTime(2025, 12, 15),
            'amount': 9850.0
          },
          {
            'title': 'Platform Commission (15%)',
            'date': DateTime(2025, 12, 18),
            'amount': -1477.5
          },
          {
            'title': 'Settlement Payout',
            'date': DateTime(2025, 12, 18),
            'amount': 8372.5
          },
        ];
      }
      // Second settlement
      if (rows[1]['status'] == 'Paid') {
        return [
          {
            'title': 'Product Sales (15 orders)',
            'date': DateTime(2025, 11, 30),
            'amount': 7200.0
          },
          {
            'title': 'Platform Commission (15%)',
            'date': DateTime(2025, 12, 5),
            'amount': -1080.0
          },
          {
            'title': 'Settlement Payout',
            'date': DateTime(2025, 12, 5),
            'amount': 6120.0
          },
        ];
      }
      // Pending settlement
      return [
        {
          'title': 'Product Sales (15 orders)',
          'date': DateTime(2025, 12, 20),
          'amount': 5400.0
        },
        {
          'title': 'Platform Commission (15%)',
          'date': DateTime(2025, 12, 20),
          'amount': -810.0
        },
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Settlements'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text(
          'Settlements',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontSize: 18,
          ),
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
                  title: 'Total Received',
                  value: currency.format(totalPaidOut),
                  subtitle: 'All-time payouts received',
                  icon: Icons.account_balance_wallet,
                  iconBg: Theme.of(context).primaryColor,
                ),
                _metricCard(
                  title: 'Total Pending',
                  value: currency.format(totalPending).replaceAll('.00', ''),
                  subtitle: 'Awaiting payout',
                  icon: Icons.hourglass_bottom_rounded,
                  iconBg: Colors.amber.shade700,
                ),
                _metricCard(
                  title: 'Pending Periods',
                  value: vendorsWithPending.toString(),
                  subtitle: 'Settlement periods pending',
                  icon: Icons.schedule,
                  iconBg: Colors.purple,
                ),
                _metricCard(
                  title: 'Total Transactions',
                  value: totalTransactions.toString(),
                  subtitle: 'Sales & payout entries',
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
                  'Details of your product sales settlements and platform payouts.',
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
                        // Row 1: Platform + status + action
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
                              tooltip: 'View Details',
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
                            _money('Gross Sales (₹)', r['adminReceive']),
                            _money('Commission Deducted (₹)', r['pending'],
                                emphasize: false),
                            _money('Net Payout Received (₹)', r['adminPay'],
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

  // ----------- POPUP DIALOG (Adapted for Supplier view) -----------
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
                            '$salonName - Settlement Details',
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

                    // Summary
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _summaryPill(
                              title: 'Gross Sales',
                              value: f.format(totalReceived),
                              bg: const Color(0xFFEAF7EF),
                            ),
                            const SizedBox(width: 8),
                            _summaryPill(
                              title: 'Net Payout',
                              value: f.format(totalPaid),
                              bg: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6DD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6E6E6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Platform Commission (15%)',
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

                    // Transactions list
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
                                        : const Color(0xFF0D47A1),
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

  // No "Receive Payment" button for supplier — they wait for platform payout
  // Removed _showReceivePaymentDialog as it's not applicable

  // ---------- small helpers ----------
  Widget _summaryPill({
    required String title,
    required String value,
    required Color bg,
    Widget? trailing,
  }) {
    return SizedBox(
      width: 170,
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
          SizedBox(height: 40, child: trailing),
        ],
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
      width: 170,
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
