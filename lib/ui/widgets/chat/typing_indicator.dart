import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_style.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>>   _animations  = [];

  static const int    _dotCount  = 3;
  static const double _dotSize   = 7.0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _dotCount; i++) {
      final ctrl = AnimationController(
        vsync:    this,
        duration: const Duration(milliseconds: 500),
      );
      final anim = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
      _controllers.add(ctrl);
      _animations.add(anim);

      // Stagger each dot
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 64, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              gradient:     AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '✚',
                style: TextStyle(
                  fontSize: 14,
                  color:    AppColors.white,
                  height:   1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.aiBubbleDark
                  : AppColors.aiBubbleLight,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(4),
                topRight:    Radius.circular(18),
                bottomLeft:  Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dots row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_dotCount, (i) {
                    return AnimatedBuilder(
                      animation: _animations[i],
                      builder:   (_, __) => Container(
                        margin:    const EdgeInsets.symmetric(horizontal: 3),
                        transform: Matrix4.translationValues(
                          0, _animations[i].value, 0,
                        ),
                        width:  _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color:  AppColors.primaryLight.withValues(alpha: 0.7),
                          shape:  BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.aiName} is thinking...',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}