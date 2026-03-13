import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

class SexSelectorBar extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const SexSelectorBar({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left:   16,
        right:  16,
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please select your biological sex:',
            style: AppTextStyles.labelMedium.copyWith(
              color: scheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SexButton(
                  emoji:   '👨',
                  label:   'Male',
                  color:   const Color(0xFF1A6BCC),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelect('Male');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SexButton(
                  emoji:   '👩',
                  label:   'Female',
                  color:   const Color(0xFF00A896),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelect('Female');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SexButton extends StatefulWidget {
  final String       emoji;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _SexButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SexButton> createState() => _SexButtonState();
}

class _SexButtonState extends State<_SexButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color:        widget.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(
              color: widget.color.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color:      widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}