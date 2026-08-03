import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standard AppBar for all trip sub-screens (flights, accoms, expenses, notes, etc.).
/// Uses [Icons.arrow_back_ios_new_rounded] by default; swap to [Icons.close] with [useCloseIcon].
class TripAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TripAppBar({
    super.key,
    required this.title,
    this.actions,
    this.useCloseIcon = false,
    this.onBack,
  });

  final String title;
  final List<Widget>? actions;
  final bool useCloseIcon;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          useCloseIcon ? Icons.close : Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }
}
