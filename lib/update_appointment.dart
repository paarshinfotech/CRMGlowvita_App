import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UpdateAppointmentPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const UpdateAppointmentPage({super.key, required this.appointment});

  @override
  State<UpdateAppointmentPage> createState() => _UpdateAppointmentPageState();
}

class _UpdateAppointmentPageState extends State<UpdateAppointmentPage> {
  late DateTime selectedDate;
  late String selectedTime;
  late String selectedService;
  late String selectedDuration;
  late String selectedStaff;
  late TextEditingController notesController;

  final List<String> timeSlots = List.generate(
    9,
    (i) => DateFormat('hh:mm a').format(DateTime(2023, 1, 1, 10, i * 15)),
  ); // From 10:00 AM to 12:00 PM

  final List<String> services = ['Haircut', 'Shave', 'Facial', 'Massage'];
  final List<String> durations =
      List.generate(12, (i) => '${(i + 1) * 5} mins');
  final List<String> staffMembers = ['Priya', 'Amit', 'Neha', 'Ravi'];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedTime = timeSlots.first;
    selectedService = services.first;
    selectedDuration = durations.first;
    selectedStaff = staffMembers.first;
    notesController =
        TextEditingController(text: widget.appointment['notes'] ?? '');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Appointment",
            style: GoogleFonts.poppins(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person,
                          size: 30, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              widget.appointment['clientName'] ?? "Client Name",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(widget.appointment['email'] ?? "Email",
                              style: const TextStyle(color: Colors.grey)),
                          Text(widget.appointment['phone'] ?? "Phone",
                              style: const TextStyle(color: Colors.grey)),
                          Text(widget.appointment['address'] ?? "Address",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Date"),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.black),
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
                      const Text("Start Time"),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTime,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            dropdownColor: Colors.white,
                            items: timeSlots.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style:
                                        const TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedTime = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service & Duration Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Service"),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<String>(
                          value: selectedService,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: services
                              .map((service) => DropdownMenuItem(
                                    value: service,
                                    child: Text(service,
                                        style: TextStyle(color: Colors.black)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => selectedService = value);
                          },
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
                      const Text("Duration"),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<String>(
                          value: selectedDuration,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: durations
                              .map((dur) => DropdownMenuItem(
                                    value: dur,
                                    child: Text(dur,
                                        style: TextStyle(color: Colors.black)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => selectedDuration = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Staff Member
            const Text("Staff Member"),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedStaff,
              items: staffMembers
                  .map((staff) => DropdownMenuItem(
                        value: staff,
                        child: Text(staff),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedStaff = value);
              },
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            const Text("Appointment Notes"),
            const SizedBox(height: 6),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter any notes...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 8,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  // Save logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Appointment updated successfully!")),
                  );
                },
                child: const Text(
                  "Save Appointment",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
