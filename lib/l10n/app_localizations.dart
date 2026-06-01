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

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginWelcome;

  /// No description provided for @loginWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email and password'**
  String get loginWelcomeSub;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogle;

  /// No description provided for @noAccountText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountText;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @fillEmailPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in email and password'**
  String get fillEmailPasswordError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Email format must contain @'**
  String get invalidEmailError;

  /// No description provided for @enterEmailFirstError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first'**
  String get enterEmailFirstError;

  /// No description provided for @failedResendOtpError.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP code.'**
  String get failedResendOtpError;

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
  /// **'SOS Sent'**
  String get alertSent;

  /// No description provided for @alertSentDesc.
  ///
  /// In en, this message translates to:
  /// **'Your emergency signal has been sent to emergency contacts.'**
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
  /// **'MEDICAL HISTORY OR ALLERGIES'**
  String get medicalHistoryLabel;

  /// No description provided for @medicalHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search disease/allergy (e.g. Asthma)'**
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

  /// No description provided for @profileDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal details and medical history.'**
  String get profileDesc;

  /// No description provided for @editButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButtonLabel;

  /// No description provided for @historySosDesc.
  ///
  /// In en, this message translates to:
  /// **'Archive of sent and received SOS signals.'**
  String get historySosDesc;

  /// No description provided for @historyTabSent.
  ///
  /// In en, this message translates to:
  /// **'My SOS'**
  String get historyTabSent;

  /// No description provided for @historyTabReceived.
  ///
  /// In en, this message translates to:
  /// **'SOS Received'**
  String get historyTabReceived;

  /// No description provided for @historyNoSent.
  ///
  /// In en, this message translates to:
  /// **'You have never sent an SOS signal.'**
  String get historyNoSent;

  /// No description provided for @historyNoReceived.
  ///
  /// In en, this message translates to:
  /// **'No incoming SOS signals from your contacts yet.'**
  String get historyNoReceived;

  /// No description provided for @triggerAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto Detection'**
  String get triggerAuto;

  /// No description provided for @triggerManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Trigger'**
  String get triggerManual;

  /// No description provided for @phoneLabelAbbr.
  ///
  /// In en, this message translates to:
  /// **'Phone:'**
  String get phoneLabelAbbr;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get historyLoadFailed;

  /// No description provided for @addContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get addContactTitle;

  /// No description provided for @addContactDesc.
  ///
  /// In en, this message translates to:
  /// **'Search by phone number or email. Only registered users can be added.'**
  String get addContactDesc;

  /// No description provided for @addContactInputLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER / EMAIL'**
  String get addContactInputLabel;

  /// No description provided for @addContactInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 08123456789 or email@safe.com'**
  String get addContactInputHint;

  /// No description provided for @addContactSearchResults.
  ///
  /// In en, this message translates to:
  /// **'SEARCH RESULTS'**
  String get addContactSearchResults;

  /// No description provided for @addContactInitialHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number or email to search'**
  String get addContactInitialHint;

  /// No description provided for @addContactNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get addContactNotFound;

  /// No description provided for @addContactNotFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'This contact is not registered on SAFE yet. Only registered users can be added.'**
  String get addContactNotFoundDesc;

  /// No description provided for @addContactButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addContactButton;

  /// No description provided for @addContactConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContactConfirmTitle;

  /// No description provided for @addContactConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Add {name} as an emergency contact?'**
  String addContactConfirmDesc(String name);

  /// No description provided for @addContactSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contact request successfully sent to {name}!'**
  String addContactSuccess(String name);

  /// No description provided for @addContactFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add contact. Please try again.'**
  String get addContactFailed;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get statusResolved;

  /// No description provided for @statusFalseAlarm.
  ///
  /// In en, this message translates to:
  /// **'FALSE ALARM'**
  String get statusFalseAlarm;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String notificationsSelected(int count);

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deleteSelectedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelectedTooltip;

  /// No description provided for @selectNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select notifications'**
  String get selectNotificationsTooltip;

  /// No description provided for @markAllAsReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsReadTooltip;

  /// No description provided for @deleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllTooltip;

  /// No description provided for @deleteNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotificationTitle;

  /// No description provided for @deleteSelectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected notifications?'**
  String deleteSelectedConfirm(int count);

  /// No description provided for @selectedDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Selected notifications successfully deleted'**
  String get selectedDeletedSuccess;

  /// No description provided for @allMarkedReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allMarkedReadSuccess;

  /// No description provided for @deleteAllNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Notifications'**
  String get deleteAllNotificationsTitle;

  /// No description provided for @deleteAllNotificationsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notification history?'**
  String get deleteAllNotificationsConfirm;

  /// No description provided for @allNotificationsDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications successfully deleted'**
  String get allNotificationsDeletedSuccess;

  /// No description provided for @notificationDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Notification successfully deleted'**
  String get notificationDeletedSuccess;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String timeDaysAgo(int count);

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'All incoming notifications related to SOS and emergency contacts will be shown here.'**
  String get noNotificationsDesc;

  /// No description provided for @notificationListHeader.
  ///
  /// In en, this message translates to:
  /// **'Notification List'**
  String get notificationListHeader;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @locationPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get locationPageTitle;

  /// No description provided for @locationPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your emergency contacts'**
  String get locationPageSubtitle;

  /// No description provided for @searchContactHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContactHint;

  /// No description provided for @distanceCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating distance'**
  String get distanceCalculating;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @unknownUpdateTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown update time'**
  String get unknownUpdateTime;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @positionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position:'**
  String get positionLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get updatedLabel;

  /// No description provided for @gpsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get GPS location'**
  String get gpsFailed;

  /// No description provided for @routeDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download route'**
  String get routeDownloadFailed;

  /// No description provided for @emergencyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS History'**
  String get emergencyHistoryTitle;

  /// No description provided for @sosHistoryReceivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming emergency signal'**
  String get sosHistoryReceivedSubtitle;

  /// No description provided for @sosHistorySentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sent emergency signal'**
  String get sosHistorySentSubtitle;

  /// No description provided for @contactPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get contactPlaceholder;

  /// No description provided for @openGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Google Maps'**
  String get openGoogleMaps;

  /// No description provided for @phoneNumberPrefix.
  ///
  /// In en, this message translates to:
  /// **'Phone:'**
  String get phoneNumberPrefix;

  /// No description provided for @searchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Searching location...'**
  String get searchingLocation;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @receiverEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get receiverEmergencyTitle;

  /// No description provided for @receiverEmergencySub.
  ///
  /// In en, this message translates to:
  /// **'Immediate assistance required'**
  String get receiverEmergencySub;

  /// No description provided for @receiverViewLocation.
  ///
  /// In en, this message translates to:
  /// **'View Location'**
  String get receiverViewLocation;

  /// No description provided for @receiverCallNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get receiverCallNow;

  /// No description provided for @receiverCalculatingDistance.
  ///
  /// In en, this message translates to:
  /// **'Calculating distance...'**
  String get receiverCalculatingDistance;

  /// No description provided for @receiverDistanceText.
  ///
  /// In en, this message translates to:
  /// **'± {distance} km from you'**
  String receiverDistanceText(Object distance);

  /// No description provided for @receiverLocationUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Location unreachable'**
  String get receiverLocationUnreachable;

  /// No description provided for @receiverSearchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Searching location...'**
  String get receiverSearchingLocation;

  /// No description provided for @receiverSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get receiverSomeone;

  /// No description provided for @cancelSos.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelSos;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Security at Your\nFingertips'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One touch, One family, Always safe'**
  String get splashSubtitle;

  /// No description provided for @splashStartButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get splashStartButton;

  /// No description provided for @splashHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get splashHaveAccount;

  /// No description provided for @splashLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get splashLoginLink;

  /// No description provided for @registerTitleText.
  ///
  /// In en, this message translates to:
  /// **'Register New Account'**
  String get registerTitleText;

  /// No description provided for @registerSubtitleText.
  ///
  /// In en, this message translates to:
  /// **'Join SAFE for your safety and peace of mind.'**
  String get registerSubtitleText;

  /// No description provided for @stepBasicAccount.
  ///
  /// In en, this message translates to:
  /// **'Basic Account'**
  String get stepBasicAccount;

  /// No description provided for @stepMedicalData.
  ///
  /// In en, this message translates to:
  /// **'Medical Data'**
  String get stepMedicalData;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@email.com'**
  String get emailHint;

  /// No description provided for @requiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredFieldError;

  /// No description provided for @emailFormatError.
  ///
  /// In en, this message translates to:
  /// **'Email must contain @'**
  String get emailFormatError;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get emailInvalidError;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'081234567890'**
  String get phoneHint;

  /// No description provided for @phonePrefixError.
  ///
  /// In en, this message translates to:
  /// **'Phone number must start with 08'**
  String get phonePrefixError;

  /// No description provided for @phoneMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be at least 10 digits'**
  String get phoneMinLengthError;

  /// No description provided for @phoneMaxLengthError.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too long'**
  String get phoneMaxLengthError;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLengthError;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get confirmPasswordHint;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @registerGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get registerGoogle;

  /// No description provided for @registerSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Check email for OTP code.'**
  String get registerSuccessMsg;

  /// No description provided for @skipAndRegister.
  ///
  /// In en, this message translates to:
  /// **'Skip & Register'**
  String get skipAndRegister;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @medicalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medicalInfoTitle;

  /// No description provided for @medicalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blood type and disease/allergy information will greatly assist rescue teams in emergencies.'**
  String get medicalInfoSubtitle;

  /// No description provided for @bloodTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Blood Type'**
  String get bloodTypeHint;

  /// No description provided for @registerNowButton.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNowButton;

  /// No description provided for @forgotPasswordTitleText.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitleText;

  /// No description provided for @forgotPasswordSubtitleText.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email to reset your password.'**
  String get forgotPasswordSubtitleText;

  /// No description provided for @fillEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in your email'**
  String get fillEmailError;

  /// No description provided for @sendOtpCodeButton.
  ///
  /// In en, this message translates to:
  /// **'SEND OTP CODE'**
  String get sendOtpCodeButton;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// No description provided for @enterOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP code sent to {email}'**
  String enterOtpSentTo(String email);

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP CODE'**
  String get otpLabel;

  /// No description provided for @codeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code expires in {timer}'**
  String codeExpiresIn(String timer);

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP code has expired'**
  String get codeExpired;

  /// No description provided for @enter6DigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP code'**
  String get enter6DigitOtp;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'VERIFY'**
  String get verifyButton;

  /// No description provided for @waitToResend.
  ///
  /// In en, this message translates to:
  /// **'Wait {timer} to resend'**
  String waitToResend(String timer);

  /// No description provided for @goBackAndResend.
  ///
  /// In en, this message translates to:
  /// **'Go Back & Resend OTP'**
  String get goBackAndResend;

  /// No description provided for @invalidOtpError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP code.'**
  String get invalidOtpError;

  /// No description provided for @verificationSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Email successfully verified. Please login.'**
  String get verificationSuccessMsg;

  /// No description provided for @registrationCancelledError.
  ///
  /// In en, this message translates to:
  /// **'OTP expired. Registration cancelled, please register again.'**
  String get registrationCancelledError;

  /// No description provided for @registrationExpiredError.
  ///
  /// In en, this message translates to:
  /// **'OTP expired. Please register again.'**
  String get registrationExpiredError;

  /// No description provided for @resendingText.
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get resendingText;

  /// No description provided for @resendInText.
  ///
  /// In en, this message translates to:
  /// **'Resend in {timer}'**
  String resendInText(String timer);

  /// No description provided for @resendOtpCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP code'**
  String get resendOtpCodeButton;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please create a new password for your account.'**
  String get newPasswordSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get confirmNewPasswordLabel;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @fillBothPasswordFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both password fields'**
  String get fillBothPasswordFieldsError;

  /// No description provided for @newPasswordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get newPasswordMinLengthError;

  /// No description provided for @confirmPasswordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Confirm password does not match'**
  String get confirmPasswordNotMatch;

  /// No description provided for @savePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE PASSWORD'**
  String get savePasswordButton;

  /// No description provided for @selectCountryCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Country Code'**
  String get selectCountryCodeTitle;

  /// No description provided for @searchCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get searchCountryHint;

  /// No description provided for @invalidPhoneFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone format (numbers only)'**
  String get invalidPhoneFormatError;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out of Account'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the SAFE application?'**
  String get logoutDialogContent;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutConfirm;
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
