import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

class DiagnosisCard extends StatefulWidget {
  final String   content;
  final VoidCallback onStartNewChat;

  const DiagnosisCard({
    super.key,
    required this.content,
    required this.onStartNewChat,
  });

  @override
  State<DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<DiagnosisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child:   SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child:   Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondaryLight.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color:      AppColors.secondaryLight.withOpacity(0.12),
                        blurRadius: 16,
                        offset:     const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondaryLight.withOpacity(
                          isDark ? 0.15 : 0.10,
                        ),
                        AppColors.primaryLight.withOpacity(
                          isDark ? 0.10 : 0.06,
                        ),
                      ],
                      begin: Alignment.centerLeft,
                      end:   Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon badge
                      Container(
                        width:  40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient:     AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '🩺',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diagnosis Result',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: scheme.onBackground,
                              ),
                            ),
                            Text(
                              'AI-generated · Not a medical prescription',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: scheme.onBackground.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Collapse toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _expanded = !_expanded),
                        child: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: scheme.onBackground.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ─────────────────────────────────────
                AnimatedCrossFade(
                  duration:     const Duration(milliseconds: 250),
                  crossFadeState: _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild:  _CardBody(
                    content:       widget.content,
                    onStartNewChat: widget.onStartNewChat,
                  ),
                  secondChild: const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  CARD BODY
// ─────────────────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final String       content;
  final VoidCallback onStartNewChat;

  const _CardBody({
    required this.content,
    required this.onStartNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child:   Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Disclaimer banner ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8,
            ),
            decoration: BoxDecoration(
              color:        AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.error,
                  size:  16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is general health information only. '
                    'Please consult a qualified doctor.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Diagnosis content ─────────────────────────
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color:  scheme.onBackground,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 14),

          // ── Action row ────────────────────────────────
          Row(
            children: [
              // Copy button
              Expanded(
                child: _ActionBtn(
                  icon:  Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:  Text('Diagnosis copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              // New chat button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onStartNewChat,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient:     AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: AppColors.white,
                          size:  18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New Consultation',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.dividerDark
                : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: scheme.onBackground.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: scheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}