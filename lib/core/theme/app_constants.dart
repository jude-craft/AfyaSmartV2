class AppConstants {
  AppConstants._();

  // ── App Info ─────────────────────────────────────────
  static const String appName        = 'AfyaSmart';
  static const String appTagline     = 'Your Intelligent Medical Assistant';
  static const String appVersion     = '1.0.0';

  // ── Asset Paths ──────────────────────────────────────
  static const String assetsImages   = 'assets/images/';

  // ── SharedPreferences Keys ───────────────────────────
  static const String keyThemeMode   = 'theme_mode';
  static const String keyChatHistory = 'chat_history';
  static const String keyUserData    = 'user_data';
  static const String keyIsLoggedIn  = 'is_logged_in';

  // ── AI / Chat ────────────────────────────────────────
  static const String aiName         = 'Afya';
  static const String aiWelcomeMessage =
      'Hello! I\'m Afya, your intelligent medical assistant. '
      'I can help you understand symptoms, medications, medical terms, '
      'and general health guidance. How can I assist you today?';

  static const String aiDisclaimer =
      '⚠️ I provide general health information only. '
      'Always consult a qualified healthcare professional for medical advice, '
      'diagnosis, or treatment.';

  // ── Splash ───────────────────────────────────────────
  static const int splashDurationMs  = 3000;

  // ── UI ───────────────────────────────────────────────
  static const double borderRadiusSmall  = 8.0;
  static const double borderRadiusMedium = 14.0;
  static const double borderRadiusLarge  = 20.0;
  static const double borderRadiusXL     = 28.0;

  static const double paddingXS  = 4.0;
  static const double paddingS   = 8.0;
  static const double paddingM   = 16.0;
  static const double paddingL   = 24.0;
  static const double paddingXL  = 32.0;

  // ── Dummy History Labels ──────────────────────────────
  static const List<String> sampleChatTitles = [
    'Understanding Type 2 Diabetes',
    'Symptoms of Iron Deficiency',
    'What is Hypertension?',
    'Paracetamol vs Ibuprofen',
    'Post-surgery Recovery Tips',
    'COVID-19 Vaccine Side Effects',
    'Managing Anxiety Naturally',
    'Child Vaccination Schedule',
  ];
}