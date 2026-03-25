import 'package:flutter/material.dart';
import '../../../core/theme/app_text_style.dart';

enum LogoSize { small, medium, large }

class AfyaLogo extends StatelessWidget {
  final LogoSize size;
  final bool     showTagline;
  final Color?   textColor;

  const AfyaLogo({
    super.key,
    this.size        = LogoSize.medium,
    this.showTagline = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config(size);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Logo Image ───────────────────────────────────
        Image.asset(
          'assets/images/logo.png',
          width:  cfg.imageSize,
          height: cfg.imageSize,
          fit:    BoxFit.contain,
        ),

        // ── Tagline ───────────────────────────────────────
        if (showTagline) ...[
          SizedBox(height: cfg.gap * 0.6),
          Text(
            'Your Intelligent Medical Assistant',
            style: cfg.taglineStyle.copyWith(
              color: textColor?.withValues(alpha: 0.75) ??
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ── Config helper ─────────────────────────────────────────
class _LogoCfg {
  final double    imageSize;
  final double    gap;
  final TextStyle taglineStyle;

  const _LogoCfg({
    required this.imageSize,
    required this.gap,
    required this.taglineStyle,
  });
}

_LogoCfg _config(LogoSize size) {
  switch (size) {
    case LogoSize.small:
      return _LogoCfg(
        imageSize:    40,
        gap:          6,
        taglineStyle: AppTextStyles.bodySmall,
      );
    case LogoSize.medium:
      return _LogoCfg(
        imageSize:    64,
        gap:          10,
        taglineStyle: AppTextStyles.bodySmall,
      );
    case LogoSize.large:
      return _LogoCfg(
        imageSize:    140,
        gap:          16,
        taglineStyle: AppTextStyles.bodyMedium,
      );
  }
}