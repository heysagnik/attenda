import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _barcodeDetected = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(
      autoStart: false,
      torchEnabled: _isTorchOn,
    );
    _subscribeBarcode();
    controller.start();
  }

  void _subscribeBarcode() {
    _subscription = controller.barcodes.listen((barcodeCapture) {
      if (!_barcodeDetected && barcodeCapture.barcodes.isNotEmpty) {
        final code = barcodeCapture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          _barcodeDetected = true;
          _processScannedCode(code);
        }
      }
    });
  }

  void _unsubscribeBarcode() {
    _subscription?.cancel();
    _subscription = null;
  }

  
  void _processScannedCode(String code) {
    final parts = code.split('_');
    if (parts.length != 2) {
      _showInvalidQRCodeDialog();
      return;
    }
   
    Navigator.pop(context, code);
  }

  void _showInvalidQRCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                "Invalid QR Code",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The scanned QR code format is invalid.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _barcodeDetected = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        _subscribeBarcode();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _unsubscribeBarcode();
        controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeBarcode();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
                controller.toggleTorch();
              });
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Scanner
          MobileScanner(controller: controller),

          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Cut-out for QR scanner
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.lightGreen, width: 3),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),

          // Corner indicators
          Center(
            child: SizedBox(
              height: 250,
              width: 250,
              child: Stack(
                children: [
                  // Top left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.lightGreen, width: 3),
                          left: BorderSide(color: Colors.lightGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                  // Top right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.lightGreen, width: 3),
                          right: BorderSide(color: Colors.lightGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                  // Bottom left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.lightGreen, width: 3),
                          left: BorderSide(color: Colors.lightGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                  // Bottom right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.lightGreen, width: 3),
                          right: BorderSide(color: Colors.lightGreen, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info panel with icon
        ],
      ),
    );
  }
}
