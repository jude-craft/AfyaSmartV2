import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/sex_selector.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/diagnosis_card.dart';
import '../../widgets/common/afya_logo.dart';
import '../../widgets/history/history_tile.dart';
import '../profile/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController         _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey      = GlobalKey<ScaffoldState>();
  ChatProvider? _chatProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = context.read<ChatProvider>();
    if (_chatProvider != newProvider) {
      _chatProvider?.removeListener(_onChatChanged);
      _chatProvider = newProvider;
      _chatProvider!.addListener(_onChatChanged);
    }
  }

  void _onChatChanged() {
    // Auto-scroll while streaming so the user sees new tokens
    if (_chatProvider?.isStreaming == true) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _chatProvider?.removeListener(_onChatChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    FocusScope.of(context).unfocus();
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat   = context.watch<ChatProvider>();

    return Scaffold(
      key:    _scaffoldKey,
      drawer: _HistoryDrawer(
        onNewChat: () {
          context.read<ChatProvider>().startNewChat();
          Navigator.pop(context);
        },
      ),
      appBar: _buildAppBar(context, isDark, chat),
      body:   Column(
        children: [
          Expanded(
            child: _MessageList(
              scrollController: _scrollController,
              onScrollToBottom: _scrollToBottom,
            ),
          ),

          if (chat.modeSelected) ...[
            if (chat.isAskingSex)
              SexSelectorBar(
                onSelect: (value) => _sendMessage(value),
              )
            else if (chat.isDiagnosed)
              _DiagnosisFooter(
                onNewChat: () {
                  context.read<ChatProvider>().startNewChat();
                  _scrollToBottom(animated: false);
                },
              )
            else
              ChatInputBar(
                onSend:       _sendMessage,
                isLoading:    chat.isTyping,
                chatMode:     chat.chatMode!,
                symptomStage: chat.symptomStage,
              ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    ChatProvider chat,
  ) {
    final auth = context.watch<AuthProvider>();

    return AppBar(
      leading: IconButton(
        icon:    const Icon(Icons.menu_rounded),
        tooltip: 'History',
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: chat.modeSelected
          ? _ModeBadge(isSymptom: chat.isSymptomMode)
          : const Text('AfyaSmart'),
      actions: [
        // New chat
        IconButton(
          icon:      const Icon(Icons.edit_square),
          tooltip:   'New chat',
          onPressed: () {
            context.read<ChatProvider>().startNewChat();
            _scrollToBottom(animated: false);
          },
        ),
        // Profile avatar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child:   _UserAvatar(user: auth.user),
          ),
        ),
      ],
    );
  }
}
class _ModeBadge extends StatelessWidget {
  final bool isSymptom;
  const _ModeBadge({required this.isSymptom});

  @override
  Widget build(BuildContext context) {
    final color = isSymptom
        ? AppColors.secondaryLight
        : AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSymptom ? '🩺' : '💬',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 6),
          Text(
            isSymptom ? 'Symptom Checker' : 'Free Chat',
            style: AppTextStyles.labelMedium.copyWith(
              color:      color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback     onScrollToBottom;

  const _MessageList({
    required this.scrollController,
    required this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {

        // Loading session from history
        if (chat.isLoadingSession) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading conversation...'),
              ],
            ),
          );
        }

        // No mode selected yet → full empty state
        if (!chat.modeSelected) {
          return _EmptyState();
        }

        // Mode selected but no messages yet → minimal prompt
        if (chat.messages.isEmpty) {
          return _ModeStartPrompt(isSymptom: chat.isSymptomMode);
        }

        return Column(
          children: [
            // Error banner
            if (chat.errorMessage != null)
              _ErrorBanner(
                message:   chat.errorMessage!,
                onDismiss: chat.clearError,
              ),

            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding:    const EdgeInsets.symmetric(vertical: 12),
                itemCount:  _itemCount(chat),
                itemBuilder: (ctx, i) =>
                    _buildItem(ctx, i, chat, onScrollToBottom),
              ),
            ),
          ],
        );
      },
    );
  }

  int _itemCount(ChatProvider chat) {
    // messages + typing indicator + diagnosis card if diagnosed
    return chat.messages.length +
        (chat.isTyping ? 1 : 0) +
        (chat.isDiagnosed ? 1 : 0);
  }

  Widget _buildItem(
    BuildContext context,
    int i,
    ChatProvider chat,
    VoidCallback onScrollToBottom,
  ) {
    final msgCount = chat.messages.length;

    // Typing indicator
    if (chat.isTyping && i == msgCount) {
      return const TypingIndicator();
    }

    // Diagnosis card — appears after all messages
    if (chat.isDiagnosed && i == msgCount + (chat.isTyping ? 1 : 0)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => onScrollToBottom());
      return DiagnosisCard(
        content: chat.diagnosisData?['response'] as String? ?? '',
        onStartNewChat: () => context.read<ChatProvider>().startNewChat(),
      );
    }

    // Normal message bubble
    final msg      = chat.messages[i];
    final isLast   = i == msgCount - 1;
    final showTime = isLast ||
        (i + 1 < msgCount &&
            chat.messages[i + 1].timestamp
                .difference(msg.timestamp)
                .inMinutes > 5);

    return MessageBubble(message: msg, showTimestamp: showTime);
  }
}

