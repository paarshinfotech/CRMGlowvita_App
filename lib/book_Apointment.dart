import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookAppointment extends StatefulWidget {
  const BookAppointment({super.key});

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();

  String? _selectedService;
  String? _selectedStaff;
  int? _selectedDuration;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 15);
  DateTime _selectedDate = DateTime(2025, 7, 22);

  final List<String> serviceList = [
    'Hair Cut',
    'Facial',
    'Hair Spa',
    'Manicure',
    'Pedicure'
  ];
  final List<String> staffList = ['Shivani', 'Komal', 'Pooja'];
  final List<int> durationList = [15, 30, 45, 60];

  List<TimeOfDay> _generateTimeSlots({int intervalMinutes = 15}) {
    return List.generate(
      (24 * 60 ~/ intervalMinutes),
      (index) {
        final hour = index * intervalMinutes ~/ 60;
        final minute = index * intervalMinutes % 60;
        return TimeOfDay(hour: hour, minute: minute);
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<TimeOfDay> timeSlots = _generateTimeSlots();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text(
          'New Appointment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Appointment Details"),
                    _buildLabel("Select Date"),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white, // Changed to white
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Start Time"),
                    DropdownButtonFormField<TimeOfDay>(
                      decoration: _fieldStyle(),
                      value: _startTime,
                      items: timeSlots.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time.format(context)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _startTime = val!),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Service"),
                    DropdownButtonFormField<String>(
                      decoration: _fieldStyle(),
                      value: _selectedService,
                      items: serviceList
                          .map((service) => DropdownMenuItem(
                                value: service,
                                child: Text(service),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedService = val),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Duration"),
                    DropdownButtonFormField<int>(
                      decoration: _fieldStyle(),
                      value: _selectedDuration,
                      items: durationList
                          .map((min) => DropdownMenuItem(
                                value: min,
                                child: Text("$min min"),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDuration = val),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Staff Member"),
                    DropdownButtonFormField<String>(
                      decoration: _fieldStyle(),
                      value: _selectedStaff,
                      items: staffList
                          .map((staff) => DropdownMenuItem(
                                value: staff,
                                child: Text(staff),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStaff = val),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Appointment Notes"),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: _fieldStyle(),
                    ),
                    const SizedBox(height: 32),
                    _sectionTitle("Client"),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _clientSearchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Client',
                                hintStyle: TextStyle(color: Colors.black45),
                                border: InputBorder.none,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: const [
                          Icon(Icons.search, size: 50, color: Colors.black45),
                          SizedBox(height: 12),
                          Text(
                            "Use the search to add a Client",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon:
                                const Icon(Icons.flash_on, color: Colors.white),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              elevation: 10,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            label: const Text(
                              "Express Checkout",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, color: Colors.white),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Appointment saved successfully!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              elevation: 10,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            label: const Text(
                              "Save Appointment",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  TextStyle _labelStyle() {
    return const TextStyle(fontWeight: FontWeight.w600, fontSize: 15);
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: _labelStyle()),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _fieldStyle() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white, // ✅ Changed to white
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
