import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool                 isLoading;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller  = TextEditingController();
  final FocusNode             _focusNode   = FocusNode();
  bool                        _hasText     = false;

  late final AnimationController _sendBtnController;
  late final Animation<double>   _sendBtnScale;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    _sendBtnController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 200),
    );
    _sendBtnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.elasticOut),
    );
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
      has ? _sendBtnController.forward() : _sendBtnController.reverse();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left:   12,
        right:  12,
        top:    10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Attachment button ──────────────────────────
          _IconBtn(
            icon:    Icons.add_circle_outline_rounded,
            onTap:   () {},
            tooltip: 'Attach',
          ),
          const SizedBox(width: 6),

          // ── Text field ─────────────────────────────────
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: TextField(
                controller:  _controller,
                focusNode:   _focusNode,
                maxLines:    null,
                minLines:    1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: scheme.onBackground,
                ),
                decoration: InputDecoration(
                  hintText:        'Ask Afya anything...',
                  hintStyle:       AppTextStyles.bodyMedium.copyWith(
                    color: scheme.onBackground.withValues(alpha: 0.38),
                  ),
                  filled:          true,
                  fillColor:       isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  contentPadding:  const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10,
                  ),
                  border:          OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:   BorderSide.none,
                  ),
                  enabledBorder:   OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:   BorderSide(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                  ),
                  focusedBorder:   OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:   BorderSide(
                      color: scheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ── Send / Mic button ──────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _hasText
                ? ScaleTransition(
                    scale: _sendBtnScale,
                    child: _SendButton(
                      onTap:     _send,
                      isLoading: widget.isLoading,
                    ),
                  )
                : _IconBtn(
                    icon:    Icons.mic_none_rounded,
                    onTap:   () {},
                    tooltip: 'Voice',
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool         isLoading;

  const _SendButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  44,
        height: 44,
        decoration: BoxDecoration(
          gradient:     AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:      AppColors.primaryLight.withValues(alpha: 0.4),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child:   CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       AppColors.white,
                ),
              )
            : const Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.white,
                size:  22,
              ),
      ),
    );
  }
}

// ── Icon button helper ────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final String       tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child:   GestureDetector(
        onTap:  onTap,
        child:  SizedBox(
          width:  44,
          height: 44,
          child:  Icon(icon, color: scheme.onBackground.withValues(alpha: 0.5), size: 24),
        ),
      ),
    );
  }
}