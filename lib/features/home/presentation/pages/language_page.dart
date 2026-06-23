import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.languageTitle,
          style: AppTextStyles.heading.copyWith(
            fontSize: 18,
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.languageSelect.toUpperCase(),
                style: AppTextStyles.inputLabel.copyWith(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: BlocBuilder<LanguageCubit, Locale>(
                  builder: (context, locale) {
                    final currentLang = locale.languageCode;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLanguageOption(
                          context: context,
                          flag: '🇮🇩',
                          title: 'Bahasa Indonesia',
                          subtitle: currentLang == 'id' ? 'Bahasa Indonesia' : 'Indonesian',
                          isSelected: currentLang == 'id',
                          onTap: () {
                            context.read<LanguageCubit>().changeLanguage('id');
                            _showLanguageChangedSnackBar(context, 'Bahasa diubah ke Bahasa Indonesia');
                          },
                        ),
                        Divider(height: 1, color: AppColors.inputBorder, indent: 64),
                        _buildLanguageOption(
                          context: context,
                          flag: '🇺🇸',
                          title: 'English',
                          subtitle: currentLang == 'id' ? 'Inggris' : 'English',
                          isSelected: currentLang == 'en',
                          onTap: () {
                            context.read<LanguageCubit>().changeLanguage('en');
                            _showLanguageChangedSnackBar(context, 'Language changed to English');
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'SAFE App v1.0.0',
                  style: AppTextStyles.subHeading.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed.withOpacity(0.08) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Text(
          flag,
          style: const TextStyle(fontSize: 22),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.subHeading.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryRed : AppColors.textDark,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.inputLabel.copyWith(
          color: AppColors.textGrey,
          fontSize: 11,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryRed, size: 24)
          : null,
      onTap: onTap,
    );
  }

  void _showLanguageChangedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF193855),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
