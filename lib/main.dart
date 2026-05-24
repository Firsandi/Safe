import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/utils/injection.dart' as di;
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/features/auth/presentation/pages/splash_page.dart';
import 'package:safe/features/auth/data/models/user_model.dart';
import 'package:safe/features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const SafeApp());
}

class SafeApp extends StatelessWidget {
  const SafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LanguageCubit>(),
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: 'SAFE App',
            debugShowCheckedModeBanner: false,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
              useMaterial3: true,
            ),
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

/// Widget yang mengecek session sebelum menampilkan halaman
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _isChecking = true;
  Widget? _targetPage;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // Ubah ke true jika ingin selalu reset session dan masuk ke halaman login/splash saat aplikasi dijalankan kembali (untuk testing)
      bool forceFreshStart = false;
      if (forceFreshStart) {
        await SessionManager.clearSession();
      }

      final isLoggedIn = await SessionManager.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await SessionManager.getUserData();
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          _targetPage = HomePage(user: user);
        }
      }
    } catch (e) {
      debugPrint('Error checking session: $e');
    } finally {
      // Jika belum login atau data tidak valid/error, tampilkan splash
      _targetPage ??= const SplashPage();

      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Tampilkan layar loading singkat saat cek session
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _targetPage!;
  }
}
