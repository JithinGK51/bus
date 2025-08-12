import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Client client;

  @override
  void initState() {
    super.initState();
    client =
        Client()
          ..setEndpoint('https://fra.cloud.appwrite.io/v1')
          ..setProject('68987fd400282bea0f9d');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Namma Tumkuru',
          theme: themeProvider.currentTheme,
          home: SessionCheckPage(client: client),
          routes: {
            '/login': (context) => LoginPage(client: client),
            '/register': (context) => RegisterPage(client: client),
            '/home': (context) => HomePage(client: client),
          },
        );
      },
    );
  }
}

class SessionCheckPage extends StatelessWidget {
  final Client client;
  const SessionCheckPage({super.key, required this.client});

  Future<bool> _checkSession() async {
    final account = Account(client);
    try {
      await account.get();
      return true; // logged in
    } on AppwriteException catch (e) {
      debugPrint('AppwriteException during session check: ${e.message}');
      return false; // not logged in
    } catch (e) {
      debugPrint('Unexpected error during session check: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Show splash screen regardless of login status
        final Widget nextScreen =
            snapshot.data == true
                ? HomePage(client: client) // ✅ Logged in
                : LoginPage(client: client); // ❌ Not logged in

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SplashScreen(nextScreen: nextScreen),
            ),
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
