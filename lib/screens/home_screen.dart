// ignore_for_file: avoid_print

import 'package:attendance/screens/scanner_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String qrResult = "You have not scanned a QR";

  Future<String?> _scanQRCode(BuildContext context) async {
    // Navigate to the ScannerPage to initiate scanning
    String? scannedResult; // Declare a variable to store the result

    try {
      scannedResult = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const ScannerPage()),
      );
    } catch (error) {
      // Handle any errors that may arise during navigation or scanning
      print('Error occurred during QR code scanning: $error');
    }

    // Return the scanned QR code data, or null if an error occurred or no data was scanned
    return scannedResult;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        leading: Row(
          children: [
            const SizedBox(width: 10), // Adjust the width for desired spacing
            Image.asset(
              'assets/logo.png',
              width: 40,
            ),
          ],
        ),
        title: const Text('Attenda',
            style: TextStyle(
                color: Colors.lightGreen,
                fontWeight: FontWeight.w900,
                fontSize: 30)),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/hero.png'),
            Center(
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Mark your attendees as ',
                      style: TextStyle(fontSize: 24, color: Colors.black38),
                    ),
                    TextSpan(
                      text: 'present',
                      style: TextStyle(fontSize: 24, color: Colors.lightGreen),
                    ),
                    TextSpan(
                      text: ' ', // Add a space after "present"
                      style: TextStyle(fontSize: 24, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final qrResult = await _scanQRCode(context);
                  if (qrResult != null) {
                    _handleScanResult(qrResult);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: const Text('Scan QR Code'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.lightGreen),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _handleScanResult(String qrResult) {
    final parts = qrResult.split(' ');
    if (parts.length >= 2) {
      _showAttendeeDetails(parts[0], parts.sublist(1).join(' '));
    } else {
      _showInvalidQRCodeDialog();
    }
  }

  void _showAttendeeDetails(String registrationNo, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendee Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reg No.: $registrationNo'),
            const SizedBox(height: 10),
            Text('Name: $name'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInvalidQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Invalid QR code format'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
