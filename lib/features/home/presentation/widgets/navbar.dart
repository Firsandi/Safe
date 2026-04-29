import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class SafeNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SafeNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildNavItem(0, Icons.home, 'BERANDA')),
            Expanded(child: _buildNavItem(1, Icons.contact_page_outlined, 'KONTAK')),
            Expanded(child: _buildNavItem(2, Icons.history, 'RIWAYAT')),
            Expanded(child: _buildNavItem(3, Icons.location_on_outlined, 'LOKASI')),
            Expanded(child: _buildNavItem(4, Icons.person_outline, 'PROFIL')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFEDF4FE),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF193855) : AppColors.inputIconGrey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.inputLabel.copyWith(
                fontSize: 9,
                letterSpacing: 0.5,
                color: isSelected ? const Color(0xFF193855) : AppColors.inputIconGrey,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
