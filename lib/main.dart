import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'theme/nothflows_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI for Nothing aesthetic
  NothFlowsTheme.configureSystemUI();

  // Initialize storage
  await StorageService().initialise();

  runApp(const NothFlowsApp());
}

class NothFlowsApp extends StatelessWidget {
  const NothFlowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NothFlows',
      debugShowCheckedModeBanner: false,

      // Apply Nothing-inspired theme
      theme: NothFlowsTheme.lightTheme,
      darkTheme: NothFlowsTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark for Nothing aesthetic

      home: const SplashScreen(),
    );
  }
}
