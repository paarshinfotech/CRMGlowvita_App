import 'package:flutter/material.dart';
import 'package:glowvita/billing_invoice_model.dart';
import 'package:glowvita/widgets/collect_payment_dialog.dart';
import 'package:glowvita/widgets/create_appointment_form.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../addon_model.dart';
import '../appointment_model.dart';
import '../services/api_service.dart';
import '../utils/string_extensions.dart';
import '../invoice_management.dart';

class AppointmentDetailDialog extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailDialog({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailDialog> createState() =>
      _AppointmentDetailDialogState();
}

class _AppointmentDetailDialogState extends State<AppointmentDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppointmentModel? _appointment;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  final List<String> _statusOptions = [
    'Confirm Appointment',
    'Complete without Payment',
    'Cancel Appointment',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('🎯 AppointmentDetailDialog opened with ID: ${widget.appointmentId}');
    _fetchAppointmentDetails();
  }

  Future<void> _fetchAppointmentDetails() async {
    try {
      print('⏳ Fetching details for appointment: ${widget.appointmentId}');
      final appointment =
          await ApiService.getAppointmentById(widget.appointmentId);
      print(
          '✨ Successfully loaded appointment: ${appointment.id} - ${appointment.clientName}');
      setState(() {
        _appointment = appointment;
        _isLoading = false;
      });
    } catch (e) {
      print('⚠️ Failed to load appointment details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 20),
              Text('Loading...', style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
      );
    }

    if (_appointment == null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error', style: TextStyle(fontSize: 18)),
        content: const Text('Could not load appointment details.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final date = _appointment!.date ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);

    // Determine Service Name Display
    String displayServiceName = _appointment?.serviceName ?? '—';
    if (_appointment?.isWeddingService == true &&
        _appointment?.weddingPackageDetails != null) {
      displayServiceName =
          _appointment!.weddingPackageDetails!.packageName ?? 'Wedding Package';
    } else if (_appointment?.isMultiService == true) {
      displayServiceName = 'Multi-Service';
    }

    final status = _appointment?.status?.toLowerCase() ?? '';
    final isCancelled = status.contains('cancelled');

    // An appointment is considered completed if:
    // 1. Status explicitly contains "completed"
    // 2. Status explicitly contains "paid" or "collected" or "success"
    // 3. Amount is fully paid (amountPaid >= totalAmount)
    final double totalAmount =
        _appointment?.totalAmount ?? _appointment?.amount ?? 0;
    final double amountPaid = _appointment?.amountPaid ?? 0;
    final bool isPaidFull = totalAmount > 0 && amountPaid >= totalAmount;

    final isCompleted = status.contains('completed') ||
        status.contains('paid') ||
        status.contains('collected') ||
        status.contains('success') ||
        isPaidFull;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Appointment Details',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${_appointment?.clientName ?? "Client"} • ${DateFormat('MMM d, yyyy').format(date)} • ${_appointment?.startTime ?? ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Colors.grey),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey.shade800,
            labelStyle: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w500),
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(vertical: 6),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 15),
                    const SizedBox(width: 6),
                    const Text('Details'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 15),
                    const SizedBox(width: 6),
                    const Text('Client History'),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('4',
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 1, thickness: 1, color: Colors.grey),

          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons Row (Top)
                  if (!isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          if (!isCancelled) ...[
                            Expanded(
                              child: _outlinedActionButton(
                                  Icons.payments_outlined, 'Collect Payment',
                                  onTap: () {
                                _showCollectPaymentDialog();
                              }),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: _outlinedActionButton(
                                Icons.calendar_month_rounded, 'Reschedule',
                                onTap: () {
                              if (_appointment == null) return;
                              showDialog(
                                context: context,
                                builder: (context) => CreateAppointmentForm(
                                  existingAppointment: _appointment,
                                ),
                              ).then((_) => _fetchAppointmentDetails());
                            }),
                          ),
                        ],
                      ),
                    )
                  else if (!isCancelled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _outlinedActionButton(
                                Icons.receipt_long_outlined, 'View Invoice',
                                onTap: () {
                              // _showInvoice();
                            }),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Status Dropdown on its own line
                  _statusDropdown(_appointment?.status ?? 'Scheduled'),

                  const SizedBox(height: 12),

                  // Payment History
                  _paymentHistorySection(),

                  const SizedBox(height: 16),

                  // Info Cards
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _infoCard(Icons.person_outline_rounded, 'CLIENT',
                                _appointment?.clientName ?? '—'),
                            const SizedBox(height: 10),
                            _serviceCard(),
                            const SizedBox(height: 10),
                            _infoCard(Icons.people_outline_rounded, 'STAFF',
                                _appointment?.staffName ?? '—'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            _infoCard(
                              Icons.calendar_today_outlined,
                              'DATE & TIME',
                              DateFormat('EEEE, MMMM d, yyyy').format(date),
                              subtitle:
                                  '${_appointment?.startTime ?? ''} - ${_appointment?.endTime ?? ''} (${_appointment?.duration ?? '?'} min)',
                              iconData: Icons.access_time_rounded,
                            ),
                            const SizedBox(height: 10),
                            _statusCard(_appointment?.status ?? 'Scheduled'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_appointment?.notes != null &&
                      _appointment!.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes / Cancellation Reason:',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _appointment!.notes!,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1, color: Colors.black),
                  const SizedBox(height: 16),

                  // Payment Details Summary
                  Text(
                    'Payment Details',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  _paymentDetailRow(
                      'Service Amount:', _appointment?.amount ?? 0),
                  _paymentDetailRow(
                      'Add-on Amount:', _appointment?.addOnsAmount ?? 0),
                  _paymentDetailRow(
                      'Service Tax (GST):', _appointment?.serviceTax ?? 0),
                  _paymentDetailRow(
                      'Platform Fee:', _appointment?.platformFee ?? 0),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child:
                        Divider(height: 1, thickness: 1, color: Colors.black12),
                  ),
                  _paymentDetailRow(
                      'Total Amount:',
                      _appointment?.finalAmount ??
                          _appointment?.totalAmount ??
                          _appointment?.amount ??
                          0,
                      bold: true),
                  _paymentDetailRow(
                      'Amount Paid:', _appointment?.amountPaid ?? 0),
                  _paymentDetailRow(
                      'Amount Remaining:', _appointment?.amountRemaining ?? 0,
                      color: Colors.red.shade800, bold: true),
                  _paymentDetailRow('Payment Status:', 0,
                      isStatusText: true,
                      status: _getPaymentStatusText(_appointment!)),

                  const SizedBox(height: 20),

                  // Bottom Close Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 0),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlinedActionButton(IconData icon, String label,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdown(String currentStatus) {
    Color color;
    switch (currentStatus.toLowerCase()) {
      case 'scheduled':
        color = Colors.green.shade700;
        break;
      case 'confirmed':
        color = Theme.of(context).primaryColor;
        break;
      case 'cancelled':
        color = Colors.red.shade700;
        break;
      case 'completed':
        color = Theme.of(context).primaryColor;
        break;
      case 'completed_without_payment':
      case 'completed (no pay)':
        color = Theme.of(context).primaryColor.withOpacity(0.7);
        break;
      case 'in_progress':
        color = Colors.orange.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }

    final double totalAmount =
        _appointment?.totalAmount ?? _appointment?.amount ?? 0;
    final double amountPaid = _appointment?.amountPaid ?? 0;
    final bool isPaidFull = totalAmount > 0 && amountPaid >= totalAmount;

    final bool isCompleted =
        currentStatus.toLowerCase().contains('completed') ||
            currentStatus.toLowerCase().contains('paid') ||
            currentStatus.toLowerCase().contains('collected') ||
            currentStatus.toLowerCase().contains('success') ||
            isPaidFull;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IgnorePointer(
        ignoring: _isUpdatingStatus,
        child: isCompleted
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatStatus(currentStatus),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : PopupMenuButton<String>(
                onSelected: _handleStatusChange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                itemBuilder: (context) {
                  return _statusOptions.map((status) {
                    return PopupMenuItem(
                      value: status,
                      child: Text(status,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    );
                  }).toList();
                },
                offset: const Offset(0, 40),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      if (_isUpdatingStatus)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.black),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatStatus(currentStatus),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.unfold_more_rounded,
                          size: 16, color: Colors.black),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _paymentHistorySection() {
    bool hasHistory = _appointment?.paymentHistory != null &&
        _appointment!.paymentHistory!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 14, color: Colors.black),
              const SizedBox(width: 6),
              Text('Payment History',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasHistory)
            Text('No payments recorded yet.',
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: Colors.grey.shade700))
          else
            ..._appointment!.paymentHistory!
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.paymentMethod?.capitalize() ?? 'Paid',
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5, color: Colors.black)),
                          Text('₹${p.amount?.toStringAsFixed(2) ?? '0.00'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                        ],
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value,
      {String? subtitle, IconData? iconData}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (iconData != null) ...[
                        Icon(iconData, size: 11, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                          child: Text(subtitle,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard() {
    final List<ServiceItem> items = _appointment!.serviceItems ?? [];
    final String label =
        items.length > 1 ? 'SERVICES (${items.length})' : 'SERVICE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.content_cut_rounded,
                    size: 16, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    Text(_appointment!.serviceName ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // List services dynamically
          if (items.isEmpty)
            _serviceItemDetail(
                _appointment!.serviceName ?? 'Unknown',
                _appointment!.amount ?? 0,
                _appointment!.staffName ?? '—',
                '${_appointment!.startTime}-${_appointment!.endTime} (${_appointment!.duration} min)',
                addOns: _appointment!.addOns)
          else
            ...items.map((it) {
              // Fallback: if item has no add-ons but there is only 1 service and appointment has add-ons, use them
              final effectiveAddOns =
                  (it.addOns != null && it.addOns!.isNotEmpty)
                      ? it.addOns
                      : (items.length == 1 ? _appointment!.addOns : null);

              return _serviceItemDetail(
                  it.serviceName ?? '—',
                  (it.amount ?? 0).toDouble(),
                  it.staffName ?? '—',
                  '${it.startTime}-${it.endTime} (${it.duration ?? 0} min)',
                  addOns: effectiveAddOns);
            }).toList(),
        ],
      ),
    );
  }

  Widget _serviceItemDetail(
      String name, double price, String staff, String time,
      {List<AddOn>? addOns}) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
              SizedBox(width: 8),
              Text('₹${price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ],
          ),
          const SizedBox(height: 1),
          Text('$staff • $time',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500)),
          if (addOns != null && addOns.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 4),
            ...addOns.map((addon) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('+ ${addon.name ?? 'Add-on'}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(width: 8),
                      Text('₹${(addon.price ?? 0).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.circle, size: 16, color: Colors.red.shade300),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STATUS',
                    style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                Text(_formatStatus(status),
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentDetailRow(String label, double value,
      {bool bold = false,
      Color? color,
      bool isStatusText = false,
      String? status}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          if (isStatusText)
            Text(status ?? 'Unpaid',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w700))
          else
            Text('₹${value.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color ?? Colors.black,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  String _getPaymentStatusText(AppointmentModel appt) {
    final paid = appt.amountPaid ?? 0;
    final total = appt.totalAmount ?? appt.amount ?? 0;
    if (paid >= total && total > 0) return 'Paid';
    if (paid > 0) return 'Partially Paid';
    return 'Unpaid';
  }

  String _formatStatus(String status) {
    if (status == 'completed_without_payment' ||
        status.toLowerCase() == 'completed (no pay)')
      return 'Completed (No Pay)';
    return status.replaceAll('_', ' ').capitalize();
  }

  void _showCollectPaymentDialog() {
    if (_appointment == null) return;
    showDialog(
      context: context,
      builder: (context) => CollectPaymentDialog(appointment: _appointment!),
    ).then((_) => _fetchAppointmentDetails());
  }

  void _showInvoice() {
    if (_appointment == null) return;

    final billingInvoice = BillingInvoice(
      id: _appointment!.id ?? '',
      invoiceNumber: _appointment!.id ?? 'N/A',
      vendorId: _appointment!.vendorId ?? '',
      clientId: _appointment!.client?.id ?? '',
      clientInfo: ClientInfo(
        fullName: _appointment!.clientName ?? 'Customer',
        email: _appointment!.client?.email ?? 'N/A',
        phone: _appointment!.client?.phone ?? 'N/A',
        profilePicture: '',
        address: '',
      ),
      items: _appointment!.serviceItems
              ?.map((s) => BillingItem(
                    itemId: '',
                    itemType: 'Service',
                    name: s.serviceName ?? 'Unknown',
                    description: '',
                    price: (s.amount ?? 0.0).toDouble(),
                    quantity: 1,
                    totalPrice: (s.amount ?? 0.0).toDouble(),
                    duration: s.duration ?? 0,
                    addOns: s.addOns
                            ?.map((a) => AddOnItem(
                                  id: a.id ?? '',
                                  name: a.name ?? 'Add-on',
                                  price: (a.price ?? 0.0).toDouble(),
                                  duration: a.duration ?? 0,
                                ))
                            .toList() ??
                        [],
                    discount: 0.0,
                    discountType: 'flat',
                  ))
              .toList() ??
          [
            BillingItem(
              itemId: '',
              itemType: 'Service',
              name: _appointment!.serviceName ?? 'Unknown',
              description: '',
              price: _appointment!.amount ?? 0.0,
              quantity: 1,
              totalPrice: _appointment!.amount ?? 0.0,
              duration: _appointment!.duration ?? 0,
              addOns: [],
              discount: 0.0,
              discountType: 'flat',
            )
          ],
      subtotal: _appointment!.totalAmount ?? _appointment!.amount ?? 0.0,
      taxRate: 0.0,
      taxAmount: 0.0,
      platformFee: 0.0,
      totalAmount: _appointment!.totalAmount ?? _appointment!.amount ?? 0.0,
      balance: 0.0,
      paymentMethod: _appointment!.paymentMethod ?? 'Cash',
      paymentStatus: 'Paid',
      billingType: 'Appointment',
      createdAt: _appointment!.date ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InvoiceDetailsDialog(invoice: billingInvoice),
    );
  }

  Future<void> _handleStatusChange(String selectedAction) async {
    if (_appointment == null) return;

    if (_appointment!.status?.toLowerCase().contains('completed') ?? false) {
      return;
    }

    String newStatusKey;
    if (selectedAction == 'Confirm Appointment') {
      newStatusKey = 'confirmed';
    } else if (selectedAction == 'Complete without Payment') {
      newStatusKey = 'completed_without_payment';
    } else if (selectedAction == 'Cancel Appointment') {
      newStatusKey = 'cancelled';
    } else if (selectedAction == 'Collect Payment') {
      _showCollectPaymentDialog();
      return;
    } else {
      return;
    }

    if (newStatusKey == (_appointment!.status?.toLowerCase() ?? '')) {
      return;
    }

    String? cancellationReason;
    if (newStatusKey == 'cancelled') {
      final reasonController = TextEditingController();
      cancellationReason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade400)),
          title: Text('Cancel Appointment',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for cancellation:',
                  style: GoogleFonts.poppins(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                    hintText: 'Reason...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reason is required')));
                  return;
                }
                Navigator.pop(context, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Cancel Appointment',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (cancellationReason == null) return;
    }

    setState(() => _isUpdatingStatus = true);
    try {
      await ApiService.updateAppointment(_appointment!.id!, {
        'status': newStatusKey,
        if (cancellationReason != null)
          'cancellationReason': cancellationReason,
      });
      await _fetchAppointmentDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      if (mounted) {
        _showErrorDialog('Failed to update status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
