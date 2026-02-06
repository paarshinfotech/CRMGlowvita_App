import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageSalesPage extends StatefulWidget {
  const ManageSalesPage({super.key});

  @override
  State<ManageSalesPage> createState() => _ManageSalesPageState();
}

class _ManageSalesPageState extends State<ManageSalesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> services = [
    {'name': 'spa', 'time': '25min', 'cat': 'spa', 'price': '300'},
    {'name': 'test', 'time': '25min', 'cat': 'spa', 'price': '300'},
    {'name': 'spa', 'time': '25min', 'cat': 'spa', 'price': '300'},
    {'name': 'dummy', 'time': '15min', 'cat': 'spa', 'price': '450'},
    {
      'name': 'Haircut',
      'time': '20min',
      'cat': 'Haircut',
      'price': '100',
      'old': '120'
    },
    {'name': 'nail art', 'time': '35min', 'cat': 'nail art', 'price': '300'},
    {'name': 'ABC', 'time': '20min', 'cat': '', 'price': '20', 'old': '100'},
  ];

  List<Map<String, String>> products = [
    {'name': 'Shampoo', 'time': '250ml', 'cat': 'Hair', 'price': '200'},
    {'name': 'Conditioner', 'time': '150ml', 'cat': 'Hair', 'price': '180'},
    {'name': 'Hair Gel', 'time': '100g', 'cat': 'Styling', 'price': '220'},
  ];

  bool isFlatDiscount = false;

  List<Map<String, dynamic>> selectedItems = [];
  List<String> staffMembers = ['Shivani', 'Siya', 'Jiya'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final items = _tabController.index == 0 ? services : products;
    final total =
        selectedItems.fold(0, (sum, item) => sum + int.parse(item['price']!));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Manage Sales',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Theme.of(context).primaryColor,
                    indicator: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, fontSize: 12.sp),
                    tabs: const [
                      Tab(text: "  Services  "),
                      Tab(text: "  Products  "),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _searchBox("Search by Client Name"),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _headerText('Name')),
                  Expanded(flex: 2, child: _headerText('Category')),
                  Expanded(
                      flex: 1,
                      child: _headerText('Price', align: TextAlign.right)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: items
                    .map((item) => GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedItems.add({
                                ...item,
                                'staff': staffMembers.first,
                                'quantity': 1,
                                'discount': 0,
                                'isFlatDiscount': false,
                              });
                            });
                          },
                          child: _buildItemRow(item),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 16.h),
            if (selectedItems.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...selectedItems.map((item) => GestureDetector(
                          onTap: () => _showEditCartItemPopup(context, item),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${item['name']} x${item['quantity']}",
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500)),
                                    Text("₹${item['price']}",
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text("${item['time']} with ${item['staff']}",
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        color: Theme.of(context).primaryColor)),
                              ],
                            ),
                          ),
                        )),
                    Divider(),
                    _rowTotal("Subtotal", "₹$total"),
                    _rowTotal("Taxes", "₹0"),
                    _rowTotal("Total", "₹$total"),
                    SizedBox(height: 6.h),
                    Divider(),
                    Text("To pay",
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: PopupMenuButton<String>(
                            onSelected: (value) {},
                            color: Colors.white,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'save',
                                child: Text("Save unpaid",
                                    style: GoogleFonts.poppins(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text("Cancel sale",
                                    style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                            icon: Icon(Icons.more_horiz),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            onPressed: () {},
                            child: Text('Continue',
                                style:
                                    GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditCartItemPopup(BuildContext context, Map<String, dynamic> item) {
    TextEditingController priceController =
        TextEditingController(text: item['price'].toString());
    TextEditingController quantityController =
        TextEditingController(text: item['quantity'].toString());
    TextEditingController discountController =
        TextEditingController(text: item['discount'].toString());
    String selectedStaff = item['staff'] ?? 'Juill Ware';
    bool isFlatDiscount = item['isFlatDiscount'] ?? false;
    if (!staffMembers.contains(selectedStaff)) {
      selectedStaff = staffMembers.first;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit cart item',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'] ?? 'dummy',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F9ED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '₹ ${item['price'] ?? 450}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF16B364),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price + Quantity
                Row(
                  children: [
                    // Price field with rupee icon background
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2939),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.currency_rupee,
                                color: Colors.white, size: 18),
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Quantity box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: () {
                              // Decrement logic
                            },
                          ),
                          Text(
                            '${item['quantity'] ?? 1}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () {
                              // Increment logic
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Discount toggle
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Flat Discount',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Switch(
                        value: isFlatDiscount,
                        onChanged: (val) {
                          setState(() {
                            isFlatDiscount = val;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                        inactiveThumbColor: Colors.grey,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Discount field with % icon background
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Discount',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2939),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isFlatDiscount ? Icons.currency_rupee : Icons.percent,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),

                // Staff Dropdown
                DropdownButtonFormField<String>(
                  value: selectedStaff,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Staff Member',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  style: GoogleFonts.poppins(color: Colors.black),
                  items: staffMembers.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => selectedStaff = newValue!),
                ),
              ],
            ),
          ),

          // Action Buttons
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actions: [
            TextButton(
              onPressed: () {
                // Remove logic
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Remove',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                // Save logic
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child:
                  Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _searchBox(String hint) {
    return TextField(
      style: GoogleFonts.poppins(fontSize: 13.sp),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13.sp),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
      ),
    );
  }

  Widget _headerText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600),
    );
  }

  Widget _rowTotal(String label, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13.sp)),
          Text(amount, style: GoogleFonts.poppins(fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, String> s) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: RichText(
              text: TextSpan(
                text: s['name'],
                style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: "\n${s['time']}",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 10.sp,
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s['cat'] ?? '',
              style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor, fontSize: 12.sp),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (s['old'] != null)
                  Text(
                    "₹${s['old']!}",
                    style: GoogleFonts.poppins(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontSize: 10.sp,
                    ),
                  ),
                Text(
                  "₹${s['price']!}",
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
