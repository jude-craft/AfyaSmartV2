import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_style.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/user_model.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final theme  = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [

          // ── Avatar + name card ────────────────────────────
          _ProfileHeader(user: auth.user),

          const SizedBox(height: 24),

          // ── Account section ───────────────────────────────
          _SectionLabel(label: 'ACCOUNT'),
          _SettingsTile(
            icon:     Icons.person_outline_rounded,
            label:    'Display Name',
            trailing: Text(
              auth.user?.name ?? 'Guest',
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onBackground.withOpacity(0.5),
              ),
            ),
            onTap: () {},
          ),
          _SettingsTile(
            icon:     Icons.email_outlined,
            label:    'Email',
            trailing: Text(
              auth.user?.email ?? '—',
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onBackground.withOpacity(0.5),
              ),
            ),
            onTap: () {},
          ),
          _SettingsTile(
            icon:     Icons.verified_user_outlined,
            label:    'Account Type',
            trailing: _PlanBadge(label: 'Free'),
            onTap:    () {},
          ),

          const SizedBox(height: 8),

          // ── Appearance section ────────────────────────────
          _SectionLabel(label: 'APPEARANCE'),
          _SettingsTile(
            icon:  Icons.dark_mode_outlined,
            label: 'Theme',
            trailing: _ThemeToggleRow(
              current:  theme.themeMode,
              onSelect: theme.setThemeMode,
            ),
            onTap: () {},
            showChevron: false,
          ),

          const SizedBox(height: 8),

          // ── Data section ──────────────────────────────────
          _SectionLabel(label: 'DATA & PRIVACY'),
          _SettingsTile(
            icon:  Icons.history_rounded,
            label: 'Chat History',
            trailing: Consumer<HistoryProvider>(
              builder: (_, h, __) => Text(
                '${h.sessions.length} chats',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: scheme.onBackground.withOpacity(0.5),
                ),
              ),
            ),
            onTap: () {},
          ),
          _SettingsTile(
            icon:     Icons.delete_outline_rounded,
            label:    'Clear All History',
            color:    AppColors.error,
            onTap: () => _confirmClearHistory(context),
            showChevron: false,
          ),
          _SettingsTile(
            icon:  Icons.download_outlined,
            label: 'Export My Data',
            onTap: () {},
          ),
          _SettingsTile(
            icon:  Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),

          const SizedBox(height: 8),

          // ── About section ─────────────────────────────────
          _SectionLabel(label: 'ABOUT'),
          _SettingsTile(
            icon:     Icons.info_outline_rounded,
            label:    'App Version',
            trailing: Text(
              'v${AppConstants.appVersion}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onBackground.withOpacity(0.5),
              ),
            ),
            onTap:       () {},
            showChevron: false,
          ),
          _SettingsTile(
            icon:  Icons.star_outline_rounded,
            label: 'Rate AfyaSmart',
            onTap: () {},
          ),
          _SettingsTile(
            icon:  Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () {},
          ),

          const SizedBox(height: 8),

          // ── Medical disclaimer card ───────────────────────
          _DisclaimerCard(),

          const SizedBox(height: 8),

          // ── Sign out ──────────────────────────────────────
          _SectionLabel(label: ''),
          _SignOutTile(onTap: () => _confirmSignOut(context, auth)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────
  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Clear History?'),
        titleTextStyle: AppTextStyles.headingSmall,
        content: Text(
          'All conversation history will be permanently deleted.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onBackground
                .withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out?'),
        titleTextStyle: AppTextStyles.headingSmall,
        content: Text(
          'You will be returned to the login screen.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onBackground
                .withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:     const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder:        (_, a, __) => const AuthScreen(),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (_) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PROFILE HEADER
// ─────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final initials = user?.initials ?? 'G';
    final hasPhoto = user?.photoUrl != null;

    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          // ── Avatar ─────────────────────────────────────────
          Stack(
            children: [
              Container(
                width:  72,
                height: 72,
                decoration: BoxDecoration(
                  gradient:     AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color:      AppColors.primaryLight.withOpacity(0.3),
                      blurRadius: 12,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: hasPhoto
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          user!.photoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
              ),
              // Edit badge
              Positioned(
                right:  0,
                bottom: 0,
                child: Container(
                  width:  22,
                  height: 22,
                  decoration: BoxDecoration(
                    color:        scheme.primary,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size:  11,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // ── Info ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Guest User',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: scheme.onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'Not signed in',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onBackground.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Member since
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size:  12,
                      color: AppColors.secondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user != null
                          ? 'Member since ${_formatJoinDate(user!.createdAt)}'
                          : 'Not a member',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color:         scheme.onBackground.withOpacity(0.4),
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SETTINGS TILE
// ─────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final Widget?   trailing;
  final VoidCallback onTap;
  final Color?    color;
  final bool      showChevron;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final c       = color ?? scheme.onBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child:   Material(
        color:        isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width:  34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (color ?? scheme.primary).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color ?? scheme.primary, size: 18),
                ),
                const SizedBox(width: 14),

                // Label
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(color: c),
                  ),
                ),

                // Trailing
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 6),
                ],
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    size:  18,
                    color: scheme.onBackground.withOpacity(0.3),
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
//  THEME TOGGLE ROW
// ─────────────────────────────────────────────────────────
class _ThemeToggleRow extends StatelessWidget {
  final ThemeMode                current;
  final ValueChanged<ThemeMode>  onSelect;

  const _ThemeToggleRow({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeChip(
          icon:     Icons.light_mode_outlined,
          label:    'Light',
          selected: current == ThemeMode.light,
          onTap:    () => onSelect(ThemeMode.light),
        ),
        const SizedBox(width: 6),
        _ThemeChip(
          icon:     Icons.dark_mode_outlined,
          label:    'Dark',
          selected: current == ThemeMode.dark,
          onTap:    () => onSelect(ThemeMode.dark),
        ),
        const SizedBox(width: 6),
        _ThemeChip(
          icon:     Icons.brightness_auto_outlined,
          label:    'Auto',
          selected: current == ThemeMode.system,
          onTap:    () => onSelect(ThemeMode.system),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : (isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? scheme.primary
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size:  13,
              color: selected
                  ? AppColors.white
                  : scheme.onBackground.withOpacity(0.5),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected
                    ? AppColors.white
                    : scheme.onBackground.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PLAN BADGE
// ─────────────────────────────────────────────────────────
class _PlanBadge extends StatelessWidget {
  final String label;
  const _PlanBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient:     AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color:    AppColors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MEDICAL DISCLAIMER CARD
// ─────────────────────────────────────────────────────────
class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.error,
            size:  18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.aiDisclaimer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SIGN OUT TILE
// ─────────────────────────────────────────────────────────
class _SignOutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Material(
        color:        isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width:  34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:        AppColors.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size:  18,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Sign Out',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}