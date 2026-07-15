import 'package:flutter/material.dart';
import 'features/products/presentation/main_navigation.dart';
import 'features/auth/presentation/login_page.dart';
import 'core/services/api_service.dart';
import 'core/theme/theme_manager.dart';

final ThemeManager themeManager = ThemeManager();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'PhoneStore',
          debugShowCheckedModeBanner: false,
          themeMode: themeManager.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFEF4444),
            scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Gray 100
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEF4444),
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFEF4444),
            scaffoldBackgroundColor: const Color(0xFF030712), // Gray 950
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFEF4444),
              surface: Color(0xFF111827), // Gray 900
              onSurface: Color(0xFFF9FAFB),
            ),
            useMaterial3: true,
          ),
          home: FutureBuilder<bool>(
            future: ApiService.isLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                    ),
                  ),
                );
              }
              if (snapshot.data == true) {
                return const MainNavigation();
              }
              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
