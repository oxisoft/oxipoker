// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Connect to a server';

  @override
  String get serverHint => 'Server address or invitation link';

  @override
  String get serverHelp =>
      'Paste the invitation link you got from your host, or the address of your poker server.';

  @override
  String get connect => 'Connect';

  @override
  String get changeServer => 'Change server';

  @override
  String serverVersion(String version) {
    return 'Server $version';
  }

  @override
  String get signInTitle => 'Sign in';

  @override
  String get username => 'Username';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameOptional => 'Display name (optional)';

  @override
  String get password => 'Password';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInPasskey => 'Sign in with a passkey';

  @override
  String get totpTitle => 'Two-factor code';

  @override
  String get totpHelp =>
      'Enter the 6-digit code from your authenticator app, or one of your recovery codes.';

  @override
  String get code => 'Code';

  @override
  String get verify => 'Verify';

  @override
  String get back => 'Back';

  @override
  String get inviteTitle => 'Join with an invitation';

  @override
  String inviteNote(String note) {
    return 'Note from your host: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Link valid until $date';
  }

  @override
  String get createAccount => 'Create account';

  @override
  String get createWithPasskey => 'Create account with a passkey';

  @override
  String get orPassword => 'or choose a password';

  @override
  String get passwordsDiffer => 'The passwords do not match.';

  @override
  String lobbyWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get lobbySoon => 'Tables open in the next release.';

  @override
  String get account => 'Account';

  @override
  String get admin => 'Admin';

  @override
  String get signOut => 'Sign out';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get remove => 'Remove';

  @override
  String get rename => 'Rename';

  @override
  String get profile => 'Profile';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordChanged =>
      'Password changed. Your other sessions were signed out.';

  @override
  String get mustChangeTitle => 'Choose a new password';

  @override
  String get mustChangeHelp =>
      'Your admin gave you a temporary password. Choose your own to continue.';

  @override
  String get sessions => 'Sessions';

  @override
  String get thisDevice => 'this device';

  @override
  String get revoke => 'Sign out';

  @override
  String get revokeOthers => 'Sign out everywhere else';

  @override
  String lastSeen(String date) {
    return 'last seen $date';
  }

  @override
  String get twoFactor => 'Two-factor sign-in';

  @override
  String twoFactorOn(int count) {
    return 'On, $count recovery codes left';
  }

  @override
  String get twoFactorOff => 'Off';

  @override
  String get enable => 'Turn on';

  @override
  String get disable => 'Turn off';

  @override
  String get totpScan =>
      'Scan this code with your authenticator app, then enter the 6-digit code it shows.';

  @override
  String totpSecret(String secret) {
    return 'Secret: $secret';
  }

  @override
  String get recoveryTitle => 'Recovery codes';

  @override
  String get recoveryHelp =>
      'Each code signs you in once when your phone is not at hand. They are shown only now: keep them somewhere safe.';

  @override
  String get passkeys => 'Passkeys';

  @override
  String get addPasskey => 'Add a passkey';

  @override
  String get noPasskeys => 'No passkeys yet.';

  @override
  String get synced => 'synced';

  @override
  String get passkeyName => 'Passkey name';

  @override
  String get passkeyUnsupported => 'Passkeys are not available on this device.';

  @override
  String get avatar => 'Avatar';

  @override
  String get uploadAvatar => 'Upload picture';

  @override
  String get dangerZone => 'Delete account';

  @override
  String get deleteAccountHelp =>
      'Your account and everything in it are deleted for good.';

  @override
  String get deleteAccountConfirm =>
      'Enter your password to delete your account.';

  @override
  String get users => 'Users';

  @override
  String get invitations => 'Invitations';

  @override
  String get settings => 'Settings';

  @override
  String get auditLog => 'Audit log';

  @override
  String get search => 'Search';

  @override
  String get newUser => 'New user';

  @override
  String get makeAdmin => 'Admin';

  @override
  String get disabled => 'Disabled';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get reset2fa => 'Reset two-factor';

  @override
  String get temporaryPassword => 'Temporary password';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Give it to $name privately. It is shown only now and must be changed at the first sign-in.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Delete $name and everything in the account?';
  }

  @override
  String get newInvitation => 'New invitation';

  @override
  String get validHours => 'Valid for (hours)';

  @override
  String get uses => 'Uses';

  @override
  String get note => 'Note (optional)';

  @override
  String get invitationLink => 'Invitation link';

  @override
  String get invitationLinkHelp =>
      'Send this link to the player. It is shown only now.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses of $max used';
  }

  @override
  String get invitationRevoked => 'revoked';

  @override
  String get invitationExpired => 'expired';

  @override
  String joinedBy(String names) {
    return 'Joined: $names';
  }

  @override
  String get tableCreation => 'Who may create tables';

  @override
  String get everyone => 'Every player';

  @override
  String get adminsOnly => 'Admins only';

  @override
  String get maxUpload => 'Maximum upload size (KiB)';

  @override
  String get loadMore => 'Load more';

  @override
  String get filterAction => 'Action (exact, or prefix ending with a dot)';

  @override
  String get errNetwork => 'The server cannot be reached.';

  @override
  String get errNotServer => 'No Oxi Poker server answers at this address.';

  @override
  String get errBadAddress => 'Enter an address like poker.example.com.';

  @override
  String get errInvalidCredentials => 'Wrong username or password.';

  @override
  String get errRateLimited => 'Too many attempts. Try again in a while.';

  @override
  String get errInvalidCode => 'That code is not valid.';

  @override
  String get errChallengeExpired => 'The sign-in took too long. Start again.';

  @override
  String get errInvitationInvalid => 'This invitation link is not valid.';

  @override
  String get errInvitationExpired => 'This invitation link has expired.';

  @override
  String get errInvitationUsed => 'This invitation link has already been used.';

  @override
  String get errBadUsername =>
      'Usernames have 3 to 32 letters, digits, dots, dashes or underscores.';

  @override
  String get errBadDisplayName => 'Display names have 1 to 64 characters.';

  @override
  String get errBadPassword => 'Passwords have 10 to 256 characters.';

  @override
  String get errUsernameTaken => 'That username is taken.';

  @override
  String get errWrongPassword => 'The password is wrong.';

  @override
  String get errLastAdmin => 'The server needs at least one admin.';

  @override
  String get errSelf => 'You cannot do that to your own account here.';

  @override
  String get errTooLarge => 'The file is too large.';

  @override
  String get errBadImage => 'Use a PNG, JPEG, GIF or WebP picture.';

  @override
  String get errPasskeyRejected => 'The passkey was not accepted.';

  @override
  String get errLastSignInMethod =>
      'This is your last way to sign in. Add a password or another passkey first.';

  @override
  String get errBadInvitation =>
      'Hours 1 to 720, uses 1 to 100, note up to 200 characters.';

  @override
  String get errBadSettings =>
      'Upload size must be between 256 KiB and 20 MiB.';

  @override
  String errGeneric(String code) {
    return 'Something went wrong ($code).';
  }

  @override
  String get handHistory => 'Hand history';

  @override
  String get createTable => 'Create table';

  @override
  String get create => 'Create';

  @override
  String get noTables =>
      'No open tables yet. Create one and invite your friends.';

  @override
  String get closeTable => 'Close table';

  @override
  String closeTableConfirm(String name) {
    return 'Close the table $name? A running hand is cancelled and every stack goes back to where it was.';
  }

  @override
  String blinds(int sb, int bb) {
    return 'Blinds $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'Stack $n';
  }

  @override
  String get connecting => 'Connecting…';

  @override
  String get reconnecting => 'Connection lost, reconnecting…';

  @override
  String get serverRestarting =>
      'The server is restarting. A hand in play is cancelled and its chips go back; the table returns in a moment.';

  @override
  String get tableName => 'Table name';

  @override
  String get seats => 'Seats';

  @override
  String get smallBlind => 'Small blind';

  @override
  String get bigBlind => 'Big blind';

  @override
  String get startingStack => 'Starting stack';

  @override
  String get turnTime => 'Turn time (seconds)';

  @override
  String get allowSpectators => 'Allow spectators';

  @override
  String get errTableName => 'The name needs 1 to 40 characters.';

  @override
  String get errBlinds =>
      'Blinds must be at least 1, and the small blind not above the big blind.';

  @override
  String get errStack => 'The starting stack must be at least two big blinds.';

  @override
  String get errTurnTime => 'Turn time must be 5 to 300 seconds.';

  @override
  String get wsNotYourTurn => 'It is not your turn.';

  @override
  String get wsSeatTaken => 'That seat was just taken.';

  @override
  String get wsAlreadySeated => 'You already have a seat at this table.';

  @override
  String get wsIllegal => 'That action is not possible right now.';

  @override
  String get wsSpectatorsOff =>
      'This table has no spectators. Take a seat to join.';

  @override
  String get table => 'Table';

  @override
  String get sitOut => 'Sit out';

  @override
  String get comeBack => 'Come back';

  @override
  String get leaveSeat => 'Leave the seat';

  @override
  String get chat => 'Chat';

  @override
  String get tableClosed => 'This table is closed.';

  @override
  String get backToLobby => 'Back to the lobby';

  @override
  String get watchingHint => 'You are watching. Pick an empty seat to play.';

  @override
  String get bustedHint =>
      'Out of chips. Use Come back in the seat menu to buy in again.';

  @override
  String get sittingOutHint =>
      'You are sitting out. Use Come back in the seat menu to play the next hand.';

  @override
  String get waitingForPlayers => 'Waiting for players';

  @override
  String get nextHandSoon => 'Next hand starts in a moment';

  @override
  String waitingFor(String name) {
    return 'Waiting for $name';
  }

  @override
  String potMain(String amount) {
    return 'Pot $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Side pot $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name wins $amount';
  }

  @override
  String get sit => 'Sit here';

  @override
  String get emptySeat => 'Empty';

  @override
  String get sittingOut => 'Sitting out';

  @override
  String get folded => 'Folded';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Raise to $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Bet $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Call $amount';
  }

  @override
  String get presetMin => 'Min';

  @override
  String get presetHalfPot => '½ pot';

  @override
  String get presetPot => 'Pot';

  @override
  String get presetAllIn => 'All-in';

  @override
  String get fold => 'Fold';

  @override
  String get check => 'Check';

  @override
  String get bet => 'Bet';

  @override
  String get chatNotStored => 'Seen by players and spectators, never stored.';

  @override
  String get chatHint => 'Message';

  @override
  String get noHands => 'No hands played yet.';

  @override
  String potLabel(String amount) {
    return 'pot $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who posts the small blind $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who posts the big blind $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who is dealt $cards';
  }

  @override
  String evFold(String who) {
    return '$who folds';
  }

  @override
  String evCheck(String who) {
    return '$who checks';
  }

  @override
  String evCall(String who, String amount) {
    return '$who calls $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who bets $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who raises to $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount returned to $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who shows $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who wins $amount';
  }

  @override
  String get replay => 'Replay';

  @override
  String get yourCards => 'Your cards';

  @override
  String stepOf(int step, int total) {
    return '$step of $total';
  }

  @override
  String get stats => 'Your stats';

  @override
  String get handsPlayed => 'Hands played';

  @override
  String get handsWon => 'Hands won';

  @override
  String get biggestPot => 'Biggest pot won';

  @override
  String get sngGames => 'Sit-and-go games';

  @override
  String get sngWins => 'Sit-and-go wins';

  @override
  String get sngBest => 'Best place';

  @override
  String get tableKind => 'Game';

  @override
  String get kindCash => 'Cash game';

  @override
  String get kindSng => 'Sit-and-go';

  @override
  String get structure => 'Blind levels';

  @override
  String structureTurbo(int min) {
    return 'Turbo, $min min';
  }

  @override
  String structureRegular(int min) {
    return 'Regular, $min min';
  }

  @override
  String structureSlow(int min) {
    return 'Slow, $min min';
  }

  @override
  String get firstBlinds => 'First level blinds';

  @override
  String sngRegistering(int n) {
    return 'Registration: $n seated. The host starts the game, or it starts when every seat is taken.';
  }

  @override
  String get startGame => 'Start the game';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Level $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'next $sb/$bb in $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'next $sb/$bb from the next hand';
  }

  @override
  String get sngLastLevel => 'last level';

  @override
  String get standings => 'Final standings';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'You finished #$place';
  }

  @override
  String get wsSngStarted => 'The sit-and-go has already started.';

  @override
  String get wsTooFewPlayers => 'A sit-and-go needs at least two players.';

  @override
  String get wsHostOnly => 'Only the host or an admin can do that.';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeClassic => 'Classic';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Card back';

  @override
  String get serverDefault => 'Server default';

  @override
  String get defaultCardBack => 'Default card back';

  @override
  String get cardBacks => 'Card backs';

  @override
  String get errBadTheme => 'Unknown theme.';

  @override
  String get errBadCardBack => 'That card back is not available.';

  @override
  String get errCardBackDefault => 'The default card back cannot be deleted.';

  @override
  String get uploadCardBack => 'Upload a card back';

  @override
  String get cardBackName => 'Card back name';

  @override
  String get errTooManyCardBacks =>
      'There are too many uploaded card backs. Delete one first.';

  @override
  String get chatUserMenuHint =>
      'Tap a chat line to block or report its author.';

  @override
  String get blockUser => 'Block';

  @override
  String get reportUser => 'Report';

  @override
  String get muteInChat => 'Mute in this table\'s chat';

  @override
  String get unmuteInChat => 'Unmute in this table\'s chat';

  @override
  String get removeSpectator => 'Remove from the table';

  @override
  String userBlocked(String name) {
    return '$name is blocked. You no longer see their chat.';
  }

  @override
  String reportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reasonChat => 'Chat';

  @override
  String get reasonBehaviour => 'Behaviour';

  @override
  String get reasonOther => 'Other';

  @override
  String get reportNote => 'What happened? (optional)';

  @override
  String get reportChatHint =>
      'The last chat lines of this table go with the report, so the admin sees what was said.';

  @override
  String get sendReport => 'Send report';

  @override
  String get reportSent => 'Report sent to the server admin.';

  @override
  String get blockedUsers => 'Blocked users';

  @override
  String get noBlockedUsers =>
      'You have not blocked anyone. Tap a chat line at a table to block its author.';

  @override
  String get unblock => 'Unblock';

  @override
  String get reports => 'Reports';

  @override
  String get showResolved => 'Show resolved reports';

  @override
  String get noReports => 'No reports.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter reported $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'resolved by $name';
  }

  @override
  String get reportNoChat => 'No chat lines with this report.';

  @override
  String get resolve => 'Mark resolved';

  @override
  String get wsMuted => 'The host muted you in this table\'s chat.';

  @override
  String get wsRemoved => 'The host removed you from this table.';

  @override
  String get wsIsPlayer => 'Players cannot be removed; only spectators.';

  @override
  String get errBusy => 'The server is busy. Try again in a moment.';

  @override
  String get errBadName => 'Names have 1 to 64 characters.';

  @override
  String get errBuiltIn => 'Built-in card backs cannot be deleted.';

  @override
  String get errTotpEnabled => 'Two-factor sign-in is already on.';

  @override
  String get errTotpNotStarted => 'Start the two-factor setup again.';

  @override
  String get errTotpNotEnabled => 'Two-factor sign-in is not on.';

  @override
  String get errPasswordChangeRequired => 'Change your password first.';

  @override
  String get errTooManyTables =>
      'The server has too many open tables. Try again later.';

  @override
  String get errTooManyPasskeys =>
      'You have too many passkeys. Delete one first.';

  @override
  String get errTooManyBlocks =>
      'Your block list is full. Unblock someone first.';

  @override
  String get errTooManyReports =>
      'You have sent too many reports. Try again later.';

  @override
  String get errReportSelf => 'You cannot report yourself.';

  @override
  String get errBlockSelf => 'You cannot block yourself.';

  @override
  String get errBadReport =>
      'Pick a reason; the note has up to 500 characters.';

  @override
  String get errAdminOnly => 'Only an admin can do that.';

  @override
  String get errNotFound => 'That no longer exists.';

  @override
  String get errUnauthenticated => 'Sign in again.';

  @override
  String get errBadRequest =>
      'The server did not understand the request. Update the app.';

  @override
  String get errInternal => 'The server hit an error. Try again.';

  @override
  String get wsNotSeated => 'You have no seat at this table.';

  @override
  String get wsNotInHand => 'You are not in this hand.';

  @override
  String get wsNoTable => 'This table is closed.';

  @override
  String get wsNotSng => 'Only a sit-and-go can be started.';

  @override
  String get wsBadChat => 'Chat lines have 1 to 300 characters.';

  @override
  String get wsBadSeat => 'That seat does not exist.';

  @override
  String get imagesFileType => 'Images';

  @override
  String get defaultTableName => 'Friday game';

  @override
  String get language => 'Language';

  @override
  String get languageDevice => 'Device language';
}
