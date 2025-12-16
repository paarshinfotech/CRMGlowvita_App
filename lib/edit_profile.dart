import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  const EditProfilePage({super.key, required this.currentName});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final nameController = TextEditingController();
  final headlineController = TextEditingController();
  final aboutController = TextEditingController();
  final specialityController = TextEditingController();
  File? _imageFile;
  final salonNameController = TextEditingController();
  final contactController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();
  final gstController = TextEditingController();
  final depositController = TextEditingController();
  bool homeService = false;
  bool eventService = false;
  bool weddingService = false;
  final experienceController = TextEditingController();
  final happyClientsController = TextEditingController();
  final expertStaffsController = TextEditingController();
  final bankNameController = TextEditingController();
  final ifscController = TextEditingController();
  final accountHolderController = TextEditingController();
  final accountNumberController = TextEditingController();
  List<String> specialities = [];
  String profileUrl =
      "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91";
  final List<String> documentTypes = [
    "Udyog Aadhar",
    "Udyam Registration",
    "Shop Act Licence",
    "PAN Card",
    "Other"
  ];
  String? selectedDocumentType;
  List<Map<String, String>> uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);   // length of tab bar
    nameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    headlineController.dispose();
    aboutController.dispose();
    super.dispose();
  }
  final List<File> _selectedImages = [];

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        profileUrl = _imageFile!.path; // Update with local path
      });
    }
  }

  Widget customTextField({
    required String label,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    final focusNode = FocusNode();
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Focus(
              focusNode: focusNode,
              onFocusChange: (hasFocus) => setState(() {}),
              child: TextField(
                controller: controller,
                keyboardType: inputType,
                maxLines: maxLines,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1), // Thin gray border
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    const BorderSide(color: Colors.black, width: 1.6), // Black thick border
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22)),
        const SizedBox(height: 6),
        Text("Update your avatar for your professional profile.",
            style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 16)),
        const SizedBox(height: 24),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : NetworkImage(profileUrl) as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.photo, size: 22),
                        onPressed: _pickImage,
                        tooltip: 'Choose Photo',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPersonalDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 10),
        Text("Salon Details",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        customTextField(label: "Salon Contact", controller: contactController, inputType: TextInputType.phone),
        customTextField(label: "State", controller: stateController),
        customTextField(label: "City", controller: cityController),
        customTextField(label: "Address", controller: addressController),
        customTextField(label: "Pincode", controller: pincodeController, inputType: TextInputType.number),
        customTextField(label: "GST Number", controller: gstController),

        const SizedBox(height: 10),
        Text("Special Service Area",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
        CheckboxListTile(
          title: const Text("Home Service"),
          value: homeService,activeColor: Colors.black,
          onChanged: (val) => setState(() => homeService = val!),
        ),
        CheckboxListTile(
          title: const Text("Event Service"),
          value: eventService,activeColor: Colors.black,
          onChanged: (val) => setState(() => eventService = val!),
        ),
        CheckboxListTile(
          title: const Text("Wedding Service"),
          value: weddingService,activeColor: Colors.black,
          onChanged: (val) => setState(() => weddingService = val!),
        ),
        const SizedBox(height: 10),

        customTextField(label: "Security Deposit Amount", controller: depositController, inputType: TextInputType.number),
        customTextField(label: "About Salon", controller: aboutController, maxLines: 4),

        const SizedBox(height: 10),
        Divider(),
        const SizedBox(height: 10),
        Text("Vendor Info", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        customTextField(
          label: "Years of Experience",
          controller: experienceController,
          inputType: TextInputType.number,
        ),

        customTextField(
          label: "Happy Clients",
          controller: happyClientsController,
          inputType: TextInputType.number,
        ),

        customTextField(
          label: "Expert Staffs",
          controller: expertStaffsController,
          inputType: TextInputType.number,
        ),

        ElevatedButton(
          onPressed: () {
            // Save logic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.blue),
            ),
            elevation: 4,
          ),
          child: Text(
            "Save",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),

      ],
    );
  }

  Widget _buildImagesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Upload Salon Images",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.upload_file, color: Colors.white, size: 30,),
          label: Text("Select Images", style: GoogleFonts.poppins()),
          style:
          ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        _selectedImages.isEmpty
            ? Center(child: Text("No images selected", style: GoogleFonts.poppins()))
            : Expanded(
          child: GridView.builder(
            itemCount: _selectedImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedImages[index], fit: BoxFit.cover),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningHoursTab() {
    final List<String> days = [
      "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Salon Opening Hours",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        ...days.map((day) => _buildDayTimeRow(day)).toList(),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            // TODO: Save logic here
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Save", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        )
      ],
    );
  }

  Map<String, TimeOfDay?> openTimes = {};
  Map<String, TimeOfDay?> closeTimes = {};
  Widget _buildTimeButton(String day, bool isOpen) {
    final timeMap = isOpen ? openTimes : closeTimes;
    final label = isOpen ? "Open" : "Close";
    final time = timeMap[day];
    return OutlinedButton(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,

                  // Hour and Minute boxes
                  hourMinuteShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                  hourMinuteColor: MaterialStateColor.resolveWith((states) => Colors.white),
                  hourMinuteTextColor: MaterialStateColor.resolveWith((states) => Colors.black),

                  // Dial values
                  dialTextColor: MaterialStateColor.resolveWith(
                        (states) => states.contains(MaterialState.selected)
                        ? Colors.white
                        : Colors.black,
                  ),
                  dialHandColor: Colors.black,
                  dialBackgroundColor: Colors.white,

                  // AM/PM toggle
                  dayPeriodShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                  dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) ? Colors.black : Colors.white),
                  dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected) ? Colors.white : Colors.black),

                  helpTextStyle: const TextStyle(color: Colors.black),
                  entryModeIconColor: Colors.black,
                ),
                colorScheme: const ColorScheme.light(
                  primary: Colors.black,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            timeMap[day] = picked;
          });
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Colors.grey),
      ),
      child: Text(
        time != null ? time.format(context) : "$label: --:--",
        style: GoogleFonts.poppins(color: Colors.blue),      ),
    );
  }

  TimeOfDay? selectedOpenTime;
  TimeOfDay? selectedCloseTime;
  Widget _buildDayTimeRow(String day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
          Row(
            children: [
              _buildTimeButton(day, true),  // Open time
              const SizedBox(width: 8),
              _buildTimeButton(day, false), // Close time
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Add Specialities",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: specialityController,
                decoration: InputDecoration(
                  hintText: "Enter speciality",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                if (specialityController.text.trim().isNotEmpty) {
                  setState(() {
                    specialities.add(specialityController.text.trim());
                    specialityController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Add", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialities.map((spec) {
            return Chip(
              label: Text(spec, style: GoogleFonts.poppins()),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  specialities.remove(spec);
                });
              },
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            // TODO: Save speciality list
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Save", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildBankDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Bank Details",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        customTextField(label: "Bank Name", controller: bankNameController),
        customTextField(label: "IFSC Code", controller: ifscController),
        customTextField(label: "Account Holder / Firm Name", controller: accountHolderController),
        customTextField(label: "Account Number", controller: accountNumberController, inputType: TextInputType.number),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // TODO: Save bank details
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text("Save", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Salon Documents",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        Text("Select Document Type", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedDocumentType,
          items: documentTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type, style: GoogleFonts.poppins()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedDocumentType = value;
            });
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (result != null && selectedDocumentType != null) {
              setState(() {
                uploadedDocuments.add({
                  'type': selectedDocumentType!,
                  'path': result.path
                });
              });
            }
          },
          icon: const Icon(Icons.upload_file, color: Colors.white,size: 30,),
          label: Text("Upload Document", style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 20),
        Divider(),
        const SizedBox(height: 20),
        Text("Uploaded Documents", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),

        ...uploadedDocuments.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.black),
              title: Text(doc['type']!, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text(doc['path']!.split('/').last, style: GoogleFonts.poppins(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.black),
                tooltip: "Remove",
                onPressed: () {
                  setState(() {
                    uploadedDocuments.removeAt(index);
                  });
                },
              ),
            ),
          );
        })

      ],
    );
  }

  Widget _buildSubscriptionTab() {
    final List<Map<String, String>> subscriptions = [
      {
        'plan': 'Platinum',
        'purchased': '02 Jul 2025, 10:44AM',
        'starts': '02 Jul 2025, 12:00AM',
        'expires': '30 Sep 2025, 12:00AM',
        'status': 'ACTIVE',
      },
      {
        'plan': 'Trial',
        'purchased': '22 Jun 2025, 04:59PM',
        'starts': '22 Jun 2025, 04:59PM',
        'expires': '29 Jun 2025, 04:59PM',
        'status': 'EXPIRED',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Subscription Details",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          _buildTableHeader(),
          const Divider(thickness: 1),
          ...subscriptions.map((sub) => _buildTableRow(sub)).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: const [
        Expanded(flex: 2, child: Text("PLAN", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text("PURCHASED", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text("STARTS", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text("EXPIRES", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildTableRow(Map<String, String> sub) {
    final isActive = sub['status'] == 'ACTIVE';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              sub['plan']!,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Expanded(flex: 3, child: Text(sub['purchased']!)),
          Expanded(flex: 3, child: Text(sub['starts']!)),
          Expanded(flex: 3, child: Text(sub['expires']!)),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isActive ? Colors.blue : Colors.red),
              ),
              child: Text(
                sub['status']!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.blue : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final selected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index); // animate tab switch
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: selected ? Colors.blue : Colors.black,
            fontSize: 18,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    _tabController.addListener(() => setState(() {}));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 26),
              onPressed: () => Navigator.pop(context))
        ],


      ),
      body: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 30,),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text("Edit your online profile",
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton("Personal details", 0),
                  const SizedBox(width: 10),
                  _buildTabButton("Images", 1),
                  const SizedBox(width: 6),
                  _buildTabButton("Opening hours", 2),
                  const SizedBox(width: 6),
                  _buildTabButton("Speciality", 3),
                  const SizedBox(width: 6),
                  _buildTabButton("Bank Details", 4),
                  const SizedBox(width: 6),
                  _buildTabButton("Documents", 5),
                  const SizedBox(width: 6),
                  _buildTabButton("Subscription", 6),
                ],
              ),
            ),
          ),  // Tabs

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: _buildPersonalDetailsTab()),
                  _buildImagesTab(),
                  SingleChildScrollView(child: _buildOpeningHoursTab()),
                  SingleChildScrollView(child: _buildSpecialityTab()),
                  SingleChildScrollView(child: _buildBankDetailsTab()),
                  SingleChildScrollView(child: _buildDocumentsTab()),
                  _buildSubscriptionTab(),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
