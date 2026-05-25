// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubTitle => 'Access your tactical medical dashboard.';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get passwordLabel => 'ACCESS PASSWORD';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'LOG IN';

  @override
  String get registerLink => 'Register for a new account';

  @override
  String get copyright => '© 2026 SAFE - Emergency Archive';

  @override
  String get security => 'Security';

  @override
  String get privacy => 'Privacy';

  @override
  String get registerTitle => 'Account Setup';

  @override
  String get stepIndicator => 'STEP 01 OF 02';

  @override
  String get profileStatus => 'PROFILE STATUS';

  @override
  String get initialEntry => 'Initial Entry';

  @override
  String get basicCredentials => 'BASIC CREDENTIALS';

  @override
  String get fullName => 'FULL NAME';

  @override
  String get emailAddress => 'EMAIL ADDRESS';

  @override
  String get mobileId => 'MOBILE ID';

  @override
  String get medicalProfile => 'INITIAL MEDICAL PROFILE';

  @override
  String get bloodType => 'BLOOD TYPE';

  @override
  String get criticalAllergies => 'CRITICAL ALLERGIES';

  @override
  String get createAccount => 'CREATE ACCOUNT';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Login';

  @override
  String get legalFooter =>
      'BY CREATING AN ACCOUNT, YOU AGREE TO OUR TERMS OF SERVICE AND PRIVACY PROTOCOLS. YOUR DATA IS ENCRYPTED AND STORED WITHIN THE SECURE ARCHIVE.';

  @override
  String get homeTitle => 'COMMAND CENTER';

  @override
  String get sosLabel => 'SOS';

  @override
  String get sosTap => 'HOLD TO ACTIVATE SOS';

  @override
  String get emergencyContacts => 'EMERGENCY CONTACTS';

  @override
  String get activeGuardian => 'GUARDIAN STATUS: READY';

  @override
  String get recentAlerts => 'RECENT ALERTS';

  @override
  String get noAlerts => 'NO RECENT THREATS DETECTED';

  @override
  String get commandInterface => 'COMMAND INTERFACE';

  @override
  String get appTitle => 'SAFE APP';

  @override
  String get monitoringActive => 'Monitoring: Active';

  @override
  String get systemOperational =>
      'System fully operational. We are standing by.';

  @override
  String get pressHold => 'PRESS & HOLD';

  @override
  String get medicalProfileTitle => 'Medical Profile';

  @override
  String get vitalsAllergies => 'Vitals & Allergies';

  @override
  String get emergencyContactsTitle => 'Emergency Contacts';

  @override
  String get trustedCircle => 'Trusted Circle';

  @override
  String get currentLocation => 'CURRENT LOCATION';

  @override
  String get guardianLinkActive => 'GUARDIAN LINK ACTIVE';

  @override
  String get accidentDetected => 'ACCIDENT DETECTED!';

  @override
  String get notifyingServices =>
      'Notifying contacts and emergency services in...';

  @override
  String get seconds => 'SECONDS';

  @override
  String get swipeUpCancel => 'SWIPE UP TO CANCEL';

  @override
  String get falseAlarm => 'I AM SAFE / FALSE ALARM';

  @override
  String get navStatus => 'STATUS';

  @override
  String get navContacts => 'CONTACTS';

  @override
  String get navMedical => 'MEDICAL';

  @override
  String get navHistory => 'HISTORY';

  @override
  String get navHome => 'HOME';

  @override
  String get navLocation => 'LOCATION';

  @override
  String get navProfile => 'PROFILE';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'Set app language preference';

  @override
  String get settingsHelp => 'Help Center';

  @override
  String get settingsHelpSub => 'FAQ & Support Contact';

  @override
  String get logout => 'LOG OUT OF SYSTEM';

  @override
  String get sensorActive => 'Sensor Active — monitoring';

  @override
  String get helpSentToLocation =>
      'Help will be dispatched to\nyour current location immediately';

  @override
  String get historySos => 'SOS History';

  @override
  String get emergencyContactsSub => '3 active';

  @override
  String get historySosSub => '2 events';

  @override
  String get notAvailableYet => 'This page is not available yet';

  @override
  String get locationTitle => 'Location';

  @override
  String get emergencyCancelled => 'Emergency cancelled — you are safe';

  @override
  String get alertSent => 'ALERT SENT';

  @override
  String get alertSentDesc =>
      'Emergency services and contacts have been notified.';

  @override
  String get backToHome => 'BACK TO HOME';

  @override
  String get searchPlaceholder => 'Search name or phone number...';

  @override
  String get contactsLoadFailed => 'Unable to load contacts';

  @override
  String get retry => 'Retry';

  @override
  String get noResultsFound => 'No results found';

  @override
  String noContactsMatching(String query) {
    return 'No contacts match \"$query\"';
  }

  @override
  String get noEmergencyContacts => 'No emergency contacts yet';

  @override
  String get addContactsInstruction =>
      'Add emergency contacts to be contacted in emergency situations.';

  @override
  String get noIncomingRequests => 'No incoming requests';

  @override
  String get incomingRequestsInstruction =>
      'Incoming requests from other users who want to add you will appear here.';

  @override
  String get callContact => 'Call';

  @override
  String get sendWhatsApp => 'Send WhatsApp message';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get deleteContactTitle => 'Delete Contact';

  @override
  String deleteContactConfirm(String name) {
    return 'Are you sure you want to remove $name from emergency contacts?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get connected => 'Connected';

  @override
  String get pending => 'Pending';

  @override
  String get myContacts => 'My Contacts';

  @override
  String get incomingRequests => 'Incoming Requests';

  @override
  String get emergencyContactsDesc =>
      'Manage the list of trusted people during emergency situations.';

  @override
  String get editProfileTitle => 'Edit Profile & Medical';

  @override
  String get editProfileSub =>
      'Update your photo, personal details and medical history.';

  @override
  String get fullNameLabel => 'FULL NAME';

  @override
  String get phoneLabel => 'PHONE NUMBER';

  @override
  String get bloodTypeLabel => 'BLOOD TYPE';

  @override
  String get choose => 'Choose';

  @override
  String get medicalHistoryLabel => 'MEDICAL HISTORY / ALLERGIES';

  @override
  String get medicalHistoryHint => 'e.g. Asthma, Peanut Allergy';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get medicalDataCenter => 'MEDICAL DATA CENTER';

  @override
  String get bloodTypeCard => 'BLOOD TYPE';

  @override
  String get allergiesCard => 'ALLERGIES / DISEASE';

  @override
  String get none => 'None';

  @override
  String get settings => 'SETTINGS';

  @override
  String get enterFullName => 'Enter full name';

  @override
  String get languageTitle => 'Select Language';

  @override
  String get languageSelect => 'Select your app language:';

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String activeContactsCount(int count) {
    return '$count active';
  }

  @override
  String sosHistoryCount(int count) {
    return '$count events';
  }

  @override
  String get sosActiveBanner => 'SOS ACTIVE';

  @override
  String get sendingRealtimeLocation => 'Sending your real-time location...';

  @override
  String get turnOff => 'Turn Off';

  @override
  String get sosDisabledSuccess => 'SOS successfully disabled';

  @override
  String sosDisableFailed(String error) {
    return 'Failed to disable SOS: $error';
  }

  @override
  String get permissionRequiredTitle => 'Permissions Required';

  @override
  String get permissionRequiredDesc =>
      'SAFE requires Location and Notification permissions to monitor your safety and send help in emergencies. Without these, the app cannot protect you.';

  @override
  String get allowPermissionsButton => 'Grant Permissions';

  @override
  String get openSettingsInstruction =>
      'If permissions are not granted, please enable them manually in the App Settings.';
}
