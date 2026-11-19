// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Mit einem Server verbinden';

  @override
  String get serverHint => 'Serveradresse oder Einladungslink';

  @override
  String get serverHelp =>
      'Füge den Einladungslink von deinem Gastgeber oder die Adresse deines Pokerservers ein.';

  @override
  String get connect => 'Verbinden';

  @override
  String get changeServer => 'Server wechseln';

  @override
  String serverVersion(String version) {
    return 'Server $version';
  }

  @override
  String get signInTitle => 'Anmelden';

  @override
  String get username => 'Benutzername';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get displayNameOptional => 'Anzeigename (optional)';

  @override
  String get password => 'Passwort';

  @override
  String get repeatPassword => 'Passwort wiederholen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signInPasskey => 'Mit Passkey anmelden';

  @override
  String get totpTitle => 'Bestätigungscode';

  @override
  String get totpHelp =>
      'Gib den 6-stelligen Code aus deiner Authenticator-App oder einen deiner Wiederherstellungscodes ein.';

  @override
  String get code => 'Code';

  @override
  String get verify => 'Bestätigen';

  @override
  String get back => 'Zurück';

  @override
  String get inviteTitle => 'Mit Einladung beitreten';

  @override
  String inviteNote(String note) {
    return 'Nachricht von deinem Gastgeber: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Link gültig bis $date';
  }

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get createWithPasskey => 'Konto mit Passkey erstellen';

  @override
  String get orPassword => 'oder wähle ein Passwort';

  @override
  String get passwordsDiffer => 'Die Passwörter stimmen nicht überein.';

  @override
  String lobbyWelcome(String name) {
    return 'Willkommen, $name';
  }

  @override
  String get lobbySoon => 'Tische gibt es mit dem nächsten Release.';

  @override
  String get account => 'Konto';

  @override
  String get admin => 'Admin';

  @override
  String get signOut => 'Abmelden';

  @override
  String get save => 'Speichern';

  @override
  String get saved => 'Gespeichert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get delete => 'Löschen';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get remove => 'Entfernen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get profile => 'Profil';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get passwordChanged =>
      'Passwort geändert. Deine anderen Sitzungen wurden abgemeldet.';

  @override
  String get mustChangeTitle => 'Wähle ein neues Passwort';

  @override
  String get mustChangeHelp =>
      'Dein Admin hat dir ein temporäres Passwort gegeben. Wähle dein eigenes, um weiterzumachen.';

  @override
  String get sessions => 'Sitzungen';

  @override
  String get thisDevice => 'dieses Gerät';

  @override
  String get revoke => 'Abmelden';

  @override
  String get revokeOthers => 'Überall sonst abmelden';

  @override
  String lastSeen(String date) {
    return 'zuletzt aktiv $date';
  }

  @override
  String get twoFactor => 'Zwei-Faktor-Anmeldung';

  @override
  String twoFactorOn(int count) {
    return 'An, noch $count Wiederherstellungscodes';
  }

  @override
  String get twoFactorOff => 'Aus';

  @override
  String get enable => 'Einschalten';

  @override
  String get disable => 'Ausschalten';

  @override
  String get totpScan =>
      'Scanne diesen Code mit deiner Authenticator-App und gib dann den angezeigten 6-stelligen Code ein.';

  @override
  String totpSecret(String secret) {
    return 'Schlüssel: $secret';
  }

  @override
  String get recoveryTitle => 'Wiederherstellungscodes';

  @override
  String get recoveryHelp =>
      'Mit jedem Code kannst du dich einmal anmelden, wenn du dein Handy nicht zur Hand hast. Sie werden nur jetzt angezeigt: Bewahre sie sicher auf.';

  @override
  String get passkeys => 'Passkeys';

  @override
  String get addPasskey => 'Passkey hinzufügen';

  @override
  String get noPasskeys => 'Noch keine Passkeys.';

  @override
  String get synced => 'synchronisiert';

  @override
  String get passkeyName => 'Name des Passkeys';

  @override
  String get passkeyUnsupported =>
      'Passkeys sind auf diesem Gerät nicht verfügbar.';

  @override
  String get avatar => 'Avatar';

  @override
  String get uploadAvatar => 'Bild hochladen';

  @override
  String get dangerZone => 'Konto löschen';

  @override
  String get deleteAccountHelp =>
      'Dein Konto und alles darin wird endgültig gelöscht.';

  @override
  String get deleteAccountConfirm =>
      'Gib dein Passwort ein, um dein Konto zu löschen.';

  @override
  String get users => 'Benutzer';

  @override
  String get invitations => 'Einladungen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get auditLog => 'Audit-Log';

  @override
  String get search => 'Suchen';

  @override
  String get newUser => 'Neuer Benutzer';

  @override
  String get makeAdmin => 'Admin';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get reset2fa => 'Zwei-Faktor zurücksetzen';

  @override
  String get temporaryPassword => 'Temporäres Passwort';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Gib es $name persönlich. Es wird nur jetzt angezeigt und muss bei der ersten Anmeldung geändert werden.';
  }

  @override
  String deleteUserConfirm(String name) {
    return '$name und alles im Konto löschen?';
  }

  @override
  String get newInvitation => 'Neue Einladung';

  @override
  String get validHours => 'Gültig für (Stunden)';

  @override
  String get uses => 'Nutzungen';

  @override
  String get note => 'Nachricht (optional)';

  @override
  String get invitationLink => 'Einladungslink';

  @override
  String get invitationLinkHelp =>
      'Schick diesen Link an den Spieler. Er wird nur jetzt angezeigt.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses von $max genutzt';
  }

  @override
  String get invitationRevoked => 'widerrufen';

  @override
  String get invitationExpired => 'abgelaufen';

  @override
  String joinedBy(String names) {
    return 'Beigetreten: $names';
  }

  @override
  String get tableCreation => 'Wer Tische erstellen darf';

  @override
  String get everyone => 'Alle Spieler';

  @override
  String get adminsOnly => 'Nur Admins';

  @override
  String get maxUpload => 'Maximale Uploadgröße (KiB)';

  @override
  String get loadMore => 'Mehr laden';

  @override
  String get filterAction => 'Aktion (exakt oder Präfix mit Punkt am Ende)';

  @override
  String get errNetwork => 'Der Server ist nicht erreichbar.';

  @override
  String get errNotServer =>
      'Unter dieser Adresse antwortet kein Oxi Poker Server.';

  @override
  String get errBadAddress => 'Gib eine Adresse wie poker.example.com ein.';

  @override
  String get errInvalidCredentials =>
      'Falscher Benutzername oder falsches Passwort.';

  @override
  String get errRateLimited => 'Zu viele Versuche. Versuch es später noch mal.';

  @override
  String get errInvalidCode => 'Dieser Code ist ungültig.';

  @override
  String get errChallengeExpired =>
      'Die Anmeldung hat zu lange gedauert. Fang noch mal von vorn an.';

  @override
  String get errInvitationInvalid => 'Dieser Einladungslink ist ungültig.';

  @override
  String get errInvitationExpired => 'Dieser Einladungslink ist abgelaufen.';

  @override
  String get errInvitationUsed =>
      'Dieser Einladungslink wurde bereits verwendet.';

  @override
  String get errBadUsername =>
      'Benutzernamen haben 3 bis 32 Buchstaben, Ziffern, Punkte, Bindestriche oder Unterstriche.';

  @override
  String get errBadDisplayName => 'Anzeigenamen haben 1 bis 64 Zeichen.';

  @override
  String get errBadPassword => 'Passwörter haben 10 bis 256 Zeichen.';

  @override
  String get errUsernameTaken => 'Dieser Benutzername ist schon vergeben.';

  @override
  String get errWrongPassword => 'Das Passwort ist falsch.';

  @override
  String get errLastAdmin => 'Der Server braucht mindestens einen Admin.';

  @override
  String get errSelf =>
      'Das kannst du hier nicht mit deinem eigenen Konto machen.';

  @override
  String get errTooLarge => 'Die Datei ist zu groß.';

  @override
  String get errBadImage => 'Verwende ein PNG-, JPEG-, GIF- oder WebP-Bild.';

  @override
  String get errPasskeyRejected => 'Der Passkey wurde nicht akzeptiert.';

  @override
  String get errLastSignInMethod =>
      'Das ist deine letzte Anmeldemöglichkeit. Füge zuerst ein Passwort oder einen weiteren Passkey hinzu.';

  @override
  String get errBadInvitation =>
      'Stunden 1 bis 720, Nutzungen 1 bis 100, Nachricht bis 200 Zeichen.';

  @override
  String get errBadSettings =>
      'Die Uploadgröße muss zwischen 256 KiB und 20 MiB liegen.';

  @override
  String errGeneric(String code) {
    return 'Etwas ist schiefgelaufen ($code).';
  }

  @override
  String get handHistory => 'Handverlauf';

  @override
  String get createTable => 'Tisch erstellen';

  @override
  String get create => 'Erstellen';

  @override
  String get noTables =>
      'Noch keine offenen Tische. Erstell einen und lade deine Freunde ein.';

  @override
  String get closeTable => 'Tisch schließen';

  @override
  String closeTableConfirm(String name) {
    return 'Tisch $name schließen? Eine laufende Hand wird abgebrochen und alle Stacks werden zurückgesetzt.';
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
  String get connecting => 'Verbinde…';

  @override
  String get reconnecting => 'Verbindung verloren, verbinde neu…';

  @override
  String get serverRestarting =>
      'Der Server startet neu. Eine laufende Hand wird abgebrochen und die Chips gehen zurück; der Tisch ist gleich wieder da.';

  @override
  String get tableName => 'Tischname';

  @override
  String get seats => 'Plätze';

  @override
  String get smallBlind => 'Small Blind';

  @override
  String get bigBlind => 'Big Blind';

  @override
  String get startingStack => 'Startstack';

  @override
  String get turnTime => 'Bedenkzeit (Sekunden)';

  @override
  String get allowSpectators => 'Zuschauer erlauben';

  @override
  String get errTableName => 'Der Name braucht 1 bis 40 Zeichen.';

  @override
  String get errBlinds =>
      'Blinds müssen mindestens 1 sein, und der Small Blind darf nicht über dem Big Blind liegen.';

  @override
  String get errStack =>
      'Der Startstack muss mindestens zwei Big Blinds betragen.';

  @override
  String get errTurnTime => 'Die Bedenkzeit muss 5 bis 300 Sekunden betragen.';

  @override
  String get wsNotYourTurn => 'Du bist nicht dran.';

  @override
  String get wsSeatTaken => 'Dieser Platz wurde gerade besetzt.';

  @override
  String get wsAlreadySeated => 'Du hast an diesem Tisch schon einen Platz.';

  @override
  String get wsIllegal => 'Diese Aktion ist gerade nicht möglich.';

  @override
  String get wsSpectatorsOff =>
      'An diesem Tisch sind keine Zuschauer erlaubt. Setz dich, um mitzuspielen.';

  @override
  String get table => 'Tisch';

  @override
  String get sitOut => 'Aussetzen';

  @override
  String get comeBack => 'Zurückkehren';

  @override
  String get leaveSeat => 'Platz verlassen';

  @override
  String get chat => 'Chat';

  @override
  String get tableClosed => 'Dieser Tisch ist geschlossen.';

  @override
  String get backToLobby => 'Zurück zur Lobby';

  @override
  String get watchingHint =>
      'Du schaust zu. Wähl einen freien Platz, um zu spielen.';

  @override
  String get bustedHint =>
      'Keine Chips mehr. Nutze „Zurückkehren“ im Platzmenü, um dich neu einzukaufen.';

  @override
  String get sittingOutHint =>
      'Du setzt aus. Nutze „Zurückkehren“ im Platzmenü, um die nächste Hand zu spielen.';

  @override
  String get waitingForPlayers => 'Warte auf Spieler';

  @override
  String get nextHandSoon => 'Die nächste Hand beginnt gleich';

  @override
  String waitingFor(String name) {
    return 'Warte auf $name';
  }

  @override
  String potMain(String amount) {
    return 'Pot $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Sidepot $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name gewinnt $amount';
  }

  @override
  String get sit => 'Hier setzen';

  @override
  String get emptySeat => 'Frei';

  @override
  String get sittingOut => 'Setzt aus';

  @override
  String get folded => 'Gefoldet';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Raise auf $amount';
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
  String get presetHalfPot => '½ Pot';

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
  String get chatNotStored =>
      'Für Spieler und Zuschauer sichtbar, wird nie gespeichert.';

  @override
  String get chatHint => 'Nachricht';

  @override
  String get noHands => 'Noch keine Hände gespielt.';

  @override
  String potLabel(String amount) {
    return 'Pot $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who setzt den Small Blind $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who setzt den Big Blind $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who bekommt $cards';
  }

  @override
  String evFold(String who) {
    return '$who foldet';
  }

  @override
  String evCheck(String who) {
    return '$who checkt';
  }

  @override
  String evCall(String who, String amount) {
    return '$who callt $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who bettet $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who raist auf $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount zurück an $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who zeigt $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who gewinnt $amount';
  }

  @override
  String get replay => 'Wiederholung';

  @override
  String get yourCards => 'Deine Karten';

  @override
  String stepOf(int step, int total) {
    return '$step von $total';
  }

  @override
  String get stats => 'Deine Statistik';

  @override
  String get handsPlayed => 'Gespielte Hände';

  @override
  String get handsWon => 'Gewonnene Hände';

  @override
  String get biggestPot => 'Größter gewonnener Pot';

  @override
  String get sngGames => 'Sit & Go Spiele';

  @override
  String get sngWins => 'Sit & Go Siege';

  @override
  String get sngBest => 'Beste Platzierung';

  @override
  String get tableKind => 'Spiel';

  @override
  String get kindCash => 'Cashgame';

  @override
  String get kindSng => 'Sit & Go';

  @override
  String get structure => 'Blind-Level';

  @override
  String structureTurbo(int min) {
    return 'Turbo, $min Min.';
  }

  @override
  String structureRegular(int min) {
    return 'Normal, $min Min.';
  }

  @override
  String structureSlow(int min) {
    return 'Langsam, $min Min.';
  }

  @override
  String get firstBlinds => 'Blinds im ersten Level';

  @override
  String sngRegistering(int n) {
    return 'Anmeldung: $n sitzen. Der Gastgeber startet das Spiel, oder es startet, wenn alle Plätze besetzt sind.';
  }

  @override
  String get startGame => 'Spiel starten';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Level $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'nächstes $sb/$bb in $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'nächstes $sb/$bb ab der nächsten Hand';
  }

  @override
  String get sngLastLevel => 'letztes Level';

  @override
  String get standings => 'Endstand';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Du bist auf Platz $place';
  }

  @override
  String get wsSngStarted => 'Das Sit & Go hat schon begonnen.';

  @override
  String get wsTooFewPlayers => 'Ein Sit & Go braucht mindestens zwei Spieler.';

  @override
  String get wsHostOnly => 'Das kann nur der Gastgeber oder ein Admin.';

  @override
  String get appearance => 'Darstellung';

  @override
  String get theme => 'Design';

  @override
  String get themeClassic => 'Klassisch';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Kartenrücken';

  @override
  String get serverDefault => 'Server-Standard';

  @override
  String get defaultCardBack => 'Standard-Kartenrücken';

  @override
  String get cardBacks => 'Kartenrücken';

  @override
  String get errBadTheme => 'Unbekanntes Design.';

  @override
  String get errBadCardBack => 'Dieser Kartenrücken ist nicht verfügbar.';

  @override
  String get errCardBackDefault =>
      'Der Standard-Kartenrücken kann nicht gelöscht werden.';

  @override
  String get uploadCardBack => 'Kartenrücken hochladen';

  @override
  String get cardBackName => 'Name des Kartenrückens';

  @override
  String get errTooManyCardBacks =>
      'Es gibt zu viele hochgeladene Kartenrücken. Lösch zuerst einen.';

  @override
  String get chatUserMenuHint =>
      'Tippe auf eine Chatzeile, um den Verfasser zu blockieren oder zu melden.';

  @override
  String get blockUser => 'Blockieren';

  @override
  String get reportUser => 'Melden';

  @override
  String get muteInChat => 'Im Chat dieses Tisches stummschalten';

  @override
  String get unmuteInChat => 'Stummschaltung im Chat dieses Tisches aufheben';

  @override
  String get removeSpectator => 'Vom Tisch entfernen';

  @override
  String userBlocked(String name) {
    return '$name ist blockiert. Du siehst die Chatnachrichten nicht mehr.';
  }

  @override
  String reportTitle(String name) {
    return '$name melden';
  }

  @override
  String get reasonChat => 'Chat';

  @override
  String get reasonBehaviour => 'Verhalten';

  @override
  String get reasonOther => 'Sonstiges';

  @override
  String get reportNote => 'Was ist passiert? (optional)';

  @override
  String get reportChatHint =>
      'Die letzten Chatzeilen dieses Tisches werden mitgeschickt, damit der Admin sieht, was gesagt wurde.';

  @override
  String get sendReport => 'Meldung senden';

  @override
  String get reportSent => 'Meldung an den Server-Admin gesendet.';

  @override
  String get blockedUsers => 'Blockierte Benutzer';

  @override
  String get noBlockedUsers =>
      'Du hast niemanden blockiert. Tippe an einem Tisch auf eine Chatzeile, um den Verfasser zu blockieren.';

  @override
  String get unblock => 'Freigeben';

  @override
  String get reports => 'Meldungen';

  @override
  String get showResolved => 'Erledigte Meldungen anzeigen';

  @override
  String get noReports => 'Keine Meldungen.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter hat $reported gemeldet';
  }

  @override
  String resolvedBy(String name) {
    return 'erledigt von $name';
  }

  @override
  String get reportNoChat => 'Keine Chatzeilen zu dieser Meldung.';

  @override
  String get resolve => 'Als erledigt markieren';

  @override
  String get wsMuted =>
      'Der Gastgeber hat dich im Chat dieses Tisches stummgeschaltet.';

  @override
  String get wsRemoved => 'Der Gastgeber hat dich von diesem Tisch entfernt.';

  @override
  String get wsIsPlayer =>
      'Spieler können nicht entfernt werden, nur Zuschauer.';

  @override
  String get errBusy =>
      'Der Server ist ausgelastet. Versuch es gleich noch mal.';

  @override
  String get errBadName => 'Namen haben 1 bis 64 Zeichen.';

  @override
  String get errBuiltIn =>
      'Eingebaute Kartenrücken können nicht gelöscht werden.';

  @override
  String get errTotpEnabled => 'Die Zwei-Faktor-Anmeldung ist schon an.';

  @override
  String get errTotpNotStarted =>
      'Starte die Einrichtung der Zwei-Faktor-Anmeldung noch mal.';

  @override
  String get errTotpNotEnabled => 'Die Zwei-Faktor-Anmeldung ist nicht an.';

  @override
  String get errPasswordChangeRequired => 'Ändere zuerst dein Passwort.';

  @override
  String get errTooManyTables =>
      'Auf dem Server sind zu viele Tische offen. Versuch es später noch mal.';

  @override
  String get errTooManyPasskeys =>
      'Du hast zu viele Passkeys. Lösch zuerst einen.';

  @override
  String get errTooManyBlocks =>
      'Deine Blockliste ist voll. Gib zuerst jemanden frei.';

  @override
  String get errTooManyReports =>
      'Du hast zu viele Meldungen gesendet. Versuch es später noch mal.';

  @override
  String get errReportSelf => 'Du kannst dich nicht selbst melden.';

  @override
  String get errBlockSelf => 'Du kannst dich nicht selbst blockieren.';

  @override
  String get errBadReport =>
      'Wähl einen Grund; die Nachricht hat bis zu 500 Zeichen.';

  @override
  String get errAdminOnly => 'Das kann nur ein Admin.';

  @override
  String get errNotFound => 'Das gibt es nicht mehr.';

  @override
  String get errUnauthenticated => 'Melde dich erneut an.';

  @override
  String get errBadRequest =>
      'Der Server hat die Anfrage nicht verstanden. Aktualisiere die App.';

  @override
  String get errInternal =>
      'Auf dem Server ist ein Fehler aufgetreten. Versuch es noch mal.';

  @override
  String get wsNotSeated => 'Du hast an diesem Tisch keinen Platz.';

  @override
  String get wsNotInHand => 'Du bist nicht in dieser Hand.';

  @override
  String get wsNoTable => 'Dieser Tisch ist geschlossen.';

  @override
  String get wsNotSng => 'Nur ein Sit & Go kann gestartet werden.';

  @override
  String get wsBadChat => 'Chatzeilen haben 1 bis 300 Zeichen.';

  @override
  String get wsBadSeat => 'Diesen Platz gibt es nicht.';

  @override
  String get imagesFileType => 'Bilder';

  @override
  String get defaultTableName => 'Freitagsrunde';

  @override
  String get language => 'Sprache';

  @override
  String get languageDevice => 'Gerätesprache';

  @override
  String get errMediaOff =>
      'Sprache und Video sind auf diesem Server nicht eingerichtet.';

  @override
  String get errNotAtTable =>
      'Setz dich zuerst an den Tisch, um Sprache und Video zu nutzen.';

  @override
  String get callJoin => 'Sprache und Video beitreten';

  @override
  String get callMuteMic => 'Mikrofon ausschalten';

  @override
  String get callStopCamera => 'Kamera ausschalten';

  @override
  String get callRemoveUser => 'Aus dem Anruf entfernen';

  @override
  String get callLeave => 'Anruf verlassen';

  @override
  String get callMicOn => 'Mikrofon einschalten';

  @override
  String get callMicOff => 'Mikrofon ausschalten';

  @override
  String get callCameraOn => 'Kamera einschalten';

  @override
  String get callCameraOff => 'Kamera ausschalten';

  @override
  String get callSpeaker => 'Lautsprecher';

  @override
  String get callSwitchCamera => 'Kamera wechseln';

  @override
  String get callConnecting => 'Anruf wird verbunden…';

  @override
  String get callLost =>
      'Der Anruf ist abgebrochen. Das Spiel läuft weiter; tritt wieder bei, wann du willst.';

  @override
  String get callRemoved => 'Du wurdest aus dem Anruf entfernt.';

  @override
  String get callMicRefused =>
      'Oxi Poker darf dein Mikrofon nicht nutzen. Erlaube es in den System- oder Browsereinstellungen und versuche es erneut.';

  @override
  String get callCameraRefused =>
      'Oxi Poker darf deine Kamera nicht nutzen. Erlaube es in den System- oder Browsereinstellungen und versuche es erneut.';

  @override
  String get callHttpsHint =>
      'Browser erlauben Kamera und Mikrofon nur auf Seiten, die über HTTPS geöffnet sind.';

  @override
  String get callBackgroundTitle => 'Oxi Poker Anruf';

  @override
  String get callBackgroundText =>
      'Dein Mikrofon bleibt an, während die App im Hintergrund ist.';

  @override
  String callInCall(int count) {
    return 'Im Anruf: $count';
  }
}
