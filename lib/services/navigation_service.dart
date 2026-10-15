import 'package:flutter/material.dart';
import '../login_screen.dart';

/// Global Navigation Service for managing context-free navigation and 401 unauthenticated redirects
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static bool _isNavigating = false;

  /// Redirect user to LoginScreen upon session expiration / 401
  static void navigateToLogin({String? message}) {
    if (_isNavigating) return;
    _isNavigating = true;

    final state = navigatorKey.currentState;
    if (state != null) {
      state.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      Future.delayed(const Duration(seconds: 2), () {
        _isNavigating = false;
      });

      final ctx = navigatorKey.currentContext;
      if (ctx != null && message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
