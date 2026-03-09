import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/common/afya_logo.dart';
import '../../widgets/history/history_tile.dart';
import '../profile/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      if (!chat.hasMessages) chat.startNewChat();
    });
  }

  @override
  void dispose() {
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
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key:    _scaffoldKey,
      drawer: _HistoryDrawer(
        onNewChat: () {
          context.read<ChatProvider>().startNewChat();
          Navigator.pop(context);
        },
      ),
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          Expanded(
            child: _MessageList(scrollController: _scrollController),
          ),
          Consumer<ChatProvider>(
            builder: (_, chat, __) => ChatInputBar(
              onSend:    _sendMessage,
              isLoading: chat.isTyping,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final auth = context.watch<AuthProvider>();

    return AppBar(
      leading: IconButton(
        icon:    const Icon(Icons.menu_rounded),
        tooltip: 'History',
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text('AfyaSmart'),
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

// ─────────────────────────────────────────────────────────
//  MESSAGE LIST
// ─────────────────────────────────────────────────────────
class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  const _MessageList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        final messages = chat.messages;

        if (messages.isEmpty) {
          return _EmptyState();
        }

        return ListView.builder(
          controller:  scrollController,
          padding:     const EdgeInsets.symmetric(vertical: 12),
          itemCount:   messages.length + (chat.isTyping ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == messages.length) {
              return const TypingIndicator();
            }

            final msg    = messages[i];
            final isLast = i == messages.length - 1;
            final showTime = isLast ||
                (i + 1 < messages.length &&
                    messages[i + 1].timestamp
                        .difference(msg.timestamp)
                        .inMinutes > 5);

            return MessageBubble(
              message:       msg,
              showTimestamp: showTime,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  GREETING HELPERS
// ─────────────────────────────────────────────────────────
String _getGreeting(String? firstName) {
  final hour = DateTime.now().hour;
  final name = firstName ?? 'there';
  if (hour < 12) return 'Good morning,\n$name 👋';
  if (hour < 17) return 'Good afternoon,\n$name 👋';
  return 'Good evening,\n$name 👋';
}

String _getDynamicSubtitle() {
  const subtitles = [
    'How are you feeling today?',
    'What health question is on your mind?',
    'I\'m here to support your health journey.',
    'Ask me anything about your health.',
    'Your wellness matters. How can I help?',
    'Let\'s talk about your health today.',
    'Ready to assist with your medical questions.',
    'What would you like to understand better?',
  ];
  final seed = DateTime.now().hour + DateTime.now().day;
  return subtitles[seed % subtitles.length];
}

// ─────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────
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

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve:  Curves.easeOut,
    );
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
      opacity: _fade,
      child:   SlideTransition(
        position: _slide,
        child:    SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          child:   Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── AfyaSmart logo badge ──────────────────────
              Container(
                width:  48,
                height: 48,
                decoration: BoxDecoration(
                  gradient:     AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '✚',
                    style: TextStyle(
                      fontSize: 22,
                      color:    AppColors.white,
                      height:   1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Dynamic greeting ──────────────────────────
              Text(
                _getGreeting(auth.user?.firstName),
                style: AppTextStyles.displayMedium.copyWith(
                  color:         scheme.onBackground,
                  letterSpacing: -0.5,
                  height:        1.2,
                ),
              ),

              const SizedBox(height: 8),

              // ── Dynamic subtitle ──────────────────────────
              Text(
                _getDynamicSubtitle(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: scheme.onBackground.withOpacity(0.5),
                ),
              ),

              const SizedBox(height: 36),

              // ── 2×2 Action cards ─────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon:  '🩺',
                      title: 'Understand\nSymptoms',
                      color: const Color(0xFF1A6BCC),
                      onTap: () => context
                          .read<ChatProvider>()
                          .sendMessage(
                            'Help me understand my symptoms',
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon:  '💊',
                      title: 'Medication\nGuidance',
                      color: const Color(0xFF00A896),
                      onTap: () => context
                          .read<ChatProvider>()
                          .sendMessage(
                            'I need guidance on medications',
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon:  '🍎',
                      title: 'Nutrition\n& Wellness',
                      color: const Color(0xFF7B61FF),
                      onTap: () => context
                          .read<ChatProvider>()
                          .sendMessage(
                            'Give me nutrition and wellness advice',
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon:  '🧪',
                      title: 'Explain Lab\nResults',
                      color: const Color(0xFFE5822A),
                      onTap: () => context
                          .read<ChatProvider>()
                          .sendMessage(
                            'Help me understand my lab results',
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Disclaimer strip ──────────────────────────
              _DisclaimerStrip(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ACTION CARD
// ─────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final String       icon;
  final String       title;
  final Color        color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync:      this,
      duration:   const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.forward(),
      onTapUp:     (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: ()  => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: Container(
          height:  130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset:     const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colored icon bubble ────────────────────────
              Container(
                width:  42,
                height: 42,
                decoration: BoxDecoration(
                  color:        widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const Spacer(),

              // ── Title ──────────────────────────────────────
              Text(
                widget.title,
                style: AppTextStyles.labelMedium.copyWith(
                  color:      scheme.onBackground,
                  height:     1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              // ── Tap hint ───────────────────────────────────
              Row(
                children: [
                  Text(
                    'Start chat',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size:  11,
                    color: widget.color,
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

// ─────────────────────────────────────────────────────────
//  DISCLAIMER STRIP
// ─────────────────────────────────────────────────────────
class _DisclaimerStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size:  13,
          color: scheme.onBackground.withOpacity(0.3),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'AfyaSmart provides general health information only. '
            'Always consult a qualified healthcare professional.',
            style: AppTextStyles.bodySmall.copyWith(
              color:  scheme.onBackground.withOpacity(0.35),
              height: 1.5,
            ),
          ),
        ),
      ],
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
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
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

            // ── New Chat button ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton.icon(
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

            // ── Section label ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
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

            // ── Session list ───────────────────────────────────
            Expanded(
              child: history.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                      ? _DrawerEmptyState()
                      : ListView.builder(
                          padding:     EdgeInsets.zero,
                          itemCount:   history.sessions.length,
                          itemBuilder: (_, i) {
                            final session = history.sessions[i];
                            return HistoryTile(
                              session:  session,
                              isActive: chat.activeSession?.id == session.id,
                              onTap: () {
                                context
                                    .read<ChatProvider>()
                                    .loadSession(session);
                                Navigator.pop(context);
                              },
                              onDelete: () => context
                                  .read<HistoryProvider>()
                                  .deleteSession(session.id),
                            );
                          },
                        ),
            ),

            const Divider(height: 1),

            // ── Profile tile ───────────────────────────────────
            Consumer<AuthProvider>(
              builder: (_, auth, __) => ListTile(
                leading: _UserAvatar(user: auth.user, size: 34),
                title: Text(
                  auth.user?.name ?? 'Guest',
                  style: AppTextStyles.labelMedium,
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

// ─────────────────────────────────────────────────────────
//  DRAWER EMPTY STATE
// ─────────────────────────────────────────────────────────
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