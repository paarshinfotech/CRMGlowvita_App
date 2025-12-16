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

    final Color primaryColor = Colors.blue;
    final TextStyle headingStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    final TextStyle normalStyle = GoogleFonts.poppins(fontSize: 14);

    return Scaffold(
      appBar: AppBar(
        title: Text("View Appointment",
            style: GoogleFonts.poppins(color: Colors.black)),
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
              side: const BorderSide(color: Colors.black), // Added black border
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.home, size: 16, color: Colors.blue),
                            SizedBox(width: 6),
                            Text("Home Service", style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("User", style: headingStyle.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("juiware30@gmail.com", style: normalStyle),
                        const SizedBox(height: 2),
                        Text("+91 9689785487", style: normalStyle),
                        const SizedBox(height: 2),
                        Text("NM CIDCO, Nashik, Maharashtra, 422010", style: normalStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text("Reference $reference",
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14)),

          const SizedBox(height: 20),

          // Service Info
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black), // Black border added
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
                            Text(
                              "Nail Art",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "35 min with Juill Ware",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.home, size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  "Home Service",
                                  style: normalStyle.copyWith(color: Colors.grey),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      Text(
                        "₹300",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
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
                      Text("Total:", style: headingStyle.copyWith(fontSize: 16)),
                      Text(
                        "₹310.00",
                        style: headingStyle.copyWith(
                          fontSize: 16,
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
            child: Container(
              width: 300,
              child: DropdownButtonFormField<String>(
                value: null,
                items: const [
                  DropdownMenuItem(
                    value: 'cancel',
                    child: Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                  DropdownMenuItem(
                    value: 'confirm',
                    child: Text('Confirm', style: TextStyle(color: Colors.black)),
                  ),
                ],
                onChanged: (value) {
                  print("Selected: $value");
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "New Appointment",
                  labelStyle: TextStyle(fontSize: 14, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                dropdownColor: Colors.white, // Makes dropdown menu background white
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
                    side: const BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                child: const Text(
                  "Edit/Reschedule",
                  style: TextStyle(
                    color: Colors.blue,
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
                      return const InvoicePopup(); // This will display your custom dialog
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                child: const Text(
                  "Invoice Details",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
                      borderRadius: BorderRadius.circular(10))),
              child: const Text("Collect Payment",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
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
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    indicator: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tabs: const [
                      Tab(text: "  Upcoming  "),
                      Tab(text: "     Past     "),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tab Views
                SizedBox(
                  height: 260, // adjust as needed
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: getDateBgColor(appointment["service"]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(appointment["day"],
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(appointment["month"],
                                        style: GoogleFonts.poppins(fontSize: 12)),
                                  ],
                                ),
                              ),

                              title: Text(appointment["service"], style: GoogleFonts.poppins()),
                              subtitle:
                              Text(appointment["duration"], style: normalStyle),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule,
                                          size: 16, color: appointment["statusColor"]),
                                      const SizedBox(width: 4),
                                      Text(appointment["status"],
                                          style: TextStyle(
                                              color: appointment["statusColor"])),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(appointment["price"],
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: getDateBgColor(appointment["service"]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(appointment["day"],
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(appointment["month"],
                                        style: GoogleFonts.poppins(fontSize: 12)),
                                  ],
                                ),
                              ),

                              title: Text(appointment["service"], style: GoogleFonts.poppins()),
                              subtitle:
                              Text(appointment["duration"], style: normalStyle),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_clock,
                                          size: 16, color: appointment["statusColor"]),
                                      const SizedBox(width: 4),
                                      Text(appointment["status"],
                                          style: TextStyle(
                                              color: appointment["statusColor"])),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(appointment["price"],
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
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

Color getDateBgColor(String serviceType) {
  switch (serviceType) {
    case "home":
      return Colors.blue.shade100;
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
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      child: SizedBox(
        height: 600, // Increased height
        width: 700,
        child: Row(
          children: [
            // Left Side - Status and Actions
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
                    const Icon(Icons.hourglass_bottom, size: 60, color: Colors.orange),
                    const Text(
                      'PENDING',
                      style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Saved Unpaid on Thursday, 17 Jul 2025\nat Men\'s Salons by Satish Raj',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Rebook', style: TextStyle(color: Colors.white)), // updated
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.email),
                          onPressed: () {
                            _showEmailPopup(context);
                          },
                        ),

                        iconButton(Icons.print, 'Print'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(child: iconButton(Icons.download, 'Download')),
                  ],
                ),
              ),
            ),

            // Right Side - Invoice Details
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView( // added scroll
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invoice details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            const Center(
                              child: Text('Invoice #1186',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(height: 4),
                            const Center(child: Text('Thursday, 17 Jul 2025')),
                            const SizedBox(height: 4),
                            const Center(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Billed to ',
                                  children: [
                                    TextSpan(
                                      text: 'SS SS',
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Chip(
                                label: Text('PENDING', style: TextStyle(color: Colors.orange)),
                                backgroundColor: Color(0xFFFFF3CD),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const Divider(height: 30),
                            Row(
                              children: const [
                                Expanded(child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                                Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(
                                  child: Text(
                                    'nail art\n12:30pm, 17 Jul 2025,\n35min with Satish Raj',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text('1x ₹ 300'),
                              ],
                            ),
                            const Divider(height: 30),
                            rowText('Subtotal', '₹ 300'),
                            rowText('Service Tax:', '₹0.00'),
                            rowText('Platform Fee:', '₹10.00'),
                            const Divider(height: 30),
                            rowText('Total', '₹ 310'),
                            rowText('Balance', '₹ 310.00', isBold: true),
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

  static Widget rowText(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          )
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
              Icon(icon, size: 20, color: Colors.black),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}

void _showEmailPopup(BuildContext context) {
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
                /// Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Send email to clients',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// To
                _buildLabel('To'),
                _buildTextField(hint: 'juiware30@gmail.com'),

                /// Your Email
                _buildLabel('Your email (Optional)', optionalHint: 'Enter your email to receive a reply from clients'),
                _buildTextField(hint: 'mail@example.com'),

                /// Subject
                _buildLabel('Subject'),
                _buildTextField(hint: 'Sales Invoice #1186 From Men\'s Salons'),

                /// Message
                _buildLabel('Message'),
                _buildTextField(
                  hint: 'Hi,\nPlease see attached sales invoice #1186.\nThank you.',
                  maxLines: 5,
                ),

                /// Attachment (PDF)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Sales Invoice #1186.PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Send Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      // Add send logic here
                      Navigator.of(context).pop();
                    },
                    child: const Text('Send', style: TextStyle(color: Colors.white)),
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

Widget _buildLabel(String title, {String? optionalHint}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        if (optionalHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              optionalHint,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    ),
  );
}

Widget _buildTextField({required String hint, int maxLines = 1}) {
  return TextFormField(
    maxLines: maxLines,
    initialValue: hint,
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

void _showCollectPaymentPopup(BuildContext context, double totalAmount) {
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
              Text(
                '₹ ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Save order logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Save Order',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Pay later logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Pay Later',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40),
              const Text(
                'Select payment method',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
          child: Icon(icon, size: 28, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}


