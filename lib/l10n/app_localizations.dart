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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get navHome;

  /// No description provided for @navLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get navLocation;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get navProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'Set app language preference'**
  String get settingsLanguageSub;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelp;

  /// No description provided for @settingsHelpSub.
  ///
  /// In en, this message translates to:
  /// **'FAQ & Support Contact'**
  String get settingsHelpSub;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT OF SYSTEM'**
  String get logout;

  /// No description provided for @sensorActive.
  ///
  /// In en, this message translates to:
  /// **'Sensor Active — monitoring'**
  String get sensorActive;

  /// No description provided for @helpSentToLocation.
  ///
  /// In en, this message translates to:
  /// **'Help will be dispatched to\nyour current location immediately'**
  String get helpSentToLocation;

  /// No description provided for @historySos.
  ///
  /// In en, this message translates to:
  /// **'SOS History'**
  String get historySos;

  /// No description provided for @emergencyContactsSub.
  ///
  /// In en, this message translates to:
  /// **'3 active'**
  String get emergencyContactsSub;

  /// No description provided for @historySosSub.
  ///
  /// In en, this message translates to:
  /// **'2 events'**
  String get historySosSub;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'This page is not available yet'**
  String get notAvailableYet;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @emergencyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Emergency cancelled — you are safe'**
  String get emergencyCancelled;

  /// No description provided for @alertSent.
  ///
  /// In en, this message translates to:
  /// **'ALERT SENT'**
  String get alertSent;

  /// No description provided for @alertSentDesc.
  ///
  /// In en, this message translates to:
  /// **'Emergency services and contacts have been notified.'**
  String get alertSentDesc;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'BACK TO HOME'**
  String get backToHome;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone number...'**
  String get searchPlaceholder;

  /// No description provided for @contactsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load contacts'**
  String get contactsLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noContactsMatching.
  ///
  /// In en, this message translates to:
  /// **'No contacts match \"{query}\"'**
  String noContactsMatching(String query);

  /// No description provided for @noEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts yet'**
  String get noEmergencyContacts;

  /// No description provided for @addContactsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contacts to be contacted in emergency situations.'**
  String get addContactsInstruction;

  /// No description provided for @noIncomingRequests.
  ///
  /// In en, this message translates to:
  /// **'No incoming requests'**
  String get noIncomingRequests;

  /// No description provided for @incomingRequestsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Incoming requests from other users who want to add you will appear here.'**
  String get incomingRequestsInstruction;

  /// No description provided for @callContact.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callContact;

  /// No description provided for @sendWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp message'**
  String get sendWhatsApp;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @deleteContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get deleteContactTitle;

  /// No description provided for @deleteContactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from emergency contacts?'**
  String deleteContactConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @myContacts.
  ///
  /// In en, this message translates to:
  /// **'My Contacts'**
  String get myContacts;

  /// No description provided for @incomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Incoming Requests'**
  String get incomingRequests;

  /// No description provided for @emergencyContactsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage the list of trusted people during emergency situations.'**
  String get emergencyContactsDesc;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile & Medical'**
  String get editProfileTitle;

  /// No description provided for @editProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Update your photo, personal details and medical history.'**
  String get editProfileSub;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get fullNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get phoneLabel;

  /// No description provided for @bloodTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'BLOOD TYPE'**
  String get bloodTypeLabel;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @medicalHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'MEDICAL HISTORY / ALLERGIES'**
  String get medicalHistoryLabel;

  /// No description provided for @medicalHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Asthma, Peanut Allergy'**
  String get medicalHistoryHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @medicalDataCenter.
  ///
  /// In en, this message translates to:
  /// **'MEDICAL DATA CENTER'**
  String get medicalDataCenter;

  /// No description provided for @bloodTypeCard.
  ///
  /// In en, this message translates to:
  /// **'BLOOD TYPE'**
  String get bloodTypeCard;

  /// No description provided for @allergiesCard.
  ///
  /// In en, this message translates to:
  /// **'ALLERGIES / DISEASE'**
  String get allergiesCard;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageTitle;

  /// No description provided for @languageSelect.
  ///
  /// In en, this message translates to:
  /// **'Select your app language:'**
  String get languageSelect;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(String name);

  /// No description provided for @activeContactsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeContactsCount(int count);

  /// No description provided for @sosHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String sosHistoryCount(int count);

  /// No description provided for @sosActiveBanner.
  ///
  /// In en, this message translates to:
  /// **'SOS ACTIVE'**
  String get sosActiveBanner;

  /// No description provided for @sendingRealtimeLocation.
  ///
  /// In en, this message translates to:
  /// **'Sending your real-time location...'**
  String get sendingRealtimeLocation;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get turnOff;

  /// No description provided for @sosDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'SOS successfully disabled'**
  String get sosDisabledSuccess;

  /// No description provided for @sosDisableFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable SOS: {error}'**
  String sosDisableFailed(String error);

  /// No description provided for @permissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionRequiredTitle;

  /// No description provided for @permissionRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'SAFE requires Location and Notification permissions to monitor your safety and send help in emergencies. Without these, the app cannot protect you.'**
  String get permissionRequiredDesc;

  /// No description provided for @allowPermissionsButton.
  ///
  /// In en, this message translates to:
  /// **'Grant Permissions'**
  String get allowPermissionsButton;

  /// No description provided for @openSettingsInstruction.
  ///
  /// In en, this message translates to:
  /// **'If permissions are not granted, please enable them manually in the App Settings.'**
  String get openSettingsInstruction;

  /// No description provided for @severeShakeDetected.
  ///
  /// In en, this message translates to:
  /// **'Severe Shake Detected'**
  String get severeShakeDetected;

  /// No description provided for @fallDetected.
  ///
  /// In en, this message translates to:
  /// **'Fall Detected'**
  String get fallDetected;

  /// No description provided for @crashImpactDetected.
  ///
  /// In en, this message translates to:
  /// **'Crash & Impact Detected'**
  String get crashImpactDetected;

  /// No description provided for @severeImpactDetected.
  ///
  /// In en, this message translates to:
  /// **'Severe Impact Detected'**
  String get severeImpactDetected;

  /// No description provided for @impactForceLabel.
  ///
  /// In en, this message translates to:
  /// **'IMPACT FORCE'**
  String get impactForceLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get locationLabel;

  /// No description provided for @connectionIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Issues'**
  String get connectionIssuesTitle;

  /// No description provided for @connectionIssuesDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SOS due to connection issues. Your SOS is saved in the offline queue and will sync automatically when your connection is restored.\n\nPlease contact emergency services or your contacts manually if possible.'**
  String get connectionIssuesDesc;
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
