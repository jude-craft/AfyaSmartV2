import 'package:flutter/material.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_style.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final AnimationController _shimmerController;

  // ── Animations
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
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve:  Curves.elasticOut,
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve:  const Interval(0.0, 0.4, curve: Curves.easeIn),
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
      begin: const Offset(0, 0.3),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Subtle pulse on logo
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
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

    // Shimmer on logo glow
    _shimmerController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  Future<void> _startSequence() async {
    // Step 1: animate logo in
    await Future.delayed(const Duration(milliseconds: 250));
    _logoController.forward();

    // Step 2: animate tagline in
    await Future.delayed(const Duration(milliseconds: 700));
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
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:        (_, animation, __) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
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
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width:  double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),  // deep dark
              Color(0xFF0A1628),  // navy-dark
              Color(0xFF0F2537),  // dark teal undertone
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient glow behind logo ──────────────────
            Positioned(
              top:  size.height * 0.28,
              left: size.width * 0.15,
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (_, __) {
                  final shimVal = _shimmerController.value;
                  return Container(
                    width:  size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondaryLight.withValues(
                            alpha: 0.08 + 0.04 * shimVal,
                          ),
                          AppColors.primaryLight.withValues(
                            alpha: 0.04 + 0.02 * shimVal,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Subtle decorative rings ───────────────────
            Positioned(
              top:   -size.width * 0.2,
              right: -size.width * 0.15,
              child: _DecorativeRing(
                diameter: size.width * 0.5,
                color:    AppColors.secondaryLight.withValues(alpha: 0.06),
              ),
            ),
            Positioned(
              bottom: size.height * 0.15,
              left:   -size.width * 0.12,
              child: _DecorativeRing(
                diameter: size.width * 0.35,
                color:    AppColors.primaryLight.withValues(alpha: 0.05),
              ),
            ),

            // ── Main content ──────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo image with scale + pulse
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width:  160,
                          height: 160,
                          fit:    BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline slide up
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Text(
                        AppConstants.appTagline,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:         AppColors.white.withValues(alpha: 0.60),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom progress + version ─────────────────
            Positioned(
              bottom: 0,
              left:   0,
              right:  0,
              child: Column(
                children: [
                  // Thin gradient progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: AnimatedBuilder(
                      animation: _progressValue,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 3,
                          child: LinearProgressIndicator(
                            value:           _progressValue.value,
                            backgroundColor: AppColors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Decorative ring ──────────────────────────────────────
class _DecorativeRing extends StatelessWidget {
  final double diameter;
  final Color  color;

  const _DecorativeRing({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
    );
  }
}