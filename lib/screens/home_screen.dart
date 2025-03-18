import 'dart:async';
import 'package:attendance/config/app_config.dart';
import 'package:attendance/screens/history_screen.dart';
import 'package:attendance/screens/scanner_screen.dart';
import 'package:attendance/services/mongodb_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  late MongoDBService _mongoDBService;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = "Not connected to database";

  @override
  void initState() {
    super.initState();
    _initializeDatabase(AppConfig);
  }

  Future<void> _initializeDatabase(dynamic appConfig) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = "Connecting to database...";
    });
    try {
      if (_isConnected) await _mongoDBService.close();
      _mongoDBService = MongoDBService(
        mongoUrl: AppConfig.mongoUrl,
        username: AppConfig.mongoUsername,
        password: AppConfig.mongoPassword,
      );
      await _mongoDBService.initialize();
      setState(() {
        _isConnected = true;
        _connectionStatus = "Connected to database";
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "Failed to connect: ${e.toString()}";
      });
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<String?> _scanQRCode(BuildContext context) async {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
  }

  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryScreen(mongoDBService: _mongoDBService),
      ),
    );
  }

  void _handleScanResult(String qrResult) {
    final parts = qrResult.split('_');
    if (parts.length != 2) {
      _showInvalidQRCodeDialog();
      return;
    }
    _showAttendeeDetails(parts[0], parts[1]);
  }

  Future<bool> _markPresent(String registrationNo, String eventName) async {
    try {
      return await _mongoDBService.markStudentPresent(
          registrationNo, eventName);
    } catch (e) {
      debugPrint('Error marking student as present: $e');
      return false;
    }
  }

  void _showAttendeeDetails(String registrationNo, String eventName) async {
    setState(() => _isLoading = true);
    bool isRegistered = false;
    bool isAlreadyPresent = false;
    try {
      isRegistered = await _mongoDBService.isStudentRegistered(registrationNo);
      if (isRegistered) {
        isAlreadyPresent =
            await _mongoDBService.isStudentPresent(registrationNo);
      }
    } catch (e) {
      debugPrint('Error checking student status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Working in offline mode. Data will sync when connection is restored.'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendeeDetailsBottomSheet(
        registrationNo: registrationNo,
        eventName: eventName,
        isAlreadyPresent: isAlreadyPresent,
        isRegistered: isRegistered,
        onMarkPresent: isRegistered
            ? () async {
                bool success = await _markPresent(registrationNo, eventName);
                Navigator.pop(context);
                _showSnackMessage(
                  success
                      ? 'Attendance marked successfully!'
                      : 'Failed to mark attendance. Please try again.',
                  success ? Colors.lightGreen : Colors.red,
                  success ? Icons.check_circle : Icons.error,
                );
              }
            : null,
      ),
    );
  }

  void _showInvalidQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => const InvalidQRCodeDialog(),
    );
    Timer(const Duration(seconds: 5), () {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  void _showSnackMessage(String message, Color bgColor, IconData icon) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 24),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(isSmallScreen ? 8 : 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final mainPadding = isSmallScreen ? 16.0 : 24.0;
    final imageSize = isLandscape
        ? screenSize.height * 0.4
        : (screenSize.width < 600 ? screenSize.width * 0.6 : 300.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Attenda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.lightGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            ConnectionStatusBanner(
              isConnected: _isConnected,
              isConnecting: _isConnecting,
              statusText: _connectionStatus,
              isSmallScreen: isSmallScreen,
              onReconnect: () => _initializeDatabase(AppConfig),
            ),
            Expanded(
              child: isLandscape
                  ? LandscapeContent(
                      mainPadding: mainPadding, imageSize: imageSize)
                  : PortraitContent(
                      mainPadding: mainPadding, imageSize: imageSize),
            ),
            Padding(
              padding: EdgeInsets.all(mainPadding),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: (!_isConnected || _isLoading)
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final result = await _scanQRCode(context);
                            setState(() => _isLoading = false);
                            if (result != null) _handleScanResult(result);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize:
                          Size(double.infinity, isSmallScreen ? 48 : 56),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: isSmallScreen ? 20 : 24,
                            width: isSmallScreen ? 20 : 24,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              !_isConnected
                                  ? 'DATABASE DISCONNECTED'
                                  : 'SCAN QR CODE',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 12),
                  OutlinedButton.icon(
                    onPressed: (!_isConnected || _isLoading)
                        ? null
                        : _navigateToHistory,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreen,
                      side: BorderSide(color: Colors.lightGreen),
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize:
                          Size(double.infinity, isSmallScreen ? 44 : 50),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('VIEW ATTENDANCE HISTORY',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mongoDBService.close();
    super.dispose();
  }
}

class ConnectionStatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String statusText;
  final bool isSmallScreen;
  final VoidCallback onReconnect;

  const ConnectionStatusBanner({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.statusText,
    required this.isSmallScreen,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 6 : 8,
        horizontal: isSmallScreen ? 12 : 16,
      ),
      child: Row(
        children: [
          Icon(isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isConnected ? Colors.green : Colors.red,
              size: isSmallScreen ? 16 : 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color:
                    isConnected ? Colors.green.shade800 : Colors.red.shade800,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ),
          if (isConnecting)
            SizedBox(
              height: isSmallScreen ? 14 : 16,
              width: isSmallScreen ? 14 : 16,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          if (!isConnected && !isConnecting)
            TextButton(
              onPressed: onReconnect,
              style: TextButton.styleFrom(
                padding: isSmallScreen
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : null,
              ),
              child: Text(
                'Reconnect',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
            ),
          if (!isConnecting)
            Tooltip(
              message: 'Refresh connection',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Refreshing database connection...',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.lightGreen,
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    onReconnect();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.refresh,
                      color: isConnected ? Colors.green : Colors.red,
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PortraitContent extends StatelessWidget {
  final double mainPadding;
  final double imageSize;

  const PortraitContent({
    super.key,
    required this.mainPadding,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(mainPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: imageSize,
              width: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(imageSize / 4),
              ),
              child: const Image(
                image: AssetImage('assets/hero.png'),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mark Attendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan a QR code to quickly mark attendance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}

class LandscapeContent extends StatelessWidget {
  final double mainPadding;
  final double imageSize;

  const LandscapeContent({
    super.key,
    required this.mainPadding,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(mainPadding),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  height: imageSize,
                  width: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(imageSize / 4),
                  ),
                  child: const Image(
                    image: AssetImage('assets/hero.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Mark Attendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Scan a QR code to quickly mark attendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendeeDetailsBottomSheet extends StatelessWidget {
  final String registrationNo;
  final String eventName;
  final bool isAlreadyPresent;
  final bool isRegistered;
  final Future<void> Function()? onMarkPresent;

  const AttendeeDetailsBottomSheet({
    super.key,
    required this.registrationNo,
    required this.eventName,
    required this.isAlreadyPresent,
    required this.isRegistered,
    required this.onMarkPresent,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final bottomSheetPadding = isSmallScreen ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(bottomSheetPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              margin: EdgeInsets.only(bottom: bottomSheetPadding * 0.8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Attendee Details',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: bottomSheetPadding * 0.8),
            _buildDetailRow(Icons.badge_outlined, "Reg No.: $registrationNo",
                Colors.lightGreen, isSmallScreen),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildDetailRow(Icons.event, "Event: $eventName", Colors.lightGreen,
                isSmallScreen),
            SizedBox(height: isSmallScreen ? 8 : 12),
            if (!isRegistered)
              _buildDetailRow(Icons.not_interested,
                  "Not registered for this event", Colors.red, isSmallScreen)
            else
              _buildDetailRow(
                isAlreadyPresent ? Icons.check_circle : Icons.pending_outlined,
                isAlreadyPresent
                    ? "Already marked present"
                    : "Not marked present yet",
                isAlreadyPresent ? Colors.green : Colors.orange,
                isSmallScreen,
              ),
            SizedBox(height: bottomSheetPadding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isAlreadyPresent || !isRegistered ? null : onMarkPresent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: Size(double.infinity, isSmallScreen ? 48 : 56),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    !isRegistered
                        ? 'NOT REGISTERED'
                        : isAlreadyPresent
                            ? 'ALREADY PRESENT'
                            : 'MARK PRESENT',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String text, Color color, bool compact) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: color == Colors.lightGreen ? Colors.black : color,
            ),
          ),
        ),
      ],
    );
  }
}

class InvalidQRCodeDialog extends StatelessWidget {
  const InvalidQRCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Colors.red, size: isSmallScreen ? 40 : 50),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Invalid QR Code',
              style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'The QR code format is invalid. Please try scanning a valid code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14, color: Colors.grey),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: Size(double.infinity, isSmallScreen ? 40 : 45),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
