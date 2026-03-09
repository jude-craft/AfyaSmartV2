import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
        // ── Icon Badge ───────────────────────────────────
        Container(
          width:  cfg.badgeSize,
          height: cfg.badgeSize,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(cfg.badgeSize * 0.28),
            boxShadow: [
              BoxShadow(
                color:      AppColors.primaryLight.withValues(alpha: 0.35),
                blurRadius: cfg.badgeSize * 0.4,
                offset:     Offset(0, cfg.badgeSize * 0.12),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '✚',
              style: TextStyle(
                fontSize: cfg.iconSize,
                color:    AppColors.white,
                height:   1,
              ),
            ),
          ),
        ),

        SizedBox(height: cfg.gap),

        // ── App Name ─────────────────────────────────────
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text:  'Afya',
                style: cfg.nameStyle.copyWith(
                  color: textColor ??
                      Theme.of(context).colorScheme.onBackground,
                ),
              ),
              TextSpan(
                text:  'Smart',
                style: cfg.nameStyle.copyWith(
                  color: AppColors.secondaryLight,
                ),
              ),
            ],
          ),
        ),

        // ── Tagline ───────────────────────────────────────
        if (showTagline) ...[
          SizedBox(height: cfg.gap * 0.6),
          Text(
            'Your Intelligent Medical Assistant',
            style: cfg.taglineStyle.copyWith(
              color: textColor?.withValues(alpha: 0.75) ??
                  Theme.of(context).colorScheme.onBackground.withValues(alpha: 0.55),
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
  final double    badgeSize;
  final double    iconSize;
  final double    gap;
  final TextStyle nameStyle;
  final TextStyle taglineStyle;

  const _LogoCfg({
    required this.badgeSize,
    required this.iconSize,
    required this.gap,
    required this.nameStyle,
    required this.taglineStyle,
  });
}

_LogoCfg _config(LogoSize size) {
  switch (size) {
    case LogoSize.small:
      return _LogoCfg(
        badgeSize:    36,
        iconSize:     16,
        gap:          6,
        nameStyle:    AppTextStyles.headingSmall,
        taglineStyle: AppTextStyles.bodySmall,
      );
    case LogoSize.medium:
      return _LogoCfg(
        badgeSize:    52,
        iconSize:     22,
        gap:          10,
        nameStyle:    AppTextStyles.headingLarge,
        taglineStyle: AppTextStyles.bodySmall,
      );
    case LogoSize.large:
      return _LogoCfg(
        badgeSize:    80,
        iconSize:     34,
        gap:          16,
        nameStyle:    AppTextStyles.displayMedium,
        taglineStyle: AppTextStyles.bodyMedium,
      );
  }
}