import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
  ];

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

  /// No description provided for @handHistory.
  ///
  /// In en, this message translates to:
  /// **'Hand history'**
  String get handHistory;

  /// No description provided for @createTable.
  ///
  /// In en, this message translates to:
  /// **'Create table'**
  String get createTable;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @noTables.
  ///
  /// In en, this message translates to:
  /// **'No open tables yet. Create one and invite your friends.'**
  String get noTables;

  /// No description provided for @closeTable.
  ///
  /// In en, this message translates to:
  /// **'Close table'**
  String get closeTable;

  /// No description provided for @closeTableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close the table {name}? A running hand is cancelled and every stack goes back to where it was.'**
  String closeTableConfirm(String name);

  /// No description provided for @blinds.
  ///
  /// In en, this message translates to:
  /// **'Blinds {sb}/{bb}'**
  String blinds(int sb, int bb);

  /// No description provided for @stackLabel.
  ///
  /// In en, this message translates to:
  /// **'Stack {n}'**
  String stackLabel(int n);

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connection lost, reconnecting…'**
  String get reconnecting;

  /// No description provided for @serverRestarting.
  ///
  /// In en, this message translates to:
  /// **'The server is restarting. A hand in play is cancelled and its chips go back; the table returns in a moment.'**
  String get serverRestarting;

  /// No description provided for @tableName.
  ///
  /// In en, this message translates to:
  /// **'Table name'**
  String get tableName;

  /// No description provided for @seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seats;

  /// No description provided for @smallBlind.
  ///
  /// In en, this message translates to:
  /// **'Small blind'**
  String get smallBlind;

  /// No description provided for @bigBlind.
  ///
  /// In en, this message translates to:
  /// **'Big blind'**
  String get bigBlind;

  /// No description provided for @startingStack.
  ///
  /// In en, this message translates to:
  /// **'Starting stack'**
  String get startingStack;

  /// No description provided for @turnTime.
  ///
  /// In en, this message translates to:
  /// **'Turn time (seconds)'**
  String get turnTime;

  /// No description provided for @allowSpectators.
  ///
  /// In en, this message translates to:
  /// **'Allow spectators'**
  String get allowSpectators;

  /// No description provided for @errTableName.
  ///
  /// In en, this message translates to:
  /// **'The name needs 1 to 40 characters.'**
  String get errTableName;

  /// No description provided for @errBlinds.
  ///
  /// In en, this message translates to:
  /// **'Blinds must be at least 1, and the small blind not above the big blind.'**
  String get errBlinds;

  /// No description provided for @errStack.
  ///
  /// In en, this message translates to:
  /// **'The starting stack must be at least two big blinds.'**
  String get errStack;

  /// No description provided for @errTurnTime.
  ///
  /// In en, this message translates to:
  /// **'Turn time must be 5 to 300 seconds.'**
  String get errTurnTime;

  /// No description provided for @wsNotYourTurn.
  ///
  /// In en, this message translates to:
  /// **'It is not your turn.'**
  String get wsNotYourTurn;

  /// No description provided for @wsSeatTaken.
  ///
  /// In en, this message translates to:
  /// **'That seat was just taken.'**
  String get wsSeatTaken;

  /// No description provided for @wsAlreadySeated.
  ///
  /// In en, this message translates to:
  /// **'You already have a seat at this table.'**
  String get wsAlreadySeated;

  /// No description provided for @wsIllegal.
  ///
  /// In en, this message translates to:
  /// **'That action is not possible right now.'**
  String get wsIllegal;

  /// No description provided for @wsSpectatorsOff.
  ///
  /// In en, this message translates to:
  /// **'This table has no spectators. Take a seat to join.'**
  String get wsSpectatorsOff;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @sitOut.
  ///
  /// In en, this message translates to:
  /// **'Sit out'**
  String get sitOut;

  /// No description provided for @comeBack.
  ///
  /// In en, this message translates to:
  /// **'Come back'**
  String get comeBack;

  /// No description provided for @leaveSeat.
  ///
  /// In en, this message translates to:
  /// **'Leave the seat'**
  String get leaveSeat;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @tableClosed.
  ///
  /// In en, this message translates to:
  /// **'This table is closed.'**
  String get tableClosed;

  /// No description provided for @backToLobby.
  ///
  /// In en, this message translates to:
  /// **'Back to the lobby'**
  String get backToLobby;

  /// No description provided for @watchingHint.
  ///
  /// In en, this message translates to:
  /// **'You are watching. Pick an empty seat to play.'**
  String get watchingHint;

  /// No description provided for @bustedHint.
  ///
  /// In en, this message translates to:
  /// **'Out of chips. Use Come back in the seat menu to buy in again.'**
  String get bustedHint;

  /// No description provided for @sittingOutHint.
  ///
  /// In en, this message translates to:
  /// **'You are sitting out. Use Come back in the seat menu to play the next hand.'**
  String get sittingOutHint;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players'**
  String get waitingForPlayers;

  /// No description provided for @nextHandSoon.
  ///
  /// In en, this message translates to:
  /// **'Next hand starts in a moment'**
  String get nextHandSoon;

  /// No description provided for @waitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String waitingFor(String name);

  /// No description provided for @potMain.
  ///
  /// In en, this message translates to:
  /// **'Pot {amount}'**
  String potMain(String amount);

  /// No description provided for @potSide.
  ///
  /// In en, this message translates to:
  /// **'Side pot {n}: {amount}'**
  String potSide(int n, String amount);

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins {amount}'**
  String wins(String name, String amount);

  /// No description provided for @sit.
  ///
  /// In en, this message translates to:
  /// **'Sit here'**
  String get sit;

  /// No description provided for @emptySeat.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptySeat;

  /// No description provided for @sittingOut.
  ///
  /// In en, this message translates to:
  /// **'Sitting out'**
  String get sittingOut;

  /// No description provided for @folded.
  ///
  /// In en, this message translates to:
  /// **'Folded'**
  String get folded;

  /// No description provided for @allIn.
  ///
  /// In en, this message translates to:
  /// **'All-in'**
  String get allIn;

  /// No description provided for @allInTo.
  ///
  /// In en, this message translates to:
  /// **'All-in {amount}'**
  String allInTo(String amount);

  /// No description provided for @raiseTo.
  ///
  /// In en, this message translates to:
  /// **'Raise to {amount}'**
  String raiseTo(String amount);

  /// No description provided for @betAmount.
  ///
  /// In en, this message translates to:
  /// **'Bet {amount}'**
  String betAmount(String amount);

  /// No description provided for @callAmount.
  ///
  /// In en, this message translates to:
  /// **'Call {amount}'**
  String callAmount(String amount);

  /// No description provided for @presetMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get presetMin;

  /// No description provided for @presetHalfPot.
  ///
  /// In en, this message translates to:
  /// **'½ pot'**
  String get presetHalfPot;

  /// No description provided for @presetPot.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get presetPot;

  /// No description provided for @presetAllIn.
  ///
  /// In en, this message translates to:
  /// **'All-in'**
  String get presetAllIn;

  /// No description provided for @fold.
  ///
  /// In en, this message translates to:
  /// **'Fold'**
  String get fold;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @bet.
  ///
  /// In en, this message translates to:
  /// **'Bet'**
  String get bet;

  /// No description provided for @chatNotStored.
  ///
  /// In en, this message translates to:
  /// **'Seen by players and spectators, never stored.'**
  String get chatNotStored;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatHint;

  /// No description provided for @noHands.
  ///
  /// In en, this message translates to:
  /// **'No hands played yet.'**
  String get noHands;

  /// No description provided for @potLabel.
  ///
  /// In en, this message translates to:
  /// **'pot {amount}'**
  String potLabel(String amount);

  /// No description provided for @evPostSb.
  ///
  /// In en, this message translates to:
  /// **'{who} posts the small blind {amount}'**
  String evPostSb(String who, String amount);

  /// No description provided for @evPostBb.
  ///
  /// In en, this message translates to:
  /// **'{who} posts the big blind {amount}'**
  String evPostBb(String who, String amount);

  /// No description provided for @evHole.
  ///
  /// In en, this message translates to:
  /// **'{who} is dealt {cards}'**
  String evHole(String who, String cards);

  /// No description provided for @evFold.
  ///
  /// In en, this message translates to:
  /// **'{who} folds'**
  String evFold(String who);

  /// No description provided for @evCheck.
  ///
  /// In en, this message translates to:
  /// **'{who} checks'**
  String evCheck(String who);

  /// No description provided for @evCall.
  ///
  /// In en, this message translates to:
  /// **'{who} calls {amount}'**
  String evCall(String who, String amount);

  /// No description provided for @evBet.
  ///
  /// In en, this message translates to:
  /// **'{who} bets {amount}'**
  String evBet(String who, String amount);

  /// No description provided for @evRaise.
  ///
  /// In en, this message translates to:
  /// **'{who} raises to {amount}'**
  String evRaise(String who, String amount);

  /// No description provided for @evReturn.
  ///
  /// In en, this message translates to:
  /// **'{amount} returned to {who}'**
  String evReturn(String who, String amount);

  /// No description provided for @evBoard.
  ///
  /// In en, this message translates to:
  /// **'{street}: {cards}'**
  String evBoard(String street, String cards);

  /// No description provided for @evShow.
  ///
  /// In en, this message translates to:
  /// **'{who} shows {cards}'**
  String evShow(String who, String cards);

  /// No description provided for @evWin.
  ///
  /// In en, this message translates to:
  /// **'{who} wins {amount}'**
  String evWin(String who, String amount);

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @yourCards.
  ///
  /// In en, this message translates to:
  /// **'Your cards'**
  String get yourCards;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'{step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get stats;

  /// No description provided for @handsPlayed.
  ///
  /// In en, this message translates to:
  /// **'Hands played'**
  String get handsPlayed;

  /// No description provided for @handsWon.
  ///
  /// In en, this message translates to:
  /// **'Hands won'**
  String get handsWon;

  /// No description provided for @biggestPot.
  ///
  /// In en, this message translates to:
  /// **'Biggest pot won'**
  String get biggestPot;

  /// No description provided for @sngGames.
  ///
  /// In en, this message translates to:
  /// **'Sit-and-go games'**
  String get sngGames;

  /// No description provided for @sngWins.
  ///
  /// In en, this message translates to:
  /// **'Sit-and-go wins'**
  String get sngWins;

  /// No description provided for @sngBest.
  ///
  /// In en, this message translates to:
  /// **'Best place'**
  String get sngBest;

  /// No description provided for @tableKind.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get tableKind;

  /// No description provided for @kindCash.
  ///
  /// In en, this message translates to:
  /// **'Cash game'**
  String get kindCash;

  /// No description provided for @kindSng.
  ///
  /// In en, this message translates to:
  /// **'Sit-and-go'**
  String get kindSng;

  /// No description provided for @structure.
  ///
  /// In en, this message translates to:
  /// **'Blind levels'**
  String get structure;

  /// No description provided for @structureTurbo.
  ///
  /// In en, this message translates to:
  /// **'Turbo, {min} min'**
  String structureTurbo(int min);

  /// No description provided for @structureRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular, {min} min'**
  String structureRegular(int min);

  /// No description provided for @structureSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow, {min} min'**
  String structureSlow(int min);

  /// No description provided for @firstBlinds.
  ///
  /// In en, this message translates to:
  /// **'First level blinds'**
  String get firstBlinds;

  /// No description provided for @sngRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registration: {n} seated. The host starts the game, or it starts when every seat is taken.'**
  String sngRegistering(int n);

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start the game'**
  String get startGame;

  /// No description provided for @sngLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {n}: {sb}/{bb}'**
  String sngLevel(int n, int sb, int bb);

  /// No description provided for @sngNext.
  ///
  /// In en, this message translates to:
  /// **'next {sb}/{bb} in {time}'**
  String sngNext(int sb, int bb, String time);

  /// No description provided for @sngNextHand.
  ///
  /// In en, this message translates to:
  /// **'next {sb}/{bb} from the next hand'**
  String sngNextHand(int sb, int bb);

  /// No description provided for @sngLastLevel.
  ///
  /// In en, this message translates to:
  /// **'last level'**
  String get sngLastLevel;

  /// No description provided for @standings.
  ///
  /// In en, this message translates to:
  /// **'Final standings'**
  String get standings;

  /// No description provided for @placeLine.
  ///
  /// In en, this message translates to:
  /// **'{place}. {name}'**
  String placeLine(int place, String name);

  /// No description provided for @youFinished.
  ///
  /// In en, this message translates to:
  /// **'You finished #{place}'**
  String youFinished(int place);

  /// No description provided for @wsSngStarted.
  ///
  /// In en, this message translates to:
  /// **'The sit-and-go has already started.'**
  String get wsSngStarted;

  /// No description provided for @wsTooFewPlayers.
  ///
  /// In en, this message translates to:
  /// **'A sit-and-go needs at least two players.'**
  String get wsTooFewPlayers;

  /// No description provided for @wsHostOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the host or an admin can do that.'**
  String get wsHostOnly;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get themeClassic;

  /// No description provided for @themeCyberpunk.
  ///
  /// In en, this message translates to:
  /// **'Cyberpunk'**
  String get themeCyberpunk;

  /// No description provided for @cardBack.
  ///
  /// In en, this message translates to:
  /// **'Card back'**
  String get cardBack;

  /// No description provided for @serverDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get serverDefault;

  /// No description provided for @defaultCardBack.
  ///
  /// In en, this message translates to:
  /// **'Default card back'**
  String get defaultCardBack;

  /// No description provided for @cardBacks.
  ///
  /// In en, this message translates to:
  /// **'Card backs'**
  String get cardBacks;

  /// No description provided for @errBadTheme.
  ///
  /// In en, this message translates to:
  /// **'Unknown theme.'**
  String get errBadTheme;

  /// No description provided for @errBadCardBack.
  ///
  /// In en, this message translates to:
  /// **'That card back is not available.'**
  String get errBadCardBack;

  /// No description provided for @errCardBackDefault.
  ///
  /// In en, this message translates to:
  /// **'The default card back cannot be deleted.'**
  String get errCardBackDefault;

  /// No description provided for @uploadCardBack.
  ///
  /// In en, this message translates to:
  /// **'Upload a card back'**
  String get uploadCardBack;

  /// No description provided for @cardBackName.
  ///
  /// In en, this message translates to:
  /// **'Card back name'**
  String get cardBackName;

  /// No description provided for @errTooManyCardBacks.
  ///
  /// In en, this message translates to:
  /// **'There are too many uploaded card backs. Delete one first.'**
  String get errTooManyCardBacks;

  /// No description provided for @chatUserMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a chat line to block or report its author.'**
  String get chatUserMenuHint;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUser;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportUser;

  /// No description provided for @muteInChat.
  ///
  /// In en, this message translates to:
  /// **'Mute in this table\'s chat'**
  String get muteInChat;

  /// No description provided for @unmuteInChat.
  ///
  /// In en, this message translates to:
  /// **'Unmute in this table\'s chat'**
  String get unmuteInChat;

  /// No description provided for @removeSpectator.
  ///
  /// In en, this message translates to:
  /// **'Remove from the table'**
  String get removeSpectator;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} is blocked. You no longer see their chat.'**
  String userBlocked(String name);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportTitle(String name);

  /// No description provided for @reasonChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get reasonChat;

  /// No description provided for @reasonBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get reasonBehaviour;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'What happened? (optional)'**
  String get reportNote;

  /// No description provided for @reportChatHint.
  ///
  /// In en, this message translates to:
  /// **'The last chat lines of this table go with the report, so the admin sees what was said.'**
  String get reportChatHint;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent to the server admin.'**
  String get reportSent;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsers;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked anyone. Tap a chat line at a table to block its author.'**
  String get noBlockedUsers;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @showResolved.
  ///
  /// In en, this message translates to:
  /// **'Show resolved reports'**
  String get showResolved;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports.'**
  String get noReports;

  /// No description provided for @reportLine.
  ///
  /// In en, this message translates to:
  /// **'{reporter} reported {reported}'**
  String reportLine(String reporter, String reported);

  /// No description provided for @resolvedBy.
  ///
  /// In en, this message translates to:
  /// **'resolved by {name}'**
  String resolvedBy(String name);

  /// No description provided for @reportNoChat.
  ///
  /// In en, this message translates to:
  /// **'No chat lines with this report.'**
  String get reportNoChat;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get resolve;

  /// No description provided for @wsMuted.
  ///
  /// In en, this message translates to:
  /// **'The host muted you in this table\'s chat.'**
  String get wsMuted;

  /// No description provided for @wsRemoved.
  ///
  /// In en, this message translates to:
  /// **'The host removed you from this table.'**
  String get wsRemoved;

  /// No description provided for @wsIsPlayer.
  ///
  /// In en, this message translates to:
  /// **'Players cannot be removed; only spectators.'**
  String get wsIsPlayer;

  /// No description provided for @errBusy.
  ///
  /// In en, this message translates to:
  /// **'The server is busy. Try again in a moment.'**
  String get errBusy;

  /// No description provided for @errBadName.
  ///
  /// In en, this message translates to:
  /// **'Names have 1 to 64 characters.'**
  String get errBadName;

  /// No description provided for @errBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in card backs cannot be deleted.'**
  String get errBuiltIn;

  /// No description provided for @errTotpEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in is already on.'**
  String get errTotpEnabled;

  /// No description provided for @errTotpNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Start the two-factor setup again.'**
  String get errTotpNotStarted;

  /// No description provided for @errTotpNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor sign-in is not on.'**
  String get errTotpNotEnabled;

  /// No description provided for @errPasswordChangeRequired.
  ///
  /// In en, this message translates to:
  /// **'Change your password first.'**
  String get errPasswordChangeRequired;

  /// No description provided for @errTooManyTables.
  ///
  /// In en, this message translates to:
  /// **'The server has too many open tables. Try again later.'**
  String get errTooManyTables;

  /// No description provided for @errTooManyPasskeys.
  ///
  /// In en, this message translates to:
  /// **'You have too many passkeys. Delete one first.'**
  String get errTooManyPasskeys;

  /// No description provided for @errTooManyBlocks.
  ///
  /// In en, this message translates to:
  /// **'Your block list is full. Unblock someone first.'**
  String get errTooManyBlocks;

  /// No description provided for @errTooManyReports.
  ///
  /// In en, this message translates to:
  /// **'You have sent too many reports. Try again later.'**
  String get errTooManyReports;

  /// No description provided for @errReportSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot report yourself.'**
  String get errReportSelf;

  /// No description provided for @errBlockSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot block yourself.'**
  String get errBlockSelf;

  /// No description provided for @errBadReport.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason; the note has up to 500 characters.'**
  String get errBadReport;

  /// No description provided for @errAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only an admin can do that.'**
  String get errAdminOnly;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'That no longer exists.'**
  String get errNotFound;

  /// No description provided for @errUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Sign in again.'**
  String get errUnauthenticated;

  /// No description provided for @errBadRequest.
  ///
  /// In en, this message translates to:
  /// **'The server did not understand the request. Update the app.'**
  String get errBadRequest;

  /// No description provided for @errInternal.
  ///
  /// In en, this message translates to:
  /// **'The server hit an error. Try again.'**
  String get errInternal;

  /// No description provided for @wsNotSeated.
  ///
  /// In en, this message translates to:
  /// **'You have no seat at this table.'**
  String get wsNotSeated;

  /// No description provided for @wsNotInHand.
  ///
  /// In en, this message translates to:
  /// **'You are not in this hand.'**
  String get wsNotInHand;

  /// No description provided for @wsNoTable.
  ///
  /// In en, this message translates to:
  /// **'This table is closed.'**
  String get wsNoTable;

  /// No description provided for @wsNotSng.
  ///
  /// In en, this message translates to:
  /// **'Only a sit-and-go can be started.'**
  String get wsNotSng;

  /// No description provided for @wsBadChat.
  ///
  /// In en, this message translates to:
  /// **'Chat lines have 1 to 300 characters.'**
  String get wsBadChat;

  /// No description provided for @wsBadSeat.
  ///
  /// In en, this message translates to:
  /// **'That seat does not exist.'**
  String get wsBadSeat;

  /// No description provided for @imagesFileType.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesFileType;

  /// No description provided for @defaultTableName.
  ///
  /// In en, this message translates to:
  /// **'Friday game'**
  String get defaultTableName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageDevice;

  /// No description provided for @errMediaOff.
  ///
  /// In en, this message translates to:
  /// **'Voice and video are not set up on this server.'**
  String get errMediaOff;

  /// No description provided for @errNotAtTable.
  ///
  /// In en, this message translates to:
  /// **'Join the table first to use voice and video.'**
  String get errNotAtTable;

  /// No description provided for @callJoin.
  ///
  /// In en, this message translates to:
  /// **'Join voice and video'**
  String get callJoin;

  /// No description provided for @callLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave the call'**
  String get callLeave;

  /// No description provided for @callMicOn.
  ///
  /// In en, this message translates to:
  /// **'Turn microphone on'**
  String get callMicOn;

  /// No description provided for @callMicOff.
  ///
  /// In en, this message translates to:
  /// **'Turn microphone off'**
  String get callMicOff;

  /// No description provided for @callCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Turn camera on'**
  String get callCameraOn;

  /// No description provided for @callCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Turn camera off'**
  String get callCameraOff;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callSpeaker;

  /// No description provided for @callSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get callSwitchCamera;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting the call…'**
  String get callConnecting;

  /// No description provided for @callLost.
  ///
  /// In en, this message translates to:
  /// **'The call dropped. The game goes on; join again when you like.'**
  String get callLost;

  /// No description provided for @callRemoved.
  ///
  /// In en, this message translates to:
  /// **'You were taken out of the call.'**
  String get callRemoved;

  /// No description provided for @callInCall.
  ///
  /// In en, this message translates to:
  /// **'In the call: {count}'**
  String callInCall(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'pl',
    'pt',
    'ru',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
