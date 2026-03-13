import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../providers/chat_provider.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool                 isLoading;
  final ChatMode             chatMode;
  final SymptomStage         symptomStage;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.chatMode,
    required this.symptomStage,
    this.isLoading = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode             _focusNode  = FocusNode();
  bool                        _hasText    = false;

  late final AnimationController _sendBtnCtrl;
  late final Animation<double>   _sendBtnScale;

  // ── Derived state ─────────────────────────────────────
  bool get _isSymptom   => widget.chatMode == ChatMode.symptomChecker;
  bool get _isDiagnosed => widget.symptomStage == SymptomStage.diagnosed;
  bool get _isAskingAge => widget.symptomStage == SymptomStage.askAge;

  // Hint text changes per stage
  String get _hintText {
    if (!_isSymptom) return 'Ask Afya anything...';
    return switch (widget.symptomStage) {
      SymptomStage.collecting => 'Describe your symptom...',
      SymptomStage.askAge     => 'Enter your age (e.g. 28)...',
      SymptomStage.askSex     => '',   // replaced by SexSelectorBar
      SymptomStage.diagnosed  => '',   // input is disabled
    };
  }

  // Accent colour changes in symptom mode
  Color get _accentColor => _isSymptom
      ? AppColors.secondaryLight
      : AppColors.primaryLight;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _sendBtnCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 200),
    );
    _sendBtnScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.elasticOut),
    );
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
      has ? _sendBtnCtrl.forward() : _sendBtnCtrl.reverse();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading || _isDiagnosed) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _sendBtnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // Diagnosed state — input fully replaced
    if (_isDiagnosed) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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
            color: _isSymptom
                ? _accentColor.withOpacity(0.3)
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: _isSymptom ? 1.5 : 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Symptom mode label ─────────────────────────
          if (_isSymptom) ...[
            Row(
              children: [
                Container(
                  width:  6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:  _accentColor,
                    shape:  BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _stageLabelText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Input row ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment/add button (free chat only)
              if (!_isSymptom) ...[
                _IconBtn(
                  icon:  Icons.add_circle_outline_rounded,
                  onTap: () {},
                  color: scheme.onBackground.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
              ],

              // Text field
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: TextField(
                    controller:  _controller,
                    focusNode:   _focusNode,
                    maxLines:    null,
                    minLines:    1,
                    // Lock to number keyboard during age collection
                    keyboardType: _isAskingAge
                        ? TextInputType.number
                        : TextInputType.multiline,
                    inputFormatters: _isAskingAge
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: scheme.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText:  _hintText,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: scheme.onBackground.withOpacity(0.38),
                      ),
                      filled:     true,
                      fillColor:  isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide(
                          color: _isSymptom
                              ? _accentColor.withOpacity(0.3)
                              : (isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide(
                          color: _accentColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Send / Mic button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _hasText
                    ? ScaleTransition(
                        scale: _sendBtnScale,
                        child: _SendButton(
                          onTap:      _send,
                          isLoading:  widget.isLoading,
                          accentColor: _accentColor,
                        ),
                      )
                    : _IconBtn(
                        icon:  Icons.mic_none_rounded,
                        onTap: () {},
                        color: scheme.onBackground.withOpacity(0.4),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _stageLabelText {
    return switch (widget.symptomStage) {
      SymptomStage.collecting => 'Symptom Checker — Describe your symptoms',
      SymptomStage.askAge     => 'Symptom Checker — Enter your age',
      SymptomStage.askSex     => 'Symptom Checker — Select your sex',
      SymptomStage.diagnosed  => 'Diagnosis complete',
    };
  }
}

// ── Send button ───────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool         isLoading;
  final Color        accentColor;

  const _SendButton({
    required this.onTap,
    required this.isLoading,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withOpacity(0.75)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:      accentColor.withOpacity(0.35),
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

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final Color        color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width:  44,
        height: 44,
        child:  Icon(icon, color: color, size: 24),
      ),
    );
  }
}