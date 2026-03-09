import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/afya_logo.dart';
import '../../widgets/common/afya_button.dart';
import '../chat/chat_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double>    _fadeIn;
  late final Animation<Offset>    _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve:  Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:        (_, a, __) => const ChatScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child:   SlideTransition(
            position: _slideUp,
            child:    Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child:   Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo ────────────────────────────────────
                  const AfyaLogo(
                    size:        LogoSize.large,
                    showTagline: true,
                  ),

                  const Spacer(flex: 2),

                  // ── Welcome card ─────────────────────────────
                  _WelcomeCard(size: size),

                  const Spacer(flex: 1),

                  // ── Error message ─────────────────────────────
                  if (auth.hasError) ...[
                    _ErrorBanner(message: auth.errorMessage ?? 'An error occurred'),
                    const SizedBox(height: 16),
                  ],

                  // ── Google button ─────────────────────────────
                  GoogleSignInButton(
                    onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                    isLoading: auth.isLoading,
                  ),

                  const SizedBox(height: 14),

                  // ── Divider ───────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child:   Text(
                        'Secure & Private',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: scheme.onBackground.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ]),

                  const SizedBox(height: 14),

                  // ── Trust badges ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _TrustBadge(icon: Icons.lock_outline_rounded,    label: 'Encrypted'),
                      SizedBox(width: 20),
                      _TrustBadge(icon: Icons.verified_user_outlined,   label: 'HIPAA Ready'),
                      SizedBox(width: 20),
                      _TrustBadge(icon: Icons.privacy_tip_outlined,     label: 'Private'),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Disclaimer ────────────────────────────────
                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    style:     AppTextStyles.bodySmall.copyWith(
                      color:  scheme.onBackground.withValues(alpha: 0.45),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Welcome card ──────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final Size size;
  const _WelcomeCard({required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset:     const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to AfyaSmart',
            style: AppTextStyles.headingMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get instant, reliable medical guidance powered by AI. '
            'Ask questions, understand symptoms, and make informed health decisions.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // ── Feature pills ─────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FeaturePill(label: '🩺 Symptom Checker'),
              _FeaturePill(label: '💊 Medication Info'),
              _FeaturePill(label: '📋 Health Guidance'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        isDark
            ? AppColors.secondaryDark.withValues(alpha: 0.12)
            : AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: isDark
              ? AppColors.secondaryDark
              : AppColors.secondaryLight,
        ),
      ),
    );
  }
}

// ── Trust badge ───────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: scheme.onBackground.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}