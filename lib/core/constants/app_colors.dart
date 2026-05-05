import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF0D1257);

  // Accent
  static const Color accent = Color(0xFFFF6F00);
  static const Color accentLight = Color(0xFFFF9800);
  static const Color accentDark = Color(0xFFE65100);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF2FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFFDE7);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFFE1F5FE);

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF3949AB);

  // Divider
  static const Color divider = Color(0xFFF3F4F6);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Group status colors
  static const Color groupActive = Color(0xFF1565C0);
  static const Color groupCompleted = Color(0xFF2E7D32);
  static const Color groupExpired = Color(0xFF757575);
  static const Color groupPending = Color(0xFFF57F17);

  // Pricing tier colors
  static const Color tier1 = Color(0xFF1A237E);
  static const Color tier2 = Color(0xFF1565C0);
  static const Color tier3 = Color(0xFF0277BD);
  static const Color tierUnlocked = Color(0xFF2E7D32);

  // Chat
  static const Color chatBubbleSent = Color(0xFF1A237E);
  static const Color chatBubbleReceived = Color(0xFFEEF2FF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dealCardGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF283593)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
