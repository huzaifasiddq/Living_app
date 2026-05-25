import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Admin/AdminDashboard.dart';
import 'package:my_app/Admin/ManageChallengesScreen.dart';
import 'package:my_app/Admin/ManageProductsScreen.dart';
import 'package:my_app/Admin/ManageRecipesScreen.dart';
import 'package:my_app/MainScreen.dart';
import 'package:my_app/Screens/LoginScreen.dart';
import 'package:my_app/Screens/ProfileScreen.dart';
import 'package:my_app/Screens/SplashScreen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const EatcnobityApp(),
    ),
  );
}

class EatcnobityApp extends StatelessWidget {
  const EatcnobityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        "/Login": (context) => const LoginScreen(),
        "/Profile": (context) => const ProfileScreen(),
        '/user-management': (_) => const ManageUsersScreen(),
        '/product-management': (_) => const ManageProductsScreen(),
        '/recipe-management': (_) => const ManageRecipesScreen(),
        '/challenge-management': (_) => const ManageChallengesScreen(),
        '/content-manager': (_) =>
            const PlaceholderScreen(title: 'Content Manager'),
        '/community-posts': (_) =>
            const PlaceholderScreen(title: 'Community Posts'),
        '/reports-analytics': (_) =>
            const PlaceholderScreen(title: 'Reports & Analytics'),
        '/eco-tips-manager': (_) =>
            const PlaceholderScreen(title: 'Eco Tips Manager'),
        '/feedback-queries': (_) =>
            const PlaceholderScreen(title: 'Feedback & Queries'),
        '/admin-profile': (_) =>
            const PlaceholderScreen(title: 'Admin Profile'),
      },
    );
  }
}
