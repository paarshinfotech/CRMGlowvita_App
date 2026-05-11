import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import '../billing_invoice_model.dart';
import '../services/api_service.dart';

class InvoiceView extends StatelessWidget {
  final BillingInvoice invoice;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const InvoiceView({
    super.key,
    required this.invoice,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final double subtotal = invoice.subtotal;
    final double discount =
        invoice.items.fold(0.0, (sum, item) => sum + item.discount);
    final double tax = invoice.taxAmount;
    final double platformFee = invoice.platformFee;
    final double total = invoice.totalAmount;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 16, vertical: isMobile ? 6 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          if (showCloseButton)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Invoice Details",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 10 : 12,
                      )),
                  const Spacer(),
                  InkWell(
                    child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.close, size: 20)),
                    onTap: onClose ?? () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
                  )
                ],
              ),
            ),
          // Header with Logo
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 50,
            ),
          ),
          const SizedBox(height: 12),
          // Company Info
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ApiService.vendorProfileNotifier.value?.businessName ??
                            "GlowVita Salon & Spa",
                        style: TextStyle(
                          fontFamily: "Georgia",
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 11 : 13,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ApiService.vendorProfileNotifier.value != null
                            ? "${ApiService.vendorProfileNotifier.value!.address}, ${ApiService.vendorProfileNotifier.value!.city}, ${ApiService.vendorProfileNotifier.value!.state}, ${ApiService.vendorProfileNotifier.value!.pincode}"
                            : "Baner Road, Pune, Pune, Maharashtra, 411045",
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                      Text(
                        "Phone: ${ApiService.vendorProfileNotifier.value?.phone ?? '9876543210'}",
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // Right: Invoice Label
                Text(
                  "INVOICE",
                  style: TextStyle(
                    fontFamily: "Georgia",
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // Section line
          Container(
              height: 2,
              color: Colors.black54,
              margin: const EdgeInsets.symmetric(vertical: 7)),
          // Date/Invoice No row
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Date: ",
                        style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: _invoiceFormatDate(invoice.createdAt),
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Invoice No: ",
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: "#${invoice.invoiceNumber}",
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
          Container(
              height: 2,
              color: Colors.black54,
              margin: const EdgeInsets.symmetric(vertical: 7)),
          // Invoice to
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Invoice To: ",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 10),
                    ),
                    TextSpan(
                      text: invoice.clientInfo.fullName,
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Main Table: Use boxed style to match the image
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.7),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.3),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey[800]!, width: 1),
                outside: BorderSide.none,
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  children: [
                    _cellTxt("ITEM DESCRIPTION",
                        weight: FontWeight.w600, isHeader: true),
                    _cellTxt("₹ PRICE",
                        weight: FontWeight.w600, isHeader: true),
                    _cellTxt("QTY", weight: FontWeight.w600, isHeader: true),
                    _cellTxt("₹ TAX", weight: FontWeight.w600, isHeader: true),
                    _cellTxt("₹ AMOUNT",
                        weight: FontWeight.w600, isHeader: true),
                  ],
                ),
                ...invoice.items.map((item) {
                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[600]!, width: 1),
                      ),
                    ),
                    children: [
                      // Item Description with Add-ons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 10),
                            ),
                            if (item.addOns.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              ...item.addOns.map((addon) => Padding(
                                    padding: const EdgeInsets.only(left: 0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "+ ${addon.name}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              color: Colors.grey[700]),
                                        ),
                                        Text(
                                          "₹${addon.price.toStringAsFixed(0)}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  )),
                            ]
                          ],
                        ),
                      ),
                      _cellTxt("₹${item.price.toStringAsFixed(2)}"),
                      _cellTxt("${item.quantity}"),
                      _cellTxt(
                          "₹${(item.totalPrice * invoice.taxRate / 100).toStringAsFixed(2)}"),
                      _cellTxt("₹${item.totalPrice.toStringAsFixed(2)}",
                          align: TextAlign.right),
                    ],
                  );
                }),
                // empty row for look
                ...List.generate(
                    1,
                    (_) => TableRow(
                          children: List.generate(
                              5, (_) => const SizedBox(height: 18)),
                        )),
                // summary bolds rightmost two columns and label aligns right
                TableRow(
                  children: [
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    _cellTxt("Subtotal:",
                        align: TextAlign.right, weight: FontWeight.w600),
                    _cellTxt("₹${subtotal.toStringAsFixed(2)}",
                        align: TextAlign.right),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    _cellTxt("Discount:",
                        align: TextAlign.right,
                        weight: FontWeight.w600,
                        color: Colors.green[800]),
                    _cellTxt("-₹${discount.toStringAsFixed(2)}",
                        color: Colors.green[800],
                        align: TextAlign.right,
                        weight: FontWeight.w500),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    _cellTxt("Tax (${invoice.taxRate.toStringAsFixed(0)}%):",
                        align: TextAlign.right, weight: FontWeight.w600),
                    _cellTxt("₹${tax.toStringAsFixed(2)}",
                        align: TextAlign.right),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    _cellTxt("Platform Fee:",
                        align: TextAlign.right, weight: FontWeight.w600),
                    _cellTxt("₹${platformFee.toStringAsFixed(2)}",
                        align: TextAlign.right),
                  ],
                ),
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[800]!, width: 1),
                    ),
                  ),
                  children: [
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    _cellTxt("Total:",
                        align: TextAlign.right, weight: FontWeight.bold),
                    _cellTxt("₹${total.toStringAsFixed(2)}",
                        align: TextAlign.right, weight: FontWeight.bold),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Section line: strong & full
          Container(
              height: 2,
              color: Colors.black87,
              margin: const EdgeInsets.symmetric(vertical: 3)),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "Payment Of ₹${total.toStringAsFixed(2)} Received By ${invoice.paymentMethod}",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              "NOTE: This is computer generated receipt and does not require physical signature.",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 8,
                  color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  "Powered by",
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/logo.png',
                  height: 35,
                ),
                const SizedBox(height: 8),
                Text(
                  "www.glowvitasalon.com",
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.print, size: 18),
                label: const Text("Print"),
                onPressed: () => _handlePrint(invoice, context),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Download"),
                onPressed: () => _handlePdfDownload(invoice, context),
              ),
              if (showCloseButton) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child: const Text("Close"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _cellTxt(String text,
          {FontWeight weight = FontWeight.normal,
          TextAlign align = TextAlign.left,
          bool isHeader = false,
          Color? color}) =>
      Padding(
        padding:
            EdgeInsets.symmetric(vertical: isHeader ? 4 : 2, horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(
              fontSize: isHeader ? 9 : 10,
              fontWeight: weight,
              color: color ?? Colors.black87),
        ),
      );

  String _invoiceFormatDate(DateTime dt) {
    return "${_weekday(dt.weekday)}, ${_month(dt.month)} ${dt.day}, ${dt.year}";
  }

  String _weekday(int weekday) {
    const week = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return week[(weekday - 1) % 7];
  }

  String _month(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[(month - 1) % 12];
  }

  Future<void> _handlePrint(
      BillingInvoice invoice, BuildContext context) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error printing PDF: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handlePdfDownload(
      BillingInvoice invoice, BuildContext context) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      final bytes = await pdf.save();

      Directory? downloadsDir;

      if (Platform.isWindows) {
        final home =
            Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (home != null) {
          downloadsDir = Directory('$home\\Downloads');
        }
      } else if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null || !await downloadsDir.exists()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          "invoice_${invoice.invoiceNumber.replaceAll(RegExp(r'[^\w-]'), '_')}.pdf";
      final filePath = "${downloadsDir.path}${Platform.pathSeparator}$fileName";
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invoice saved to: $filePath"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "Open",
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving PDF: $e"),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdfDocument(BillingInvoice invoice) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final double subtotal = invoice.subtotal;
    final double discount =
        invoice.items.fold(0.0, (sum, item) => sum + item.discount);
    final double tax = invoice.taxAmount;
    final double platformFee = invoice.platformFee;
    final double total = invoice.totalAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(logoImage, height: 60),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        ApiService.vendorProfileNotifier.value?.businessName ??
                            "GlowVita Salon & Spa",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          font: boldFont,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        ApiService.vendorProfileNotifier.value != null
                            ? "${ApiService.vendorProfileNotifier.value!.address}, ${ApiService.vendorProfileNotifier.value!.city}, ${ApiService.vendorProfileNotifier.value!.state}, ${ApiService.vendorProfileNotifier.value!.pincode}"
                            : "Baner Road, Pune, Maharashtra, 411045",
                        style: pw.TextStyle(fontSize: 10, font: font),
                      ),
                      pw.Text(
                        "Phone: ${ApiService.vendorProfileNotifier.value?.phone ?? '9876543210'}",
                        style: pw.TextStyle(fontSize: 10, font: font),
                      ),
                    ],
                  ),
                  pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                      font: boldFont,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Date: ",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                        pw.TextSpan(
                          text: DateFormat('EEEE, MMM dd, yyyy')
                              .format(invoice.createdAt),
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Invoice No: ",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            font: boldFont,
                          ),
                        ),
                        pw.TextSpan(
                          text: invoice.invoiceNumber,
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: "Invoice To: ",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                    ),
                    pw.TextSpan(
                      text: invoice.clientInfo.fullName,
                      style: pw.TextStyle(fontSize: 11, font: font),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _pdfCell('ITEM DESCRIPTION',
                          bold: true, font: font, boldFont: boldFont),
                      _pdfCell('₹ PRICE',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('QTY',
                          bold: true,
                          align: pw.TextAlign.center,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹ TAX',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹ AMOUNT',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  ...invoice.items.map((item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.name,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    font: boldFont,
                                  ),
                                ),
                                if (item.addOns.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  ...item.addOns.map((addon) => pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(
                                            "+ ${addon.name}",
                                            style: pw.TextStyle(
                                              fontSize: 9,
                                              color:
                                                  PdfColor.fromHex('#6B7280'),
                                              font: font,
                                            ),
                                          ),
                                          pw.Text(
                                            "₹${addon.price.toStringAsFixed(0)}",
                                            style: pw.TextStyle(
                                              fontSize: 9,
                                              color:
                                                  PdfColor.fromHex('#6B7280'),
                                              font: font,
                                            ),
                                          ),
                                        ],
                                      )),
                                ]
                              ],
                            ),
                          ),
                          _pdfCell('₹${item.price.toStringAsFixed(2)}',
                              align: pw.TextAlign.right,
                              font: font,
                              boldFont: boldFont),
                          _pdfCell('${item.quantity}',
                              align: pw.TextAlign.center,
                              font: font,
                              boldFont: boldFont),
                          _pdfCell(
                              '₹${(item.totalPrice * invoice.taxRate / 100).toStringAsFixed(2)}',
                              align: pw.TextAlign.right,
                              font: font,
                              boldFont: boldFont),
                          _pdfCell('₹${item.totalPrice.toStringAsFixed(2)}',
                              align: pw.TextAlign.right,
                              font: font,
                              boldFont: boldFont),
                        ],
                      )),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Subtotal:',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${subtotal.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Discount:',
                          bold: true,
                          align: pw.TextAlign.right,
                          color: PdfColor.fromHex('#15803D'),
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('-₹${discount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          color: PdfColor.fromHex('#15803D'),
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Tax (${invoice.taxRate.toStringAsFixed(0)}%):',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${tax.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Platform Fee:',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${platformFee.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('', font: font, boldFont: boldFont),
                      _pdfCell('Total:',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                      _pdfCell('₹${total.toStringAsFixed(2)}',
                          bold: true,
                          align: pw.TextAlign.right,
                          font: font,
                          boldFont: boldFont),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 2, color: PdfColors.black),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  "Payment Of ₹${total.toStringAsFixed(2)} Received By ${invoice.paymentMethod}",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    font: boldFont,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "NOTE: THIS IS COMPUTER GENERATED RECEIPT AND DOES NOT REQUIRE PHYSICAL SIGNATURE.",
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('#6B7280'),
                    font: font,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Powered by",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                        color: PdfColor.fromHex('#64748B'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Image(logoImage, height: 40),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "www.glowvitasalon.com",
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColor.fromHex('#64748B'),
                        font: font,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _pdfCell(String text,
      {bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
      PdfColor? color,
      required pw.Font font,
      required pw.Font boldFont}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
          font: bold ? boldFont : font,
        ),
        textAlign: align,
      ),
    );
  }
}
