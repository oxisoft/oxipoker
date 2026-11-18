import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Oxi Poker'**
  String get appTitle;

  /// No description provided for @serverTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a server'**
  String get serverTitle;

  /// No description provided for @serverHint.
  ///
  /// In en, this message translates to:
  /// **'Server address or invitation link'**
  String get serverHint;

  /// No description provided for @serverHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the invitation link you got from your host, or the address of your poker server.'**
  String get serverHelp;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @changeServer.
  ///
  /// In en, this message translates to:
  /// **'Change server'**
  String get changeServer;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'Server {version}'**
  String serverVersion(String version);

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameOptional;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInPasskey.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a passkey'**
  String get signInPasskey;

  /// No description provided for @totpTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor code'**
  String get totpTitle;

  /// No description provided for @totpHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app, or one of your recovery codes.'**
  String get totpHelp;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with an invitation'**
  String get inviteTitle;

  /// No description provided for @inviteNote.
  ///
  /// In en, this message translates to:
  /// **'Note from your host: {note}'**
  String inviteNote(String note);

  /// No description provided for @inviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Link valid until {date}'**
  String inviteExpires(String date);

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createWithPasskey.
  ///
  /// In en, this message translates to:
  /// **'Create account with a passkey'**
  String get createWithPasskey;

  /// No description provided for @orPassword.
  ///
  /// In en, this message translates to:
  /// **'or choose a password'**
  String get orPassword;

  /// No description provided for @passwordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordsDiffer;

  /// No description provided for @lobbyWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String lobbyWelcome(String name);

  /// No description provided for @lobbySoon.
  ///
  /// In en, this message translates to:
  /// **'Tables open in the next release.'**
  String get lobbySoon;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Your other sessions were signed out.'**
  String get passwordChanged;

  /// No description provided for @mustChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get mustChangeTitle;

  /// No description provided for @mustChangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Your admin gave you a temporary password. Choose your own to continue.'**
  String get mustChangeHelp;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'this device'**
  String get thisDevice;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get revoke;

  /// No description provided for @revokeOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere else'**
  String get revokeOthers;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'last seen {date}'**
  String lastSeen(String date);

  /// No description provided for @twoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in'**
  String get twoFactor;

  /// No description provided for @twoFactorOn.
  ///
  /// In en, this message translates to:
  /// **'On, {count} recovery codes left'**
  String twoFactorOn(int count);

  /// No description provided for @twoFactorOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get twoFactorOff;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get disable;

  /// No description provided for @totpScan.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with your authenticator app, then enter the 6-digit code it shows.'**
  String get totpScan;

  /// No description provided for @totpSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret: {secret}'**
  String totpSecret(String secret);

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes'**
  String get recoveryTitle;

  /// No description provided for @recoveryHelp.
  ///
  /// In en, this message translates to:
  /// **'Each code signs you in once when your phone is not at hand. They are shown only now: keep them somewhere safe.'**
  String get recoveryHelp;

  /// No description provided for @passkeys.
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeys;

  /// No description provided for @addPasskey.
  ///
  /// In en, this message translates to:
  /// **'Add a passkey'**
  String get addPasskey;

  /// No description provided for @noPasskeys.
  ///
  /// In en, this message translates to:
  /// **'No passkeys yet.'**
  String get noPasskeys;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'synced'**
  String get synced;

  /// No description provided for @passkeyName.
  ///
  /// In en, this message translates to:
  /// **'Passkey name'**
  String get passkeyName;

  /// No description provided for @passkeyUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Passkeys are not available on this device.'**
  String get passkeyUnsupported;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @uploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload picture'**
  String get uploadAvatar;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get dangerZone;

  /// No description provided for @deleteAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Your account and everything in it are deleted for good.'**
  String get deleteAccountHelp;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to delete your account.'**
  String get deleteAccountConfirm;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditLog;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get newUser;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get makeAdmin;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @reset2fa.
  ///
  /// In en, this message translates to:
  /// **'Reset two-factor'**
  String get reset2fa;

  /// No description provided for @temporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temporaryPassword;

  /// No description provided for @temporaryPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Give it to {name} privately. It is shown only now and must be changed at the first sign-in.'**
  String temporaryPasswordHelp(String name);

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and everything in the account?'**
  String deleteUserConfirm(String name);

  /// No description provided for @newInvitation.
  ///
  /// In en, this message translates to:
  /// **'New invitation'**
  String get newInvitation;

  /// No description provided for @validHours.
  ///
  /// In en, this message translates to:
  /// **'Valid for (hours)'**
  String get validHours;

  /// No description provided for @uses.
  ///
  /// In en, this message translates to:
  /// **'Uses'**
  String get uses;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get note;

  /// No description provided for @invitationLink.
  ///
  /// In en, this message translates to:
  /// **'Invitation link'**
  String get invitationLink;

  /// No description provided for @invitationLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Send this link to the player. It is shown only now.'**
  String get invitationLinkHelp;

  /// No description provided for @invitationUses.
  ///
  /// In en, this message translates to:
  /// **'{uses} of {max} used'**
  String invitationUses(int uses, int max);

  /// No description provided for @invitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'revoked'**
  String get invitationRevoked;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get invitationExpired;

  /// No description provided for @joinedBy.
  ///
  /// In en, this message translates to:
  /// **'Joined: {names}'**
  String joinedBy(String names);

  /// No description provided for @tableCreation.
  ///
  /// In en, this message translates to:
  /// **'Who may create tables'**
  String get tableCreation;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Every player'**
  String get everyone;

  /// No description provided for @adminsOnly.
  ///
  /// In en, this message translates to:
  /// **'Admins only'**
  String get adminsOnly;

  /// No description provided for @maxUpload.
  ///
  /// In en, this message translates to:
  /// **'Maximum upload size (KiB)'**
  String get maxUpload;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @filterAction.
  ///
  /// In en, this message translates to:
  /// **'Action (exact, or prefix ending with a dot)'**
  String get filterAction;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'The server cannot be reached.'**
  String get errNetwork;

  /// No description provided for @errNotServer.
  ///
  /// In en, this message translates to:
  /// **'No Oxi Poker server answers at this address.'**
  String get errNotServer;

  /// No description provided for @errBadAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter an address like poker.example.com.'**
  String get errBadAddress;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a while.'**
  String get errRateLimited;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not valid.'**
  String get errInvalidCode;

  /// No description provided for @errChallengeExpired.
  ///
  /// In en, this message translates to:
  /// **'The sign-in took too long. Start again.'**
  String get errChallengeExpired;

  /// No description provided for @errInvitationInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invitation link is not valid.'**
  String get errInvitationInvalid;

  /// No description provided for @errInvitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation link has expired.'**
  String get errInvitationExpired;

  /// No description provided for @errInvitationUsed.
  ///
  /// In en, this message translates to:
  /// **'This invitation link has already been used.'**
  String get errInvitationUsed;

  /// No description provided for @errBadUsername.
  ///
  /// In en, this message translates to:
  /// **'Usernames have 3 to 32 letters, digits, dots, dashes or underscores.'**
  String get errBadUsername;

  /// No description provided for @errBadDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display names have 1 to 64 characters.'**
  String get errBadDisplayName;

  /// No description provided for @errBadPassword.
  ///
  /// In en, this message translates to:
  /// **'Passwords have 10 to 256 characters.'**
  String get errBadPassword;

  /// No description provided for @errUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken.'**
  String get errUsernameTaken;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is wrong.'**
  String get errWrongPassword;

  /// No description provided for @errLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'The server needs at least one admin.'**
  String get errLastAdmin;

  /// No description provided for @errSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot do that to your own account here.'**
  String get errSelf;

  /// No description provided for @errTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large.'**
  String get errTooLarge;

  /// No description provided for @errBadImage.
  ///
  /// In en, this message translates to:
  /// **'Use a PNG, JPEG, GIF or WebP picture.'**
  String get errBadImage;

  /// No description provided for @errPasskeyRejected.
  ///
  /// In en, this message translates to:
  /// **'The passkey was not accepted.'**
  String get errPasskeyRejected;

  /// No description provided for @errLastSignInMethod.
  ///
  /// In en, this message translates to:
  /// **'This is your last way to sign in. Add a password or another passkey first.'**
  String get errLastSignInMethod;

  /// No description provided for @errBadInvitation.
  ///
  /// In en, this message translates to:
  /// **'Hours 1 to 720, uses 1 to 100, note up to 200 characters.'**
  String get errBadInvitation;

  /// No description provided for @errBadSettings.
  ///
  /// In en, this message translates to:
  /// **'Upload size must be between 256 KiB and 20 MiB.'**
  String get errBadSettings;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}).'**
  String errGeneric(String code);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
