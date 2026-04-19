import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/l10n/app_localizations.dart';

class SentinelBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SentinelBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: AppTextStyles.inputLabel.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.inputLabel.copyWith(fontSize: 10),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_moderator),
            label: l10n.navStatus,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: l10n.navContacts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_ind_outlined),
            label: l10n.navMedical,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
        ],
      ),
    );
  }
}
