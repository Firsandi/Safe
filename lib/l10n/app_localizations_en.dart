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
  String get loginWelcome => 'Log In';

  @override
  String get loginWelcomeSub => 'Enter your registered email and password';

  @override
  String get orText => 'OR';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get noAccountText => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get fillEmailPasswordError => 'Please fill in email and password';

  @override
  String get invalidEmailError => 'Email format must contain @';

  @override
  String get enterEmailFirstError => 'Please enter your email first';

  @override
  String get failedResendOtpError => 'Failed to resend OTP code.';

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
  String get alertSent => 'SOS Sent';

  @override
  String get alertSentDesc =>
      'Your emergency signal has been sent to emergency contacts.';

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
  String get medicalHistoryLabel => 'MEDICAL HISTORY OR ALLERGIES';

  @override
  String get medicalHistoryHint => 'Search disease/allergy (e.g. Asthma)';

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

  @override
  String get severeShakeDetected => 'Severe Shake Detected';

  @override
  String get fallDetected => 'Fall Detected';

  @override
  String get crashImpactDetected => 'Crash & Impact Detected';

  @override
  String get severeImpactDetected => 'Severe Impact Detected';

  @override
  String get impactForceLabel => 'IMPACT FORCE';

  @override
  String get locationLabel => 'LOCATION';

  @override
  String get connectionIssuesTitle => 'Connection Issues';

  @override
  String get connectionIssuesDesc =>
      'Failed to send SOS due to connection issues. Your SOS is saved in the offline queue and will sync automatically when your connection is restored.\n\nPlease contact emergency services or your contacts manually if possible.';

  @override
  String get profileDesc => 'Manage your personal details and medical history.';

  @override
  String get editButtonLabel => 'Edit';

  @override
  String get historySosDesc => 'Archive of sent and received SOS signals.';

  @override
  String get historyTabSent => 'My SOS';

  @override
  String get historyTabReceived => 'SOS Received';

  @override
  String get historyNoSent => 'You have never sent an SOS signal.';

  @override
  String get historyNoReceived =>
      'No incoming SOS signals from your contacts yet.';

  @override
  String get triggerAuto => 'Auto Detection';

  @override
  String get triggerManual => 'Manual Trigger';

  @override
  String get phoneLabelAbbr => 'Phone:';

  @override
  String get historyLoadFailed => 'Failed to load history';

  @override
  String get addContactTitle => 'Add Emergency Contact';

  @override
  String get addContactDesc =>
      'Search by phone number or email. Only registered users can be added.';

  @override
  String get addContactInputLabel => 'PHONE NUMBER / EMAIL';

  @override
  String get addContactInputHint => 'e.g. 08123456789 or email@safe.com';

  @override
  String get addContactSearchResults => 'SEARCH RESULTS';

  @override
  String get addContactInitialHint => 'Enter phone number or email to search';

  @override
  String get addContactNotFound => 'User not found';

  @override
  String get addContactNotFoundDesc =>
      'This contact is not registered on SAFE yet. Only registered users can be added.';

  @override
  String get addContactButton => 'Add';

  @override
  String get addContactConfirmTitle => 'Add Contact';

  @override
  String addContactConfirmDesc(String name) {
    return 'Add $name as an emergency contact?';
  }

  @override
  String addContactSuccess(String name) {
    return 'Contact request successfully sent to $name!';
  }

  @override
  String get addContactFailed => 'Failed to add contact. Please try again.';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusResolved => 'RESOLVED';

  @override
  String get statusFalseAlarm => 'FALSE ALARM';

  @override
  String get noHistory => 'No history';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsSelected(int count) {
    return '$count Selected';
  }

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get selectAll => 'Select all';

  @override
  String get deleteSelectedTooltip => 'Delete selected';

  @override
  String get selectNotificationsTooltip => 'Select notifications';

  @override
  String get markAllAsReadTooltip => 'Mark all as read';

  @override
  String get deleteAllTooltip => 'Delete all';

  @override
  String get deleteNotificationTitle => 'Delete Notification';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Are you sure you want to delete $count selected notifications?';
  }

  @override
  String get selectedDeletedSuccess =>
      'Selected notifications successfully deleted';

  @override
  String get allMarkedReadSuccess => 'All notifications marked as read';

  @override
  String get deleteAllNotificationsTitle => 'Delete All Notifications';

  @override
  String get deleteAllNotificationsConfirm =>
      'Are you sure you want to delete all notification history?';

  @override
  String get allNotificationsDeletedSuccess =>
      'All notifications successfully deleted';

  @override
  String get notificationDeletedSuccess => 'Notification successfully deleted';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get noNotifications => 'No Notifications';

  @override
  String get noNotificationsDesc =>
      'All incoming notifications related to SOS and emergency contacts will be shown here.';

  @override
  String get notificationListHeader => 'Notification List';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortNewest => 'Newest';

  @override
  String get locationPageTitle => 'Live Location';

  @override
  String get locationPageSubtitle => 'Track your emergency contacts';

  @override
  String get searchContactHint => 'Search contacts...';

  @override
  String get distanceCalculating => 'Calculating distance';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get unknownUpdateTime => 'Unknown update time';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String get positionLabel => 'Position:';

  @override
  String get updatedLabel => 'Updated:';

  @override
  String get gpsFailed => 'Failed to get GPS location';

  @override
  String get routeDownloadFailed => 'Failed to download route';

  @override
  String get emergencyHistoryTitle => 'SOS History';

  @override
  String get sosHistoryReceivedSubtitle => 'Incoming emergency signal';

  @override
  String get sosHistorySentSubtitle => 'Sent emergency signal';

  @override
  String get contactPlaceholder => 'Emergency contact';

  @override
  String get openGoogleMaps => 'Open Google Maps';

  @override
  String get phoneNumberPrefix => 'Phone:';

  @override
  String get searchingLocation => 'Searching location...';

  @override
  String get yourLocation => 'Your location';

  @override
  String get receiverEmergencyTitle => 'EMERGENCY';

  @override
  String get receiverEmergencySub => 'Immediate assistance required';

  @override
  String get receiverViewLocation => 'View Location';

  @override
  String get receiverCallNow => 'Call Now';

  @override
  String get receiverCalculatingDistance => 'Calculating distance...';

  @override
  String receiverDistanceText(Object distance) {
    return '± $distance km from you';
  }

  @override
  String get receiverLocationUnreachable => 'Location unreachable';

  @override
  String get receiverSearchingLocation => 'Searching location...';

  @override
  String get receiverSomeone => 'Someone';

  @override
  String get cancelSos => 'CANCEL';

  @override
  String get splashTitle => 'Security at Your\nFingertips';

  @override
  String get splashSubtitle => 'One touch, One family, Always safe';

  @override
  String get splashStartButton => 'Get Started';

  @override
  String get splashHaveAccount => 'Already have an account? ';

  @override
  String get splashLoginLink => 'Login';

  @override
  String get registerTitleText => 'Register New Account';

  @override
  String get registerSubtitleText =>
      'Join SAFE for your safety and peace of mind.';

  @override
  String get stepBasicAccount => 'Basic Account';

  @override
  String get stepMedicalData => 'Medical Data';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get emailHint => 'name@email.com';

  @override
  String get requiredFieldError => 'Required field';

  @override
  String get emailFormatError => 'Email must contain @';

  @override
  String get emailInvalidError => 'Invalid email format';

  @override
  String get phoneHint => '081234567890';

  @override
  String get phonePrefixError => 'Phone number must start with 08';

  @override
  String get phoneMinLengthError => 'Phone number must be at least 10 digits';

  @override
  String get phoneMaxLengthError => 'Phone number is too long';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get passwordMinLengthError => 'Password must be at least 8 characters';

  @override
  String get confirmPasswordLabel => 'CONFIRM PASSWORD';

  @override
  String get confirmPasswordHint => 'Repeat your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get continueButton => 'Continue';

  @override
  String get registerGoogle => 'Sign up with Google';

  @override
  String get registerSuccessMsg =>
      'Registration successful. Check email for OTP code.';

  @override
  String get skipAndRegister => 'Skip & Register';

  @override
  String get backTooltip => 'Back';

  @override
  String get medicalInfoTitle => 'Medical Information';

  @override
  String get medicalInfoSubtitle =>
      'Blood type and disease/allergy information will greatly assist rescue teams in emergencies.';

  @override
  String get bloodTypeHint => 'Select Blood Type';

  @override
  String get registerNowButton => 'Register Now';

  @override
  String get forgotPasswordTitleText => 'Forgot Password';

  @override
  String get forgotPasswordSubtitleText =>
      'Enter your registered email to reset your password.';

  @override
  String get fillEmailError => 'Please fill in your email';

  @override
  String get sendOtpCodeButton => 'SEND OTP CODE';

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String enterOtpSentTo(String email) {
    return 'Enter the 6-digit OTP code sent to $email';
  }

  @override
  String get otpLabel => 'OTP CODE';

  @override
  String codeExpiresIn(String timer) {
    return 'Code expires in $timer';
  }

  @override
  String get codeExpired => 'OTP code has expired';

  @override
  String get enter6DigitOtp => 'Enter the 6-digit OTP code';

  @override
  String get verifyButton => 'VERIFY';

  @override
  String waitToResend(String timer) {
    return 'Wait $timer to resend';
  }

  @override
  String get goBackAndResend => 'Go Back & Resend OTP';

  @override
  String get invalidOtpError => 'Invalid or expired OTP code.';

  @override
  String get verificationSuccessMsg =>
      'Email successfully verified. Please login.';

  @override
  String get registrationCancelledError =>
      'OTP expired. Registration cancelled, please register again.';

  @override
  String get registrationExpiredError => 'OTP expired. Please register again.';

  @override
  String get resendingText => 'Resending...';

  @override
  String resendInText(String timer) {
    return 'Resend in $timer';
  }

  @override
  String get resendOtpCodeButton => 'Resend OTP code';

  @override
  String get newPasswordTitle => 'New Password';

  @override
  String get newPasswordSubtitle =>
      'Please create a new password for your account.';

  @override
  String get newPasswordLabel => 'NEW PASSWORD';

  @override
  String get newPasswordHint => 'At least 8 characters';

  @override
  String get confirmNewPasswordLabel => 'CONFIRM PASSWORD';

  @override
  String get confirmNewPasswordHint => 'Repeat your new password';

  @override
  String get fillBothPasswordFieldsError =>
      'Please fill in both password fields';

  @override
  String get newPasswordMinLengthError =>
      'Password must be at least 8 characters';

  @override
  String get confirmPasswordNotMatch => 'Confirm password does not match';

  @override
  String get savePasswordButton => 'SAVE PASSWORD';

  @override
  String get selectCountryCodeTitle => 'Select Country Code';

  @override
  String get searchCountryHint => 'Search country...';

  @override
  String get invalidPhoneFormatError => 'Invalid phone format (numbers only)';
}
