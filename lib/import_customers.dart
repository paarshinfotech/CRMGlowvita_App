import 'dart:io'; // Needed for File type
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImportCustomers extends StatefulWidget {
  const ImportCustomers({super.key});

  @override
  State<ImportCustomers> createState() => _ImportCustomersState();
}

class _ImportCustomersState extends State<ImportCustomers> {
  // State variables to manage the import process
  String _importType = 'CSV';
  PlatformFile? _pickedFile;
  bool _isImporting = false;

  // Function to open the file picker
  Future<void> _pickFile() async {
    // Define allowed extensions based on the selected import type
    final allowedExtensions = _importType == 'CSV' ? ['csv'] : ['vcf'];

    // Use the file_picker package to select a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    } else {
      // User canceled the picker
    }
  }

  // Function to simulate the import process
  Future<void> _startImport() async {
    if (_pickedFile == null) return; // Guard clause

    setState(() => _isImporting = true);

    // Simulate a network call or heavy processing
    await Future.delayed(const Duration(seconds: 3));

    setState(() => _isImporting = false);

    // Show a success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_pickedFile!.name} imported successfully!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      // Reset the state after successful import
      setState(() {
        _pickedFile = null;
      });
    }
  }

  // A helper widget for building section titles to reduce repetition
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the import button should be enabled
    final bool canImport = _pickedFile != null && !_isImporting;

    return Scaffold(
      appBar: AppBar(
        title: Text('Import Customers', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "Import from a File",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Import your existing client list from a Google Contacts CSV or a standard vCard/VCF file.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),

            // --- Step 1: Select File Type ---
            _buildSectionTitle("1. Select File Type"),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('CSV (from Google Contacts)'),
                    value: 'CSV',
                    groupValue: _importType,
                    onChanged: (value) => setState(() => _importType = value!),
                    activeColor: Colors.blue,
                  ),
                   Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    title: const Text('vCard / .vcf (Standard)'),
                    value: 'vCard',
                    groupValue: _importType,
                    onChanged: (value) => setState(() => _importType = value!),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),

            // --- Step 2: Choose File ---
            _buildSectionTitle("2. Choose File"),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file, color: Colors.blue,),
              label: Text("Select File..."),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_pickedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Material(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.teal),
                    title: Text(_pickedFile!.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _pickedFile = null),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // --- Step 3: Import Button ---
            ElevatedButton(
              onPressed: canImport ? _startImport : null, // Disables button if conditions aren't met
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                // Apply a different style when disabled
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _isImporting
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : const Text(
                "IMPORT CUSTOMERS",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}