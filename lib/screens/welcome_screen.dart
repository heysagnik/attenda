import 'package:flutter/material.dart';
import 'package:attendance/services/mongodb_service.dart';
import 'package:attendance/screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final MongoDBService mongoDBService;

  const WelcomeScreen({Key? key, required this.mongoDBService})
      : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isError = false;
  List<String> _collections = [];
  String? _selectedCollection;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _loadCollections();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final savedCollection = await widget.mongoDBService.loadSavedCollection();
      final collections = await widget.mongoDBService.getCollectionNames();

      setState(() {
        _collections = collections;
        _selectedCollection = savedCollection;

        if (_selectedCollection != null &&
            !_collections.contains(_selectedCollection)) {
          _selectedCollection = null;
        }
      });
    } catch (e) {
      setState(() => _isError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _continueToApp() async {
    if (_selectedCollection != null) {
      setState(() => _isLoading = true);

      await widget.mongoDBService.setCurrentCollection(_selectedCollection!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo and title
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    "assets/hero.png",
                    height: 150,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "ATTENDA",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Attendance made simple",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 50),

                // Content card
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Please select an event to continue",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Collection selection or loading/error states
                          Expanded(
                            child: Center(
                              child: _isLoading
                                  ? const _LoadingIndicator()
                                  : _isError
                                      ? _ErrorState(onRetry: _loadCollections)
                                      : _collections.isEmpty
                                          ? _NoCollectionsState(
                                              onRefresh: _loadCollections)
                                          : _CollectionSelector(
                                              collections: _collections,
                                              selectedCollection:
                                                  _selectedCollection,
                                              onChanged: (value) {
                                                setState(() =>
                                                    _selectedCollection =
                                                        value);
                                              },
                                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Continue button
                _ContinueButton(
                  isEnabled:
                      _selectedCollection != null && !_isLoading && !_isError,
                  isLoading: _isLoading && _selectedCollection != null,
                  onPressed: _continueToApp,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.lightGreen.shade400,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Loading events...",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(Icons.wifi_off, color: Colors.red.shade400, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          "Connection Error",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Could not connect to database",
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text("Try Again"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoCollectionsState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NoCollectionsState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(40),
          ),
          child:
              Icon(Icons.folder_off, color: Colors.orange.shade400, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          "No Events Found",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Please create collections in MongoDB first",
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionSelector extends StatelessWidget {
  final List<String> collections;
  final String? selectedCollection;
  final Function(String?) onChanged;

  const _CollectionSelector({
    required this.collections,
    required this.selectedCollection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Event",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedCollection,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.lightGreen),
                iconSize: 24,
                hint: const Text(
                  "Select an event",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                items: collections.map((String collection) {
                  return DropdownMenuItem<String>(
                    value: collection,
                    child: Text(
                      collection,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // Optional: adjust the padding inside each dropdown item if needed
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: isEnabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "CONTINUE",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
