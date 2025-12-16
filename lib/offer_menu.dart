import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfferMenu extends StatefulWidget {
  @override
  _OfferMenuState createState() => _OfferMenuState();
}

class _OfferMenuState extends State<OfferMenu> {
  String _selectedExportOption = 'Export';
  final List<String> _exportOptions = ['Copy', 'Excel', 'Print', 'PDF', 'CSV'];

  final List<Map<String, String>> _offers = [];
  int _idCounter = 1;

  void _showAddOfferDialog({Map<String, String>? existingOffer, int? index}) {
    final isEditing = existingOffer != null;

    final TextEditingController titleController = TextEditingController(text: existingOffer?['offer'] ?? '');
    final TextEditingController codeController = TextEditingController(text: existingOffer?['code'] ?? '');
    final TextEditingController discountController = TextEditingController(text: existingOffer?['discount']?.replaceAll('%', '') ?? '');

    final TextEditingController startController = TextEditingController(text: existingOffer?['start'] ?? '');
    final TextEditingController endController = TextEditingController(text: existingOffer?['end'] ?? '');

    DateTime? startDate = existingOffer?['start'] != null ? DateFormat('dd/MM/yyyy').parse(existingOffer!['start']!) : null;
    DateTime? endDate = existingOffer?['end'] != null ? DateFormat('dd/MM/yyyy').parse(existingOffer!['end']!) : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer_outlined, color: Colors.blue.shade800),
                      SizedBox(width: 8),
                      Text(
                        isEditing ? "Edit Offer" : "Add New Offer",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: _inputDecoration('Offer Title', 'e.g., Festive Sale'),
                  ),
                  SizedBox(height: 14),

                  TextField(
                    controller: codeController,
                    decoration: _inputDecoration('Coupon Code', 'e.g., SAVE25'),
                  ),
                  SizedBox(height: 14),

                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Discount (%)',
                      hintText: 'e.g., 25',
                      prefixIcon: Container(
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: Colors.black)),
                        ),
                        child: Icon(Icons.percent, color: Colors.black),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  SizedBox(height: 14),

                  TextField(
                    controller: startController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          startController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    decoration: _calendarDecoration("Start Date"),
                  ),
                  SizedBox(height: 14),

                  TextField(
                    controller: endController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                          endController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    decoration: _calendarDecoration("End Date"),
                  ),
                  SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text(isEditing ? 'Update Offer' : 'Save Offer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    ),
                    onPressed: () {
                      final newOffer = {
                        'id': isEditing ? existingOffer!['id']! : (_idCounter++).toString(),
                        'offer': titleController.text.trim(),
                        'code': codeController.text.trim(),
                        'discount': '${discountController.text.trim()}%',
                        'start': startController.text.trim(),
                        'end': endController.text.trim(),
                      };

                      setState(() {
                        if (isEditing && index != null) {
                          _offers[index] = newOffer;
                        } else {
                          _offers.add(newOffer);
                        }
                      });

                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteOffer(int index) {
    setState(() {
      _offers.removeAt(index);
    });
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  InputDecoration _calendarDecoration(String label) {
    return InputDecoration(
      labelText: label,
      suffixIcon: Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade700),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add and manage your online offers',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
            SizedBox(height: 20),

            // Search Bar
            TextField(
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 20),

            // Export & Add New
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: _selectedExportOption,
                      icon: Icon(Icons.arrow_drop_down),
                      items: [
                        DropdownMenuItem(
                          child: Text('Export', style: TextStyle(fontSize: 13)),
                          value: 'Export',
                        ),
                        ..._exportOptions.map((option) => DropdownMenuItem(
                          child: Text(option, style: TextStyle(fontSize: 13)),
                          value: option,
                        )),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedExportOption = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showAddOfferDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade900,
                    elevation: 8,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Add New', style: TextStyle(fontSize: 14)),
                )
              ],
            ),
            SizedBox(height: 16),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Offers')),
                    DataColumn(label: Text('Coupon Code')),
                    DataColumn(label: Text('Discount')),
                    DataColumn(label: Text('Start Date')),
                    DataColumn(label: Text('End Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _offers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final offer = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(offer['id']!)),
                      DataCell(Text(offer['offer']!)),
                      DataCell(Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(offer['code']!),
                      )),
                      DataCell(Text(offer['discount']!)),
                      DataCell(Text(offer['start']!)),
                      DataCell(Text(offer['end']!)),
                      DataCell(PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showAddOfferDialog(existingOffer: offer, index: index);
                          } else if (value == 'delete') {
                            _deleteOffer(index);
                          }
                        },
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

InputDecoration _calendarDecoration(String label) {
  return InputDecoration(
    labelText: label,
    suffixIcon: Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade700),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.white,
  );
}

Widget _customTextField({required String label, required String hint}) {
  return TextField(
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
