import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool         showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    return message.isUser
        ? _UserBubble(message: message, showTimestamp: showTimestamp)
        : _AiBubble(message: message, showTimestamp: showTimestamp);
  }
}

//  USER BUBBLE
class _UserBubble extends StatelessWidget {
  final MessageModel message;
  final bool         showTimestamp;

  const _UserBubble({required this.message, required this.showTimestamp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Bubble ──────────────────────────────────────
          GestureDetector(
            onLongPress: () => _showOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient:     AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(18),
                  topRight:    Radius.circular(4),
                  bottomLeft:  Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color:      scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color:  AppColors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // ── Timestamp + status ────────────────────────────
          if (showTimestamp) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.messageTime(message.timestamp),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 4),
                _StatusIcon(status: message.status),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context:       context,
      backgroundColor: Colors.transparent,
      builder:       (_) => _BubbleOptionsSheet(content: message.content),
    );
  }
}

//  AI BUBBLE — renders markdown
class _AiBubble extends StatelessWidget {
  final MessageModel message;
  final bool         showTimestamp;

  const _AiBubble({required this.message, required this.showTimestamp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 64, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI Avatar ──────────────────────────────────
          _AiAvatar(),
          const SizedBox(width: 10),

          // ── Bubble + timestamp ─────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _showOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12,
                    ),
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
                    child: MarkdownBody(
                      data: message.content,
                      selectable: true,
                      shrinkWrap: true,
                      softLineBreak: true,
                      styleSheet: _buildMarkdownStyle(
                        context, isDark, textColor,
                      ),
                    ),
                  ),
                ),

                if (showTimestamp) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstants.aiName} · '
                    '${DateFormatter.messageTime(message.timestamp)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a themed MarkdownStyleSheet that matches the app design.
  MarkdownStyleSheet _buildMarkdownStyle(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    final codeBackground = isDark
        ? const Color(0xFF2D333B)
        : const Color(0xFFF0F2F5);
    final codeBorder = isDark
        ? const Color(0xFF444C56)
        : const Color(0xFFD0D7DE);

    return MarkdownStyleSheet(
      // ── Body text ───────────────────────────────────
      p: AppTextStyles.bodyMedium.copyWith(
        color:  textColor,
        height: 1.6,
      ),

      // ── Bold & italic ──────────────────────────────
      strong: AppTextStyles.bodyMedium.copyWith(
        color:      textColor,
        fontWeight: FontWeight.w700,
        height:     1.6,
      ),
      em: AppTextStyles.bodyMedium.copyWith(
        color:     textColor,
        fontStyle: FontStyle.italic,
        height:    1.6,
      ),

      // ── Headings ───────────────────────────────────
      h1: AppTextStyles.headingLarge.copyWith(color: textColor),
      h2: AppTextStyles.headingMedium.copyWith(color: textColor),
      h3: AppTextStyles.headingSmall.copyWith(color: textColor),
      h4: AppTextStyles.bodyLarge.copyWith(
        color: textColor, fontWeight: FontWeight.w600,
      ),
      h5: AppTextStyles.bodyMedium.copyWith(
        color: textColor, fontWeight: FontWeight.w600,
      ),
      h6: AppTextStyles.bodySmall.copyWith(
        color: textColor, fontWeight: FontWeight.w600,
      ),

      // ── Lists ──────────────────────────────────────
      listBullet: AppTextStyles.bodyMedium.copyWith(
        color:  textColor,
        height: 1.6,
      ),
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 16,

      // ── Inline code ────────────────────────────────
      code: AppTextStyles.bodySmall.copyWith(
        color:            isDark ? const Color(0xFFE6EDF3) : const Color(0xFF24292F),
        backgroundColor:  codeBackground,
        fontFamily:       'monospace',
        fontSize:         12.5,
      ),

      // ── Code block ─────────────────────────────────
      codeblockDecoration: BoxDecoration(
        color:        codeBackground,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: codeBorder),
      ),
      codeblockPadding: const EdgeInsets.all(12),

      // ── Block quote ────────────────────────────────
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      blockquote: AppTextStyles.bodyMedium.copyWith(
        color:     textColor.withValues(alpha: 0.75),
        fontStyle: FontStyle.italic,
        height:    1.6,
      ),

      // ── Horizontal rule ────────────────────────────
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),

      // ── Table ──────────────────────────────────────
      tableHead: AppTextStyles.bodyMedium.copyWith(
        color:      textColor,
        fontWeight: FontWeight.w600,
      ),
      tableBody: AppTextStyles.bodyMedium.copyWith(color: textColor),
      tableBorder: TableBorder.all(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

      // ── Spacing ────────────────────────────────────
      pPadding:         const EdgeInsets.only(bottom: 8),
      h1Padding:        const EdgeInsets.only(bottom: 8),
      h2Padding:        const EdgeInsets.only(bottom: 6),
      h3Padding:        const EdgeInsets.only(bottom: 4),
      blockSpacing:     8,
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder:         (_) => _BubbleOptionsSheet(content: message.content),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AI AVATAR
// ─────────────────────────────────────────────────────────
class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// ─────────────────────────────────────────────────────────
//  STATUS ICON
// ─────────────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => const SizedBox(
          width: 10, height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      MessageStatus.sent  => Icon(
          Icons.done_all_rounded,
          size:  13,
          color: AppColors.secondaryLight,
        ),
      MessageStatus.error => const Icon(
          Icons.error_outline_rounded,
          size:  13,
          color: AppColors.error,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────
//  BUBBLE OPTIONS SHEET (long-press)
// ─────────────────────────────────────────────────────────
class _BubbleOptionsSheet extends StatelessWidget {
  final String content;
  const _BubbleOptionsSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return Container(
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
            width:  40, height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color:        scheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          _OptionTile(
            icon:    Icons.copy_rounded,
            label:   'Copy message',
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _OptionTile(
            icon:    Icons.share_rounded,
            label:   'Share',
            onTap:   () => Navigator.pop(context),
          ),
          _OptionTile(
            icon:    Icons.text_increase_rounded,
            label:   'Select text',
            onTap:   () => Navigator.pop(context),
          ),
          const Divider(height: 8),
          _OptionTile(
            icon:    Icons.flag_outlined,
            label:   'Report response',
            color:   AppColors.error,
            onTap:   () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final VoidCallback onTap;
  final Color?    color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c      = color ?? scheme.onSurface;

    return ListTile(
      leading:  Icon(icon, color: c, size: 20),
      title:    Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: c),
      ),
      onTap:    onTap,
      dense:    true,
    );
  }
}