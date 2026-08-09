import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/snackbars.dart';
import 'pro_plan_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _avatarUrl =
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&fit=crop&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(_avatarUrl),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gina',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Singapore, Singapore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            _ProfileMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'My cart',
              onTap: () => showComingSoon(context, 'My cart'),
            ),
            _ProfileMenuTile(
              icon: Icons.confirmation_number_outlined,
              title: 'My bookings',
              onTap: () => showComingSoon(context, 'My bookings'),
            ),
            _ProfileMenuTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Pro plan',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProPlanScreen()),
                );
              },
            ),
            _ProfileMenuTile(
              icon: Icons.folder_special_outlined,
              title: 'Past trips',
              onTap: () => showComingSoon(context, 'Past trips'),
            ),
            _ProfileMenuTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              onTap: () => showComingSoon(context, 'Notifications'),
            ),
            _ProfileMenuTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      showSuccessToast(context, 'Logged out');
    }
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyDark,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
