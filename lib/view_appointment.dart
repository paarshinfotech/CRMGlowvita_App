import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'update_appointment.dart';

class ViewAppointmentPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const ViewAppointmentPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final String date = "Thursday, 24 Jul 2025";
    final String reference = "#00001820 at Wed, 23 Jul 2025 at 12:57pm";
    String dropdownValue = 'New Appointment';

    final Color primaryColor = Theme.of(context).primaryColor;

    // ↓ Reduced font sizes across the page
    final TextStyle headingStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final TextStyle subHeadingStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final TextStyle normalStyle = GoogleFonts.poppins(fontSize: 12);
    final TextStyle smallStyle = GoogleFonts.poppins(fontSize: 11);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Appointment",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 15, // reduced
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF6F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(date, style: headingStyle),
          const SizedBox(height: 20),

          // Client Info
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24, // slightly smaller
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person,
                        size: 26, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home,
                                size: 14,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              "Home Service",
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("User",
                            style: headingStyle.copyWith(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("juiware30@gmail.com", style: normalStyle),
                        const SizedBox(height: 2),
                        Text("+91 9689785487", style: normalStyle),
                        const SizedBox(height: 2),
                        Text(
                          "NM CIDCO, Nashik, Maharashtra, 422010",
                          style: normalStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            "Reference $reference",
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
          ),

          const SizedBox(height: 20),

          // Service Info
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nail Art", style: subHeadingStyle),
                            const SizedBox(height: 4),
                            Text(
                              "35 min with Juill Ware",
                              style: smallStyle.copyWith(
                                  color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.home,
                                    size: 14,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  "Home Service",
                                  style:
                                      smallStyle.copyWith(color: Colors.grey),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      Text(
                        "₹300",
                        style: GoogleFonts.poppins(
                          fontSize: 14, // reduced
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Service Tax:", style: normalStyle),
                      Text("₹0.00", style: normalStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Platform Fee:", style: normalStyle),
                      Text("₹10.00", style: normalStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total:",
                          style: headingStyle.copyWith(fontSize: 14)),
                      Text(
                        "₹310.00",
                        style: headingStyle.copyWith(
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: SizedBox(
              width: 300,
              child: DropdownButtonFormField<String>(
                value: null,
                items: [
                  DropdownMenuItem(
                    value: 'cancel',
                    child: Text('Cancel',
                        style: normalStyle.copyWith(color: Colors.black)),
                  ),
                  DropdownMenuItem(
                    value: 'confirm',
                    child: Text('Confirm',
                        style: normalStyle.copyWith(color: Colors.black)),
                  ),
                ],
                onChanged: (value) {
                  // ignore: avoid_print
                  print("Selected: $value");
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "New Appointment",
                  labelStyle: normalStyle.copyWith(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13, // reduced
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateAppointmentPage(
                        appointment: appointment,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: Theme.of(context).primaryColor, width: 1),
                  ),
                ),
                child: Text(
                  "Edit/Reschedule",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const InvoicePopup();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: Theme.of(context).primaryColor, width: 1),
                  ),
                ),
                child: Text(
                  "Invoice Details",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showCollectPaymentPopup(context, 310.00);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Collect Payment",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Appointments History", style: headingStyle),
                const SizedBox(height: 12),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 12, // reduced
                    ),
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    indicator: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tabs: const [
                      Tab(text: "  Upcoming  "),
                      Tab(text: "   Past   "),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tab Views
                SizedBox(
                  height: 260,
                  child: TabBarView(
                    children: [
                      // Upcoming Appointments
                      ListView.builder(
                        itemCount: upcomingAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = upcomingAppointments[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 46, // slightly smaller
                                height: 46,
                                decoration: BoxDecoration(
                                  color: getDateBgColor(
                                      context, appointment["serviceType"]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      appointment["day"],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      appointment["month"],
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                appointment["service"],
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(appointment["duration"],
                                  style: smallStyle),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule,
                                          size: 14,
                                          color: appointment["statusColor"]),
                                      const SizedBox(width: 4),
                                      Text(
                                        appointment["status"],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: appointment["statusColor"],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appointment["price"],
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Past Appointments
                      ListView.builder(
                        itemCount: pastAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = pastAppointments[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: getDateBgColor(
                                      context, appointment["serviceType"]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      appointment["day"],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      appointment["month"],
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                appointment["service"],
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(appointment["duration"],
                                  style: smallStyle),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_clock,
                                          size: 14,
                                          color: appointment["statusColor"]),
                                      const SizedBox(width: 4),
                                      Text(
                                        appointment["status"],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: appointment["statusColor"],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appointment["price"],
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
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
              ],
            ),
          )
        ]),
      ),
    );
  }
}

final List<Map<String, dynamic>> upcomingAppointments = [
  {
    "day": "25",
    "month": "JUL",
    "service": "Hair Spa",
    "duration": "45min with Amy Grace",
    "status": "Scheduled",
    "statusColor": Colors.green,
    "price": "₹500",
    "serviceType": "home"
  },
  {
    "day": "27",
    "month": "JUL",
    "service": "Bridal Makeup",
    "duration": "2h with Natasha",
    "status": "Scheduled",
    "statusColor": Colors.green,
    "price": "₹2500",
    "serviceType": "wedding"
  },
  {
    "day": "28",
    "month": "JUL",
    "service": "Facial Glow",
    "duration": "60min with Riya",
    "status": "Scheduled",
    "statusColor": Colors.green,
    "price": "₹700",
    "serviceType": "other"
  },
];

final List<Map<String, dynamic>> pastAppointments = [
  {
    "day": "24",
    "month": "JUL",
    "service": "Nail Art",
    "duration": "35min with Juill Ware",
    "status": "Completed",
    "statusColor": Colors.orange,
    "price": "₹300",
    "serviceType": "home"
  },
  {
    "day": "22",
    "month": "JUL",
    "service": "Wedding Hairdo",
    "duration": "90min with Sasha",
    "status": "Completed",
    "statusColor": Colors.orange,
    "price": "₹1800",
    "serviceType": "wedding"
  },
  {
    "day": "21",
    "month": "JUL",
    "service": "Hair Color",
    "duration": "90min with Sophia",
    "status": "Completed",
    "statusColor": Colors.orange,
    "price": "₹850",
    "serviceType": "other"
  },
];

Color getDateBgColor(BuildContext context, String serviceType) {
  switch (serviceType) {
    case "home":
      return Theme.of(context).primaryColor.withOpacity(0.1);
    case "wedding":
      return Colors.red.shade100;
    default:
      return Colors.grey.shade300;
  }
}

class InvoicePopup extends StatelessWidget {
  const InvoicePopup({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold);
    final TextStyle normalStyle = GoogleFonts.poppins(fontSize: 12);
    final TextStyle smallStyle = GoogleFonts.poppins(fontSize: 11);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      child: SizedBox(
        height: 600,
        width: 700,
        child: Row(
          children: [
            // Left Side
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.hourglass_bottom,
                        size: 52, color: Colors.orange),
                    Text(
                      'PENDING',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Saved Unpaid on Thursday, 17 Jul 2025\nat Men\'s Salons by Satish Raj',
                      style: smallStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: Text('Rebook',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.email),
                          onPressed: () {
                            _showEmailPopup(context);
                          },
                        ),
                        InvoicePopup.iconButton(Icons.print, 'Print'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                        child: InvoicePopup.iconButton(
                            Icons.download, 'Download')),
                  ],
                ),
              ),
            ),

            // Right Side
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice details', style: titleStyle),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Invoice #1186',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                                child: Text('Thursday, 17 Jul 2025',
                                    style: normalStyle)),
                            const SizedBox(height: 4),
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Billed to ',
                                  style: normalStyle,
                                  children: [
                                    TextSpan(
                                      text: 'SS SS',
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Chip(
                                label: Text('PENDING',
                                    style: TextStyle(
                                        color: Colors.orange, fontSize: 11)),
                                backgroundColor: Color(0xFFFFF3CD),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const Divider(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Item',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                                Text('Amount',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'nail art\n12:30pm, 17 Jul 2025,\n35min with Satish Raj',
                                    style: smallStyle,
                                  ),
                                ),
                                Text('1x ₹ 300', style: normalStyle),
                              ],
                            ),
                            const Divider(height: 30),
                            rowText('Subtotal', '₹ 300', normalStyle),
                            rowText('Service Tax:', '₹0.00', normalStyle),
                            rowText('Platform Fee:', '₹10.00', normalStyle),
                            const Divider(height: 30),
                            rowText('Total', '₹ 310', normalStyle),
                            rowText('Balance', '₹ 310.00', normalStyle,
                                isBold: true),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget rowText(String title, String value, TextStyle base,
      {bool isBold = false}) {
    final style =
        base.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  static Widget iconButton(IconData icon, String label) {
    return Column(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(60, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () {},
          child: Column(
            children: [
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      GoogleFonts.poppins(color: Colors.black, fontSize: 11)),
            ],
          ),
        )
      ],
    );
  }
}

void _showEmailPopup(BuildContext context) {
  final TextStyle titleStyle =
      GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold);
  final TextStyle normalStyle = GoogleFonts.poppins(fontSize: 12);

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Send email to clients', style: titleStyle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('To', normalStyle),
                _buildTextField(
                    hint: 'juiware30@gmail.com', style: normalStyle),
                _buildLabel(
                  'Your email (Optional)',
                  normalStyle,
                  optionalHint:
                      'Enter your email to receive a reply from clients',
                ),
                _buildTextField(hint: 'mail@example.com', style: normalStyle),
                _buildLabel('Subject', normalStyle),
                _buildTextField(
                  hint: 'Sales Invoice #1186 From Men\'s Salons',
                  style: normalStyle,
                ),
                _buildLabel('Message', normalStyle),
                _buildTextField(
                  hint:
                      'Hi,\nPlease see attached sales invoice #1186.\nThank you.',
                  maxLines: 5,
                  style: normalStyle,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file,
                          color: Colors.grey[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Sales Invoice #1186.PDF',
                        style: normalStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Send',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildLabel(String title, TextStyle style, {String? optionalHint}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: style.copyWith(fontWeight: FontWeight.w600)),
        if (optionalHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              optionalHint,
              style: style.copyWith(color: Colors.grey[600], fontSize: 11),
            ),
          ),
      ],
    ),
  );
}

Widget _buildTextField(
    {required String hint, required TextStyle style, int maxLines = 1}) {
  return TextFormField(
    maxLines: maxLines,
    initialValue: hint,
    style: style,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: style.copyWith(color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
  );
}

void _showCollectPaymentPopup(BuildContext context, double totalAmount) {
  final TextStyle amountStyle =
      GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold);
  final TextStyle titleStyle =
      GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹ ${totalAmount.toStringAsFixed(2)}', style: amountStyle),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: Text('Save Order',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: Text('Pay Later',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 40),
              Text('Select payment method', style: titleStyle),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildPaymentOption(Icons.money, 'Cash'),
                  _buildPaymentOption(Icons.qr_code_2, 'QR Code'),
                  _buildPaymentOption(Icons.credit_card, 'Debit Card'),
                  _buildPaymentOption(Icons.credit_card_rounded, 'Credit Card'),
                  _buildPaymentOption(Icons.link, 'Payment Link'),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPaymentOption(IconData icon, String label) {
  return SizedBox(
    width: 100,
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(icon, size: 24, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    ),
  );
}
