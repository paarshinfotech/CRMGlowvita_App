import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportHelper {
  /// Exports data to an Excel file.
  static Future<void> exportToExcel({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel[sheetName];

      // Add Headers
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
        );
      }

      // Add Data Rows
      for (var r = 0; r < rows.length; r++) {
        for (var c = 0; c < rows[r].length; c++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
          var val = rows[r][c];
          if (val is num) {
            cell.value = DoubleCellValue(val.toDouble());
          } else {
            cell.value = TextCellValue(val?.toString() ?? '');
          }
        }
      }

      // Remove default sheet
      if (sheetName != 'Sheet1') {
        excel.delete('Sheet1');
      }

      final fileBytes = excel.save();
      if (fileBytes == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName.xlsx";
      final file = File(path);
      await file.writeAsBytes(fileBytes);

      await OpenFile.open(path);
    } catch (e) {
      debugPrint('Export to Excel error: $e');
      rethrow;
    }
  }

  /// Exports data to a CSV file.
  static Future<void> exportToCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      List<List<dynamic>> csvData = [headers, ...rows];
      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName.csv";
      final file = File(path);
      await file.writeAsString(csv);

      await OpenFile.open(path);
    } catch (e) {
      debugPrint('Export to CSV error: $e');
      rethrow;
    }
  }

  /// Exports data to a PDF file.
  static Future<void> exportToPdf({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            child: pw.Text(title, style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)),
          ),
          footer: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.mm),
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)),
          ),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: headers,
              data: rows.map((row) => row.map((cell) => cell.toString()).toList()).toList(),
              cellHeight: 30,
              cellAlignments: {
                for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      debugPrint('Export to PDF error: $e');
      rethrow;
    }
  }

  /// Copies data to clipboard.
  static Future<void> copyToClipboard({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      StringBuffer sb = StringBuffer();
      sb.writeln(headers.join('\t'));
      for (var row in rows) {
        sb.writeln(row.join('\t'));
      }
      await Clipboard.setData(ClipboardData(text: sb.toString()));
    } catch (e) {
      debugPrint('Copy to Clipboard error: $e');
      rethrow;
    }
  }

  /// Prints the report.
  static Future<void> printReport({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    await exportToPdf(title: title, headers: headers, rows: rows);
  }

  /// Executes export based on type.
  static Future<void> executeExport(
    String type, {
    required String fileName,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    switch (type) {
      case 'copy':
        await copyToClipboard(headers: headers, rows: rows);
        break;
      case 'excel':
        await exportToExcel(fileName: fileName, sheetName: 'Data', headers: headers, rows: rows);
        break;
      case 'csv':
        await exportToCsv(fileName: fileName, headers: headers, rows: rows);
        break;
      case 'pdf':
        await exportToPdf(title: title, headers: headers, rows: rows);
        break;
      case 'print':
        await printReport(title: title, headers: headers, rows: rows);
        break;
    }
  }
}
