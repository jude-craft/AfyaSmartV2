import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/auth/auth_screen.dart';
import 'ui/screens/chat/chat_screen.dart';

class AfyaSmartApp extends StatelessWidget {
  const AfyaSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title:                      'AfyaSmart',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.lightTheme,
      darkTheme:                  AppTheme.darkTheme,
      themeMode:                  themeProvider.themeMode,
      home:                       const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/auth':   (_) => const AuthScreen(),
        '/chat':   (_) => const ChatScreen(),
      },
    );
  }
}

// Auth gate — shown after splash 
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // While Firebase is resolving auth state show a loader
    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return auth.isAuthenticated
        ? const ChatScreen()
        : const AuthScreen();
  }
}