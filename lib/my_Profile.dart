import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'edit_profile.dart';

class My_Profile extends StatefulWidget {
  const My_Profile({super.key});

  @override
  State<My_Profile> createState() => _My_ProfileState();
}

class _My_ProfileState extends State<My_Profile> {
  List<String> portfolioImages = [];
  List<String> openingHours = [];
  List<String> specialities = [];
  List<String> vendorInfo = [];

  String name = "Shivani Deshmukh";
  String location = "Jalgaon";
  String language = "English";
  String profileImageUrl =
      "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91";

  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        portfolioImages.addAll(pickedFiles.map((e) => e.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Pops current screen from the stack
          },
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined, color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black12),
              ),
              child: const Text('View on GlowVita Salon'),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Text('My profile',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 26)),
                const SizedBox(width: 10),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text("Online",
                      style: GoogleFonts.poppins(
                          color: Colors.green, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text("Edit and manage the content of your online profile",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 22),
            _buildProfileCard(),
            const SizedBox(height: 40),

            // Showcase
            Text("Showcase your Work",
                style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            _buildShowcaseGrid(),

            const SizedBox(height: 40),
            _sectionTitle("Opening Hours"),
            const SizedBox(height: 15),
            openingHours.isEmpty
                ? _buildEmptySection(
              title: "No opening hours",
              description: "Let your clients know when you're available for appointments.",
              imageUrl: "https://cdn-icons-png.flaticon.com/512/2920/2920167.png",
            )
                : _buildOpeningHoursCard(),

            const SizedBox(height: 40),
            _sectionTitle("Vendor Information"),
            const SizedBox(height: 15),
            vendorInfo.isEmpty
                ? _buildEmptySection(
              title: "No vendor info yet",
              description: "Add details like experience, clients, and team size.",
              imageUrl: "https://cdn-icons-png.flaticon.com/512/949/949735.png",
            )
                : _buildInfoCard(vendorInfo),

            const SizedBox(height: 40),
            _sectionTitle("Vendor Information"),
            const SizedBox(height: 15),
            vendorInfo.isEmpty
                ? _buildEmptySection(
              title: "Vendor information missing",
              description: "Add details like experience, clients, and team members.",
              imageUrl: "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
            )
                : _buildInfoCard(vendorInfo),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Spacer(),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(currentName: name),
                      ),
                    );
                  },
                  child: Text("Edit", style: GoogleFonts.poppins(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black12),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            const SizedBox(height: 18),
            Text(name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 4),
            Text("No reviews yet",
                style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 2),
            Text(location, style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 22),
            Container(height: 1, color: Colors.black12),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Languages',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(language,
                    style: GoogleFonts.poppins(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseGrid() {
    if (portfolioImages.isEmpty) {
      return _buildEmptyShowcase();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: portfolioImages.map((imgUrl) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imgUrl.startsWith('http')
                    ? Image.network(imgUrl, fit: BoxFit.cover)
                    : Image.file(File(imgUrl), fit: BoxFit.cover),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _pickMultipleImages,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Add Your Work", style: GoogleFonts.poppins()),
          ),

        ],
      ),
    );
  }

  Widget _buildEmptyShowcase() {
    return Center(
      child: Column(
        children: [
          Image.network(
              "https://cdn-icons-png.flaticon.com/512/1829/1829586.png",
              width: 65,
              height: 65),
          const SizedBox(height: 20),
          Text("No images added",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            "Add your images to your online portfolio that best reflect your\ncreativity and work",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _pickMultipleImages,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Set up now", style: GoogleFonts.poppins(fontSize: 17)),
          ),

        ],
      ),
    );
  }

  Widget _buildOpeningHoursCard() {
    final openingHours = {
      "Mon - Fri": "10:00 AM - 8:00 PM",
      "Sat": "10:00 AM - 6:00 PM",
      "Sun": "Closed",
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: openingHours.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.black54, size: 20),
                    const SizedBox(width: 10),
                    Text(entry.key,
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(entry.value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: entry.value == "Closed"
                            ? Colors.red
                            : Colors.black87)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18));
  }

  Widget _buildInfoCard(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text("• $e", style: GoogleFonts.poppins(fontSize: 15)),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptySection({
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Image.network(imageUrl, width: 60, height: 60),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}
