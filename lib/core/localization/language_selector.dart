import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        final isEn = locale.languageCode == 'en';
        return TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textDark,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.inputBorder),
            ),
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
          ),
          icon: Text(isEn ? '🇺🇸' : '🇮🇩', style: const TextStyle(fontSize: 16)),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn ? 'EN' : 'ID',
                style: AppTextStyles.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textGrey, size: 18),
            ],
          ),
          onPressed: () => _showLanguageSelector(context, locale.languageCode),
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context, String currentLang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.languageSelect,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇮🇩', style: TextStyle(fontSize: 22)),
                title: const Text(
                  'Bahasa Indonesia',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                trailing: currentLang == 'id'
                    ? const Icon(Icons.check_circle, color: AppColors.primaryRed)
                    : null,
                onTap: () {
                  context.read<LanguageCubit>().changeLanguage('id');
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                title: const Text(
                  'English',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                trailing: currentLang == 'en'
                    ? const Icon(Icons.check_circle, color: AppColors.primaryRed)
                    : null,
                onTap: () {
                  context.read<LanguageCubit>().changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
