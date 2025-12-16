import 'package:flutter/material.dart';
import 'package:glowvita/my_Profile.dart';
import 'offer_menu.dart';
import 'staff.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salon Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage all your settings in one place.', style: TextStyle(color: Colors.black54, fontSize: 14)),
            SizedBox(height: 20),

            _settingCard(
              title: 'Account setup',
              items: [
                _settingTile(
                  title: 'Salon details',
                  subtitle: 'Manage settings such as your business name and time zone',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => My_Profile()));
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            _settingCard(
              title: 'Sales',
              items: [
                _settingTile(
                  title: 'Taxes',
                  subtitle: 'Manage tax rates that apply to items sold at checkout',
                  onTap: () {
                    _showTaxesPopup(context);
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            _settingCard(
              title: 'Online offers',
              items: [
                _settingTile(
                  title: 'Offers menu',
                  subtitle: 'Add, edit and delete the types of offers available',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OfferMenu()));
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            _settingCard(
              title: 'Staff Members',
              items: [
                _settingTile(
                  title: 'Staff members',
                  subtitle: 'Add, edit and delete your staff members',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => Staff()));
                  },
                ),
                _settingTile(
                  title: 'Working hours',
                  subtitle: 'Manage working hours of your staff members',
                  onTap: () {
                    _showWorkingHoursDialog();
                  },
                ),
                _settingTile(
                  title: 'Permissions',
                  subtitle: 'Configure level of access to people for each of your staff member',
                  onTap: () {},
                ),
                _settingTile(
                  title: 'Commissions',
                  subtitle: 'Set up the calculation of commissions for staff members',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingCard({required String title, required List<Widget> items}) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(height: 12),
          ...items,
        ]),
      ),
    );
  }

  Widget _settingTile({required String title, required String subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.black87)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showTaxesPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Map<String, dynamic>> taxes = [
              {'name': 'GST', 'rate': '18%'},
              {'name': 'Service Tax', 'rate': '5%'},
            ];

            void showAddEditPopup({Map<String, dynamic>? existingTax, int? index}) {
              TextEditingController nameCtrl = TextEditingController(text: existingTax?['name'] ?? '');
              TextEditingController rateCtrl = TextEditingController(text: existingTax?['rate']?.replaceAll('%', '') ?? '');

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Add/Edit Tax", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text("Set the tax name and percentage rate. To apply this to your products and services, adjust your tax defaults settings.", style: TextStyle(fontSize: 13)),
                        SizedBox(height: 16),
                        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Tax Name", border: OutlineInputBorder())),
                        SizedBox(height: 10),
                        TextField(
                          controller: rateCtrl,
                          decoration: InputDecoration(labelText: "Tax Rate (%)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            String name = nameCtrl.text.trim();
                            String rate = rateCtrl.text.trim() + "%";
                            if (name.isNotEmpty && rateCtrl.text.isNotEmpty) {
                              if (existingTax != null && index != null) {
                                taxes[index] = {'name': name, 'rate': rate};
                              } else {
                                taxes.add({'name': name, 'rate': rate});
                              }
                              setState(() {});
                              Navigator.pop(context);
                            }
                          },
                          child: Text("Save", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text("Tax Rates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Spacer(),
                      IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: taxes.length,
                    itemBuilder: (context, index) {
                      var tax = taxes[index];
                      return Card(
                        color: Colors.grey[100],
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(tax['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(tax['rate']),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.settings),
                            onSelected: (value) {
                              if (value == 'Edit') {
                                Navigator.pop(context);
                                showAddEditPopup(existingTax: tax, index: index);
                              } else if (value == 'Delete') {
                                taxes.removeAt(index);
                                setState(() {});
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'Edit', child: Text('Edit')),
                              PopupMenuItem(value: 'Delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => showAddEditPopup(),
                    child: Text("Add New", style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWorkingHoursDialog() {
    final List<Map<String, String>> _staffs = [
      {'name': 'Renuka', 'position': 'Hair Stylist'},
      {'name': 'Om', 'position': 'Therapist'},
      {'name': 'Siya', 'position': 'Nail Artist'},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Manage Staff Working Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              SizedBox(height: 16),
              ..._staffs.map((staff) {
                return Card(
                  elevation: 8,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(staff['name']![0], style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    title: Text(staff['name']!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Text(staff['position']!, style: TextStyle(fontSize: 10)),
                    ),
                    trailing: PopupMenuButton<String>(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      icon: Icon(Icons.settings),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditWorkingHoursDialog(staff['name']!);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.orange))),
                        PopupMenuItem(value: 'blocked', child: Text('Blocked Time', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditWorkingHoursDialog(String staffName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: _buildOpeningHoursTab(staffName, context),
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningHoursTab(String staffName, BuildContext context) {
    final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Edit Working Hours for $staffName", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...days.map((day) => _buildDayTimeRow(day, context)).toList(),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: Text("Save", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildDayTimeRow(String day, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(day, style: TextStyle(fontSize: 14))),
          Expanded(flex: 2, child: _buildTimeButton(day, true, context)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _buildTimeButton(day, false, context)),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String day, bool isStartTime, BuildContext context) {
    String label = isStartTime ? "Start" : "End";
    return OutlinedButton(
      onPressed: () async {
        TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (pickedTime != null) {
          print("$day - $label: ${pickedTime.format(context)}");
        }
      },
      child: Text(label),
    );
  }
}
