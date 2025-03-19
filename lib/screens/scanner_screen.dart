import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for compute()
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:tuple/tuple.dart';

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
    _subscription = controller.barcodes.listen((barcodeCapture) async {
      if (!_barcodeDetected && barcodeCapture.barcodes.isNotEmpty) {
        final code = barcodeCapture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          _barcodeDetected = true;
          await _processScannedCode(code);
        }
      }
    });
  }

  void _unsubscribeBarcode() {
    _subscription?.cancel();
    _subscription = null;
  }

  // Updated method to decrypt QR code asynchronously using compute()
  Future<void> _processScannedCode(String encryptedCode) async {
    debugPrint(encryptedCode);
    try {
      const defaultKey = 'your-secret-key';

      // Offload decryption using a background isolate
      final decryptedCode = await compute(_decryptUsingLogic, {
        'data': encryptedCode,
        'key': defaultKey,
      });
      debugPrint('Decrypted code: $decryptedCode');

      // Use underscore as delimiter per your format "23BCE11649_IPLAUDICTION"
      final parts = decryptedCode.split('_');
      if (parts.length != 2) {
        _showInvalidQRCodeDialog();
        return;
      }

      Navigator.pop(context, {
        'encrypted': encryptedCode,
        'decrypted': decryptedCode,
        'registrationNo': parts[0],
        'eventName': parts[1],
      });
    } catch (e) {
      debugPrint('Decryption error: $e');
      _showInvalidQRCodeDialog();
    }
  }

  // Updated decryption logic using AES CBC mode with key/IV derivation.
  static String _decryptUsingLogic(Map<String, dynamic> args) {
    final data = args['data'] as String;
    final passphrase = args['key'] as String;
    try {
      // Decode data from Base64
      Uint8List encryptedBytesWithSalt = base64.decode(data);
      // "Salted__" is the first 8 bytes; next 8 bytes is salt.
      Uint8List salt = encryptedBytesWithSalt.sublist(8, 16);
      // The actual encrypted bytes start at index 16.
      Uint8List encryptedBytes =
          encryptedBytesWithSalt.sublist(16, encryptedBytesWithSalt.length);
      // Derive key and IV using the provided passphrase and salt.
      Tuple2<Uint8List, Uint8List> keyAndIV = _deriveKeyAndIV(passphrase, salt);
      final key = encrypt.Key(keyAndIV.item1);
      final iv = encrypt.IV(keyAndIV.item2);

      final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: "PKCS7"));

      // Since decrypt64 expects Base64, re-encode the encrypted payload.
      final decrypted =
          encrypter.decrypt64(base64.encode(encryptedBytes), iv: iv);
      if (decrypted.isEmpty) throw Exception('Invalid key or data');
      return decrypted;
    } catch (e) {
      return 'Decryption failed: Invalid key or data';
    }
  }

  static Tuple2<Uint8List, Uint8List> _deriveKeyAndIV(
      String passphrase, Uint8List salt) {
    // Convert passphrase into a Uint8List.
    final password = _createUint8ListFromString(passphrase);
    Uint8List concatenatedHashes = Uint8List(0);
    Uint8List currentHash = Uint8List(0);
    bool enoughBytes = false;
    Uint8List preHash;
    while (!enoughBytes) {
      if (currentHash.isNotEmpty) {
        preHash = Uint8List.fromList(currentHash + password + salt);
      } else {
        preHash = Uint8List.fromList(password + salt);
      }
      currentHash = Uint8List.fromList(md5.convert(preHash).bytes);
      concatenatedHashes = Uint8List.fromList(concatenatedHashes + currentHash);
      if (concatenatedHashes.length >= 48) {
        enoughBytes = true;
      }
    }
    final keyBytes = concatenatedHashes.sublist(0, 32);
    final ivBytes = concatenatedHashes.sublist(32, 48);
    return Tuple2(keyBytes, ivBytes);
  }

  static Uint8List _createUint8ListFromString(String s) {
    return Uint8List.fromList(s.codeUnits);
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
          MobileScanner(controller: controller),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
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
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              height: 250,
              width: 250,
              child: Stack(
                children: [
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
        ],
      ),
    );
  }
}