// ─────────────────────────────────────────────────────────
//  EMPTY STATE — mode selector cards
// ─────────────────────────────────────────────────────────
String _getGreeting(String? firstName) {
  final hour = DateTime.now().hour;
  final name = firstName ?? 'there';
  if (hour < 12) return 'Good morning,\n$name 👋';
  if (hour < 17) return 'Good afternoon,\n$name 👋';
  return 'Good evening,\n$name 👋';
}

String _getDynamicSubtitle() {
  const list = [
    'How are you feeling today?',
    'What health question is on your mind?',
    'I\'m here to support your health journey.',
    'Ask me anything about your health.',
    'Your wellness matters. How can I help?',
    'Let\'s talk about your health today.',
  ];
  final seed = DateTime.now().hour + DateTime.now().day;
  return list[seed % list.length];
}

class _EmptyState extends StatefulWidget {
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
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
    final auth   = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity:  _fade,
      child:    SlideTransition(
        position: _slide,
        child:    SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          child:   Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Logo badge 
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/logo.png',
                  width:  48,
                  height: 48,
                  fit:    BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              // ── Greeting 
              Text(
                _getGreeting(auth.user?.firstName),
                style: AppTextStyles.displayMedium.copyWith(
                  color:         scheme.onBackground,
                  letterSpacing: -0.5,
                  height:        1.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _getDynamicSubtitle(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: scheme.onBackground.withValues(alpha:0.5),
                ),
              ),

              const SizedBox(height: 36),

              // ── Section label 
              Text(
                'HOW WOULD YOU LIKE TO START?',
                style: AppTextStyles.labelSmall.copyWith(
                  color:         scheme.onBackground.withValues(alpha: 0.4),
                  letterSpacing: 0.9,
                ),
              ),

              const SizedBox(height: 14),

              // ── Mode cards 
              _ModeCard(
                emoji:    '💬',
                title:    'Free Chat',
                subtitle: 'Ask any general health question.\n'
                    'Get instant AI-powered answers.',
                bullets: const [
                  'Medication information',
                  'General health queries',
                  'Understand medical terms',
                ],
                color:   AppColors.primaryLight,
                onTap:   () => context
                    .read<ChatProvider>()
                    .selectMode(ChatMode.freeChat),
              ),

              const SizedBox(height: 12),

              _ModeCard(
                emoji:    '🩺',
                title:    'Symptom Checker',
                subtitle: 'Describe your symptoms and get\n'
                    'a guided AI diagnosis.',
                bullets: const [
                  'Symptom analysis',
                  'Age & sex-aware diagnosis',
                  'Structured health report',
                ],
                color:   AppColors.secondaryLight,
                onTap:   () => context
                    .read<ChatProvider>()
                    .selectMode(ChatMode.symptomChecker),
              ),

              const SizedBox(height: 28),

              // ── Disclaimer 
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size:  13,
                    color: scheme.onBackground.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AfyaSmart provides general health information only. '
                      'Always consult a qualified healthcare professional.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color:  scheme.onBackground.withValues(alpha: 0.35),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  MODE CARD
class _ModeCard extends StatefulWidget {
  final String       emoji;
  final String       title;
  final String       subtitle;
  final List<String> bullets;
  final Color        color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
      vsync:      this,
      duration:   const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color:      widget.color.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset:     const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon 
              Container(
                width:  52,
                height: 52,
                decoration: BoxDecoration(
                  color:        widget.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Text block 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + arrow
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: scheme.onBackground,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size:  18,
                          color: widget.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color:  scheme.onBackground.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bullet points
                    ...widget.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child:   Row(
                          children: [
                            Container(
                              width:  5,
                              height: 5,
                              decoration: BoxDecoration(
                                color:  widget.color,
                                shape:  BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              b,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: scheme.onBackground.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MODE START PROMPT (after mode selected, before first msg)
// ─────────────────────────────────────────────────────────
class _ModeStartPrompt extends StatelessWidget {
  final bool isSymptom;
  const _ModeStartPrompt({required this.isSymptom});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color  = isSymptom
        ? AppColors.secondaryLight
        : AppColors.primaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  64,
              height: 64,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  isSymptom ? '🩺' : '💬',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSymptom
                  ? 'Describe your first symptom'
                  : 'Ask me anything',
              style: AppTextStyles.headingSmall.copyWith(
                color: scheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSymptom
                  ? 'Tell me what you\'re feeling and I\'ll\n'
                    'guide you through a full assessment.'
                  : 'I can help with symptoms, medications,\n'
                    'health tips, and medical questions.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onBackground.withOpacity(0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  DIAGNOSIS FOOTER
// ─────────────────────────────────────────────────────────
class _DiagnosisFooter extends StatelessWidget {
  final VoidCallback onNewChat;
  const _DiagnosisFooter({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      child: SizedBox(
        width:  double.infinity,
        height: 50,
        child:  ElevatedButton.icon(
          onPressed: onNewChat,
          icon:      const Icon(Icons.refresh_rounded, size: 18),
          label:     const Text('Start New Consultation'),
          style:     ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ERROR BANNER
// ─────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      margin:  const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  HISTORY DRAWER
// ─────────────────────────────────────────────────────────
class _HistoryDrawer extends StatelessWidget {
  final VoidCallback onNewChat;
  const _HistoryDrawer({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;
    final history = context.watch<HistoryProvider>();
    final chat    = context.watch<ChatProvider>();

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child:   Row(
                children: [
                  const AfyaLogo(size: LogoSize.small),
                  const Spacer(),
                  IconButton(
                    icon:      const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // New Chat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child:   OutlinedButton.icon(
                onPressed: onNewChat,
                icon:      const Icon(Icons.edit_square, size: 18),
                label:     const Text('New Chat'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Section label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child:   Row(
                children: [
                  Text(
                    'Recent Chats',
                    style: AppTextStyles.labelSmall.copyWith(
                      color:         scheme.onBackground.withOpacity(0.45),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (!history.isEmpty)
                    GestureDetector(
                      onTap: () => _confirmClearAll(context, history),
                      child: Text(
                        'Clear all',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.error.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Session list
            Expanded(
              child: history.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                      ? _DrawerEmptyState()
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<HistoryProvider>().fetchHistory(),
                          child: ListView.builder(
                            padding:   EdgeInsets.zero,
                            itemCount: history.sessions.length,
                            itemBuilder: (_, i) {
                              final session = history.sessions[i];
                              return HistoryTile(
                                session:  session,
                                isActive: chat.activeSession?.id == session.id,
                                onTap: () async {
                                  await context
                                      .read<ChatProvider>()
                                      .loadSession(
                                        session,
                                        context.read<HistoryProvider>(),
                                      );
                                  if (context.mounted) Navigator.pop(context);
                                },
                                onDelete: () => context
                                    .read<HistoryProvider>()
                                    .deleteSession(session.id),
                              );
                            },
                          ),
                        ),
            ),

            const Divider(height: 1),

            // Profile tile
            Consumer<AuthProvider>(
              builder: (_, auth, __) => ListTile(
                leading: _UserAvatar(user: auth.user, size: 34),
                title: Text(
                  auth.user?.name ?? 'Guest',
                  style:    AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  auth.user?.email ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onBackground.withOpacity(0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title:   const Text('Clear All Chats?'),
        content: const Text(
          'All conversation history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              history.clearAll();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _DrawerEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size:  40,
            color: scheme.onBackground.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No conversations yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onBackground.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  USER AVATAR
// ─────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final dynamic user;
  final double  size;
  const _UserAvatar({this.user, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final initials = user?.initials ?? 'G';
    final hasPhoto = user?.photoUrl != null;

    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        gradient:     AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child:        Image.network(user!.photoUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  color:      AppColors.white,
                  fontSize:   size * 0.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
