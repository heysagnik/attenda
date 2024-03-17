import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                Navigator.canPop(context) ? Navigator.pop<String>(context, barcode.rawValue ?? 'No data in QR') : null;
              }
            },
          ),
          const QRScannerOverlay(), // Add the overlay widget
        ],
      ),
    );
  }
}

// Assuming you copied the QRScannerOverlay class from the reference
class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double scanArea = screen.width < 400 || screen.height < 400 ? 300.0 : 350.0; // Adjust size as needed

    return Center(
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut), // Transparent overlay
            child: SizedBox(
              width: screen.width,
              height: screen.height,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: scanArea,
              width: scanArea,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 3), // White border
              ),
            ),
          ),
        ],
      ),
    );
  }
}






























































































