import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

class AfyaButton extends StatelessWidget {
  final String      label;
  final VoidCallback? onPressed;
  final Widget?     icon;
  final bool        isLoading;
  final bool        outlined;
  final Color?      backgroundColor;
  final Color?      foregroundColor;
  final double?     width;

  const AfyaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading      = false,
    this.outlined       = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bgColor = backgroundColor ??
        (outlined ? Colors.transparent : scheme.primary);
    final fgColor = foregroundColor ??
        (outlined ? scheme.primary : AppColors.white);

    final content = isLoading
        ? SizedBox(
            width:  20,
            height: 20,
            child:  CircularProgressIndicator(
              strokeWidth: 2.5,
              color:       fgColor,
            ),
          )
        : Row(
            mainAxisSize:     MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: fgColor),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: outlined
          ? BorderSide(color: scheme.primary, width: 1.5)
          : BorderSide.none,
    );

    return SizedBox(
      width:  width ?? double.infinity,
      height: 54,
      child:  outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style:     OutlinedButton.styleFrom(
                foregroundColor: fgColor,
                side:            BorderSide(color: scheme.primary, width: 1.5),
                shape:           shape,
                backgroundColor: bgColor,
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style:     ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                elevation:       0,
                shape:           shape,
              ),
              child: content,
            ),
    );
  }
}

// ── Google-branded button ─────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool          isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width:  double.infinity,
      height: 54,
      child:  Material(
        color:        isDark ? const Color(0xFF1E2329) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child:        InkWell(
          onTap:        isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child:        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                width: 1.5,
              ),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width:  22,
                      height: 22,
                      child:  CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google "G" logo drawn with text — no asset needed
                      _GoogleGIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  24,
      height: 24,
      child:  CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip to circle
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: radius),
        Radius.circular(radius),
      ),
    );

    // White background
    canvas.drawCircle(
      center, radius,
      Paint()..color = Colors.white,
    );

    // Draw simplified Google G segments
    final segments = [
      (Colors.red,    -0.15, 1.1),
      (Colors.yellow,  1.1,  2.2),
      (Colors.green,   2.2,  3.3),
      (Colors.blue,    3.3,  5.1),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color       = seg.$1 as Color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap   = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        seg.$2,
        (seg.$3) - (seg.$2),
        false,
        paint,
      );
    }

    // White cutout for G crossbar
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - size.height * 0.12,
        radius * 0.85,
        size.height * 0.24,
      ),
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}