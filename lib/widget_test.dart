import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final productName = TextEditingController();
  final productCode = TextEditingController();
  final qty = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Generator'), centerTitle: true, backgroundColor: Colors.blueGrey),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _input("Product Name", productName),
            _input("Product Code", productCode, onChanged: (_) => setState(() {})),
            _input("Quantity", qty, keyboard: TextInputType.number),

            const SizedBox(height: 20),

            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: qr.QrImageView(
                  data: productCode.text.isEmpty ? "empty" : productCode.text,
                  size: 150,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final pdf = await TicketPrinter.buildTicket(
                  productName: productName.text,
                  productCode: productCode.text,
                  quantity: qty.text,
                );
                await TicketPrinter.printTicket(pdf);
              },
              child: const Text("Print Ticket", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String title, TextEditingController c, {Function(String)? onChanged, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
    );
  }
}

class TicketPrinter {
  static Future<Uint8List> buildTicket({required String productName, required String productCode, required String quantity}) async {
    final pdf = pw.Document();

    final qrImage = await qr.QrPainter(data: productCode, version: qr.QrVersions.auto, gapless: true).toImageData(220);

    final qrPdfImage = pw.MemoryImage(qrImage!.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.all(6),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(qrPdfImage, width: 100, height: 100),

              // pw.SizedBox(height: 10),

              // pw.Text("XP-4208", style: const pw.TextStyle(fontSize: 7)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printTicket(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
