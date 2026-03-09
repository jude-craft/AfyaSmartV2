import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/chat_session.dart';

class HistoryTile extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback     onTap;
  final VoidCallback     onDelete;
  final bool             isActive;

  const HistoryTile({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key:             ValueKey(session.id),
      direction:       DismissDirection.endToStart,
      onDismissed:     (_) => onDelete(),
      confirmDismiss:  (_) => _confirmDelete(context),
      background:      _SwipeBackground(),
      child:           _TileContent(
        session:  session,
        onTap:    onTap,
        onDelete: onDelete,
        isActive: isActive,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Chat?'),
        titleTextStyle: AppTextStyles.headingSmall,
        content: Text(
          'This conversation will be permanently deleted.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:     TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TILE CONTENT
// ─────────────────────────────────────────────────────────
class _TileContent extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback     onTap;
  final VoidCallback     onDelete;
  final bool             isActive;

  const _TileContent({
    required this.session,
    required this.onTap,
    required this.onDelete,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: () => _showLongPressMenu(context),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin:   const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary.withOpacity(isDark ? 0.18 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: scheme.primary.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // ── Chat icon ──────────────────────────────────
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withOpacity(0.15)
                      : (isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size:  18,
                  color: isActive
                      ? scheme.primary
                      : scheme.onBackground.withOpacity(0.45),
                ),
              ),
              const SizedBox(width: 12),

              // ── Title & preview ────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isActive
                            ? scheme.primary
                            : scheme.onBackground,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.lastMessagePreview,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onBackground.withOpacity(0.45),
                      ),
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Date ──────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormatter.chatDate(session.updatedAt),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: scheme.onBackground.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.messageCount}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color:      AppColors.white,
                      fontSize:   9,
                    ),
                  ).let((child) => Container(
                    padding:     const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1,
                    ),
                    decoration:  BoxDecoration(
                      color:        scheme.primary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: child,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLongPressMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin:  const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme.onBackground.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                session.title,
                style: AppTextStyles.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 16),
            ListTile(
              leading:  const Icon(Icons.open_in_new_rounded, size: 20),
              title:    Text('Open chat', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
              dense: true,
            ),
            ListTile(
              leading:  const Icon(Icons.edit_outlined, size: 20),
              title:    Text('Rename', style: AppTextStyles.bodyMedium),
              onTap:    () => Navigator.pop(context),
              dense:    true,
            ),
            const Divider(height: 8),
            ListTile(
              leading:  const Icon(
                Icons.delete_outline_rounded,
                size:  20,
                color: AppColors.error,
              ),
              title:    Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SWIPE BACKGROUND
// ─────────────────────────────────────────────────────────
class _SwipeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin:       const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      alignment:    Alignment.centerRight,
      padding:      const EdgeInsets.only(right: 20),
      decoration:   BoxDecoration(
        color:        AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          SizedBox(width: 6),
          Text(
            'Delete',
            style: TextStyle(
              color:      AppColors.error,
              fontSize:   13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Extension helper ──────────────────────────────────────
extension _WidgetLet on Widget {
  Widget let(Widget Function(Widget) fn) => fn(this);
}