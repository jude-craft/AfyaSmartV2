import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/afya_logo.dart';
import '../auth/auth_screen.dart';
import '../chat/chat_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ─────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  // ── Animations ────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _pulse;
  late final Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo entrance
    _logoController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve:  Curves.elasticOut,
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve:  const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text slide up
    _textController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Subtle pulse on logo badge
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bottom progress bar
    _progressController = AnimationController(
      vsync:    this,
      duration: Duration(milliseconds: AppConstants.splashDurationMs - 400),
    );
    _progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    // Step 1: animate logo in
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Step 2: animate tagline in
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    _progressController.forward();

    // Step 3: navigate
    await Future.delayed(
      Duration(milliseconds: AppConstants.splashDurationMs),
    );
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => auth.isAuthenticated
            ? const ChatScreen()
            : const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child:   child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width:      double.infinity,
        height:     double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradientLight,
        ),
        child: Stack(
          children: [
            // ── Decorative circles ─────────────────────────
            Positioned(
              top:   -size.width * 0.25,
              right: -size.width * 0.2,
              child: _DecorativeCircle(
                size:    size.width * 0.7,
                opacity: 0.12,
              ),
            ),
            Positioned(
              bottom: -size.width * 0.2,
              left:   -size.width * 0.15,
              child:  _DecorativeCircle(
                size:    size.width * 0.6,
                opacity: 0.10,
              ),
            ),
            Positioned(
              top:  size.height * 0.15,
              left: size.width  * 0.05,
              child: _DecorativeCircle(
                size:    size.width * 0.2,
                opacity: 0.08,
              ),
            ),

            // ── Main content ───────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with scale + pulse
                  FadeTransition(
                    opacity: _logoOpacity,
                    child:   ScaleTransition(
                      scale: _logoScale,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: const AfyaLogo(
                          size:      LogoSize.large,
                          textColor: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline slide up
                  SlideTransition(
                    position: _textSlide,
                    child:    FadeTransition(
                      opacity: _textOpacity,
                      child:   Text(
                        AppConstants.appTagline,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:       AppColors.white.withOpacity(0.80),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom version + progress ──────────────────
            Positioned(
              bottom: 0,
              left:   0,
              right:  0,
              child:  Column(
                children: [
                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressValue,
                    builder:   (_, __) => LinearProgressIndicator(
                      value:            _progressValue.value,
                      backgroundColor:  AppColors.white.withOpacity(0.2),
                      valueColor:       const AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }
}