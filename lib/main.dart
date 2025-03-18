import 'package:flutter/material.dart';
import 'package:attendance/screens/welcome_screen.dart';
import 'package:attendance/services/mongodb_service.dart';
import 'package:attendance/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mongoDBService = MongoDBService(
      mongoUrl: AppConfig.mongoUrl,
      username: AppConfig.mongoUsername,
      password: AppConfig.mongoPassword,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attenda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: WelcomeScreen(mongoDBService: mongoDBService),
    );
  }
}
