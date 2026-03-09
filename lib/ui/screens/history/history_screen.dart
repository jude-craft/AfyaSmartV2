import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/chat_session.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../widgets/history/history_tile.dart';
import '../chat/chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double>   _fadeIn;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });

    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Filter sessions by search query ───────────────────
  List<ChatSessionModel> _filtered(List<ChatSessionModel> sessions) {
    if (_query.isEmpty) return sessions;
    return sessions
        .where((s) => s.title.toLowerCase().contains(_query) ||
            s.lastMessagePreview.toLowerCase().contains(_query))
        .toList();
  }

  // ── Group sessions by date label ───────────────────────
  Map<String, List<ChatSessionModel>> _grouped(
    List<ChatSessionModel> sessions,
  ) {
    final map = <String, List<ChatSessionModel>>{};
    for (final s in sessions) {
      final label = DateFormatter.chatDate(s.updatedAt);
      map.putIfAbsent(label, () => []).add(s);
    }
    return map;
  }

  void _openSession(ChatSessionModel session) {
    context.read<ChatProvider>().loadSession(session);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:        (_, a, __) => const ChatScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Clear All History?'),
        titleTextStyle: AppTextStyles.headingSmall,
        content: Text(
          'Every conversation will be permanently deleted. '
          'This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onBackground
                .withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<HistoryProvider>().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final history = context.watch<HistoryProvider>();

    final filtered = _filtered(history.sessions);
    final grouped  = _grouped(filtered);
    final groups   = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          if (!history.isEmpty)
            IconButton(
              icon:      const Icon(Icons.delete_sweep_outlined),
              tooltip:   'Clear all',
              color:     AppColors.error,
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // ── Search bar ─────────────────────────────────
            _SearchBar(controller: _searchController),

            // ── Stats strip ────────────────────────────────
            if (!history.isEmpty)
              _StatsStrip(totalSessions: history.sessions.length),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: history.isLoading
                  ? const _LoadingState()
                  : history.isEmpty
                      ? const _FullEmptyState()
                      : filtered.isEmpty
                          ? _NoResultsState(query: _query)
                          : _GroupedList(
                              groups:   groups,
                              grouped:  grouped,
                              onTap:    _openSession,
                              onDelete: (id) => context
                                  .read<HistoryProvider>()
                                  .deleteSession(id),
                              activeChatId: context
                                  .watch<ChatProvider>()
                                  .activeSession
                                  ?.id,
                            ),
            ),
          ],
        ),
      ),

      // ── FAB — new chat ─────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<ChatProvider>().startNewChat();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:        (_, a, __) => const ChatScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        icon:            const Icon(Icons.add_rounded),
        label:           const Text('New Chat'),
        backgroundColor: scheme.primary,
        foregroundColor: AppColors.white,
        elevation:       2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final scheme  = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller:  controller,
        style: AppTextStyles.bodyMedium.copyWith(
          color: scheme.onBackground,
        ),
        decoration: InputDecoration(
          hintText:    'Search conversations...',
          prefixIcon:  Icon(
            Icons.search_rounded,
            color: scheme.onBackground.withOpacity(0.4),
            size:  20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: controller.clear,
                  child: Icon(
                    Icons.cancel_rounded,
                    color: scheme.onBackground.withOpacity(0.4),
                    size: 18,
                  ),
                )
              : null,
          filled:     true,
          fillColor:  isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          hintStyle:  AppTextStyles.bodyMedium.copyWith(
            color: scheme.onBackground.withOpacity(0.38),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   BorderSide(
              color: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   BorderSide(
              color: scheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  STATS STRIP
// ─────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int totalSessions;
  const _StatsStrip({required this.totalSessions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondaryDark.withOpacity(0.08)
            : AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size:  16,
            color: AppColors.secondaryLight,
          ),
          const SizedBox(width: 8),
          Text(
            '$totalSessions conversation${totalSessions == 1 ? '' : 's'} saved',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.secondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            'Swipe left to delete',
            style: AppTextStyles.labelSmall.copyWith(
              color: scheme.onBackground.withOpacity(0.35),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.swipe_left_alt_rounded,
            size:  14,
            color: scheme.onBackground.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  GROUPED LIST
// ─────────────────────────────────────────────────────────
class _GroupedList extends StatelessWidget {
  final List<String>                        groups;
  final Map<String, List<ChatSessionModel>> grouped;
  final ValueChanged<ChatSessionModel>      onTap;
  final ValueChanged<String>               onDelete;
  final String?                            activeChatId;

  const _GroupedList({
    required this.groups,
    required this.grouped,
    required this.onTap,
    required this.onDelete,
    this.activeChatId,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding:     const EdgeInsets.only(bottom: 96),
      itemCount:   groups.length,
      itemBuilder: (_, groupIdx) {
        final label    = groups[groupIdx];
        final sessions = grouped[label]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Group header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child:   Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color:         scheme.onBackground.withOpacity(0.45),
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // ── Sessions in group ────────────────────────────
            ...sessions.map(
              (session) => HistoryTile(
                session:  session,
                isActive: session.id == activeChatId,
                onTap:    () => onTap(session),
                onDelete: () => onDelete(session.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  STATE WIDGETS
// ─────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding:     const EdgeInsets.all(16),
      itemCount:   6,
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
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

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin:  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : AppColors.dividerLight)
              .withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width:  36, height: 36,
              decoration: BoxDecoration(
                color: (isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight).withOpacity(_anim.value),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width:  double.infinity,
                    decoration: BoxDecoration(
                      color: (isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight).withOpacity(_anim.value),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width:  160,
                    decoration: BoxDecoration(
                      color: (isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight).withOpacity(_anim.value * 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullEmptyState extends StatelessWidget {
  const _FullEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child:   Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color:        scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size:  36,
                color: scheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: AppTextStyles.headingSmall.copyWith(
                color: scheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat and your conversations\nwill appear here.',
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

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child:   Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size:  48,
              color: scheme.onBackground.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: AppTextStyles.headingSmall.copyWith(
                color: scheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onBackground.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}