import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../appointment_model.dart';
import '../services/api_service.dart';
import '../utils/string_extensions.dart';

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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_appointment?.clientName ?? "Client"} • ${DateFormat('MMM d, yyyy').format(date)} • ${_appointment?.startTime ?? ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.6),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              indicatorColor: Colors.blueGrey.shade700,
              labelColor: Colors.blueGrey.shade900,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Client History'),
              ],
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Quick actions
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionChip(
                            Icons.attach_money_rounded, 'Collect Payment'),
                        _actionChip(Icons.calendar_today_rounded, 'Reschedule'),
                        _statusChip(_appointment!.status ?? 'Scheduled'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info cards grid
                    ..._buildInfoGrid([
                      _infoTile(Icons.person_outline_rounded, 'CLIENT',
                          _appointment?.clientName ?? '—'),
                      _infoTile(Icons.calendar_today_outlined, 'DATE & TIME',
                          '$formattedDate\n${_appointment?.startTime ?? ''} - ${_appointment?.endTime ?? ''} (${_appointment?.duration ?? '?'} min)'),
                      _infoTile(Icons.content_cut_rounded, 'SERVICE',
                          displayServiceName),
                      _infoTile(Icons.circle, 'STATUS',
                          _appointment?.status?.capitalize() ?? 'Scheduled',
                          isStatus: true),
                      _infoTile(Icons.people_outline_rounded, 'STAFF',
                          _appointment?.staffName ?? '—'),
                    ]),

                    // Location Info (Home Service)
                    if (_appointment?.isHomeService == true &&
                        _appointment?.homeServiceLocation != null) ...[
                      const SizedBox(height: 16),
                      _infoTile(
                        Icons.location_on_outlined,
                        'HOME SERVICE LOCATION',
                        _appointment!.homeServiceLocation!.address ?? 'N/A',
                      ),
                    ],

                    // Notes
                    if (_appointment?.notes != null &&
                        _appointment!.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _infoTile(
                        Icons.note_alt_outlined,
                        'NOTES',
                        _appointment!.notes!,
                      ),
                    ],

                    // Service List (Multi/Wedding)
                    _buildServiceList(),

                    const SizedBox(height: 28),

                    // Payment section
                    Text(
                      'Payment Details',
                      style: GoogleFonts.poppins(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    _paymentRow('Service Amount',
                        '₹${_appointment?.amount?.toStringAsFixed(2) ?? '0.00'}'),

                    if ((_appointment?.discount ?? 0) > 0)
                      _paymentRow('Discount',
                          '- ₹${_appointment?.discount?.toStringAsFixed(2) ?? '0.00'}',
                          muted: true),

                    _paymentRow('Total Amount',
                        '₹${_appointment?.totalAmount?.toStringAsFixed(2) ?? _appointment?.amount?.toStringAsFixed(2) ?? '0.00'}',
                        bold: true),
                    _paymentRow('Amount Paid',
                        '₹${_appointment?.amountPaid?.toStringAsFixed(2) ?? '0.00'}',
                        muted: true),
                    _paymentRow('Amount Remaining',
                        '₹${_appointment?.amountRemaining?.toStringAsFixed(2) ?? '0.00'}',
                        muted: true),

                    const SizedBox(height: 8),
                    Text(
                      '• ${_appointment?.paymentStatus?.capitalize() ?? 'Unpaid'}',
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: Colors.grey.shade700),
                    ),

                    // Payment History List
                    if (_appointment?.paymentHistory != null &&
                        _appointment!.paymentHistory!.isNotEmpty)
                      _buildPaymentHistoryList(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    label: const Text('Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Methods ──────────────────────────────────────────────────────────

  Widget _buildServiceList() {
    if (_appointment?.isWeddingService == true &&
        _appointment?.weddingPackageDetails?.packageServices != null &&
        _appointment!.weddingPackageDetails!.packageServices!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Package Services',
            style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._appointment!.weddingPackageDetails!.packageServices!.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(s.serviceName ?? 'Unknown Service',
                      style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      );
    } else if (_appointment?.isMultiService == true &&
        _appointment?.serviceItems != null &&
        _appointment!.serviceItems!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Services',
            style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._appointment!.serviceItems!.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.serviceName ?? 'Unknown',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        if (s.staffName != null)
                          Text('by ${s.staffName}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('₹${s.amount?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPaymentHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Payment History',
          style:
              GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: _appointment!.paymentHistory!.map((p) {
              DateTime? pDate;
              try {
                if (p.paymentDate != null)
                  pDate = DateTime.parse(p.paymentDate!);
              } catch (_) {}

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            pDate != null
                                ? DateFormat('MMM d, hh:mm a').format(pDate)
                                : 'Unknown Date',
                            style: GoogleFonts.poppins(fontSize: 12)),
                        Text(p.paymentMethod?.capitalize() ?? 'Cash',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Text('₹${p.amount?.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade800),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status.toLowerCase() == 'scheduled'
        ? Colors.green.shade700
        : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.capitalize(),
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade500,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {bool isStatus = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isStatus ? Colors.red.shade400 : Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoGrid(List<Widget> tiles) {
    final List<Widget> result = [];

    for (int i = 0; i < tiles.length; i += 2) {
      result.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 12),
            if (i + 1 < tiles.length)
              Expanded(child: tiles[i + 1])
            else
              const Spacer(),
          ],
        ),
      );

      // Add spacing between rows (except after the last one)
      if (i + 2 < tiles.length) {
        result.add(const SizedBox(height: 12));
      }
    }

    return result;
  }

  Widget _paymentRow(String label, String value,
      {bool bold = false, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: muted ? Colors.grey.shade700 : Colors.black87,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: muted ? Colors.grey.shade700 : Colors.black87,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
