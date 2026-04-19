import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Access your tactical medical dashboard.'**
  String get loginSubTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCESS PASSWORD'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get loginButton;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register for a new account'**
  String get registerLink;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 SAFE - Emergency Archive'**
  String get copyright;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Setup'**
  String get registerTitle;

  /// No description provided for @stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'STEP 01 OF 02'**
  String get stepIndicator;

  /// No description provided for @profileStatus.
  ///
  /// In en, this message translates to:
  /// **'PROFILE STATUS'**
  String get profileStatus;

  /// No description provided for @initialEntry.
  ///
  /// In en, this message translates to:
  /// **'Initial Entry'**
  String get initialEntry;

  /// No description provided for @basicCredentials.
  ///
  /// In en, this message translates to:
  /// **'BASIC CREDENTIALS'**
  String get basicCredentials;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddress;

  /// No description provided for @mobileId.
  ///
  /// In en, this message translates to:
  /// **'MOBILE ID'**
  String get mobileId;

  /// No description provided for @medicalProfile.
  ///
  /// In en, this message translates to:
  /// **'INITIAL MEDICAL PROFILE'**
  String get medicalProfile;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'BLOOD TYPE'**
  String get bloodType;

  /// No description provided for @criticalAllergies.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL ALLERGIES'**
  String get criticalAllergies;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// No description provided for @legalFooter.
  ///
  /// In en, this message translates to:
  /// **'BY CREATING AN ACCOUNT, YOU AGREE TO OUR TERMS OF SERVICE AND PRIVACY PROTOCOLS. YOUR DATA IS ENCRYPTED AND STORED WITHIN THE SECURE ARCHIVE.'**
  String get legalFooter;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMAND CENTER'**
  String get homeTitle;

  /// No description provided for @sosLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// No description provided for @sosTap.
  ///
  /// In en, this message translates to:
  /// **'HOLD TO ACTIVATE SOS'**
  String get sosTap;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY CONTACTS'**
  String get emergencyContacts;

  /// No description provided for @activeGuardian.
  ///
  /// In en, this message translates to:
  /// **'GUARDIAN STATUS: READY'**
  String get activeGuardian;

  /// No description provided for @recentAlerts.
  ///
  /// In en, this message translates to:
  /// **'RECENT ALERTS'**
  String get recentAlerts;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'NO RECENT THREATS DETECTED'**
  String get noAlerts;

  /// No description provided for @commandInterface.
  ///
  /// In en, this message translates to:
  /// **'COMMAND INTERFACE'**
  String get commandInterface;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SAFE APP'**
  String get appTitle;

  /// No description provided for @monitoringActive.
  ///
  /// In en, this message translates to:
  /// **'Monitoring: Active'**
  String get monitoringActive;

  /// No description provided for @systemOperational.
  ///
  /// In en, this message translates to:
  /// **'System fully operational. We are standing by.'**
  String get systemOperational;

  /// No description provided for @pressHold.
  ///
  /// In en, this message translates to:
  /// **'PRESS & HOLD'**
  String get pressHold;

  /// No description provided for @medicalProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Profile'**
  String get medicalProfileTitle;

  /// No description provided for @vitalsAllergies.
  ///
  /// In en, this message translates to:
  /// **'Vitals & Allergies'**
  String get vitalsAllergies;

  /// No description provided for @emergencyContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContactsTitle;

  /// No description provided for @trustedCircle.
  ///
  /// In en, this message translates to:
  /// **'Trusted Circle'**
  String get trustedCircle;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LOCATION'**
  String get currentLocation;

  /// No description provided for @guardianLinkActive.
  ///
  /// In en, this message translates to:
  /// **'GUARDIAN LINK ACTIVE'**
  String get guardianLinkActive;

  /// No description provided for @accidentDetected.
  ///
  /// In en, this message translates to:
  /// **'ACCIDENT DETECTED!'**
  String get accidentDetected;

  /// No description provided for @notifyingServices.
  ///
  /// In en, this message translates to:
  /// **'Notifying contacts and emergency services in...'**
  String get notifyingServices;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'SECONDS'**
  String get seconds;

  /// No description provided for @swipeUpCancel.
  ///
  /// In en, this message translates to:
  /// **'SWIPE UP TO CANCEL'**
  String get swipeUpCancel;

  /// No description provided for @falseAlarm.
  ///
  /// In en, this message translates to:
  /// **'I AM SAFE / FALSE ALARM'**
  String get falseAlarm;

  /// No description provided for @navStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get navStatus;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'CONTACTS'**
  String get navContacts;

  /// No description provided for @navMedical.
  ///
  /// In en, this message translates to:
  /// **'MEDICAL'**
  String get navMedical;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get navHistory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
