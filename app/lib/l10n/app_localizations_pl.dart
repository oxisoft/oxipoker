// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Połącz się z serwerem';

  @override
  String get serverHint => 'Adres serwera lub link z zaproszeniem';

  @override
  String get serverHelp =>
      'Wklej link z zaproszeniem od gospodarza albo adres swojego serwera pokerowego.';

  @override
  String get connect => 'Połącz';

  @override
  String get changeServer => 'Zmień serwer';

  @override
  String serverVersion(String version) {
    return 'Serwer $version';
  }

  @override
  String get signInTitle => 'Zaloguj się';

  @override
  String get username => 'Nazwa użytkownika';

  @override
  String get displayName => 'Wyświetlana nazwa';

  @override
  String get displayNameOptional => 'Wyświetlana nazwa (opcjonalnie)';

  @override
  String get password => 'Hasło';

  @override
  String get repeatPassword => 'Powtórz hasło';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get signInPasskey => 'Zaloguj się kluczem dostępu';

  @override
  String get totpTitle => 'Kod weryfikacji dwuetapowej';

  @override
  String get totpHelp =>
      'Wpisz 6-cyfrowy kod z aplikacji uwierzytelniającej albo jeden z kodów odzyskiwania.';

  @override
  String get code => 'Kod';

  @override
  String get verify => 'Zweryfikuj';

  @override
  String get back => 'Wstecz';

  @override
  String get inviteTitle => 'Dołącz z zaproszenia';

  @override
  String inviteNote(String note) {
    return 'Notka od gospodarza: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Link ważny do $date';
  }

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get createWithPasskey => 'Utwórz konto z kluczem dostępu';

  @override
  String get orPassword => 'albo ustaw hasło';

  @override
  String get passwordsDiffer => 'Hasła nie są takie same.';

  @override
  String lobbyWelcome(String name) {
    return 'Witaj, $name';
  }

  @override
  String get lobbySoon => 'Stoły pojawią się w następnej wersji.';

  @override
  String get account => 'Konto';

  @override
  String get admin => 'Admin';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get save => 'Zapisz';

  @override
  String get saved => 'Zapisano';

  @override
  String get cancel => 'Anuluj';

  @override
  String get close => 'Zamknij';

  @override
  String get delete => 'Usuń';

  @override
  String get copy => 'Kopiuj';

  @override
  String get copied => 'Skopiowano';

  @override
  String get remove => 'Usuń';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get profile => 'Profil';

  @override
  String get changePassword => 'Zmień hasło';

  @override
  String get currentPassword => 'Obecne hasło';

  @override
  String get newPassword => 'Nowe hasło';

  @override
  String get passwordChanged =>
      'Hasło zmienione. Pozostałe sesje zostały wylogowane.';

  @override
  String get mustChangeTitle => 'Ustaw nowe hasło';

  @override
  String get mustChangeHelp =>
      'Admin dał ci hasło tymczasowe. Ustaw własne, żeby kontynuować.';

  @override
  String get sessions => 'Sesje';

  @override
  String get thisDevice => 'to urządzenie';

  @override
  String get revoke => 'Wyloguj';

  @override
  String get revokeOthers => 'Wyloguj wszędzie indziej';

  @override
  String lastSeen(String date) {
    return 'ostatnio aktywna $date';
  }

  @override
  String get twoFactor => 'Logowanie dwuetapowe';

  @override
  String twoFactorOn(int count) {
    return 'Włączone, pozostałe kody odzyskiwania: $count';
  }

  @override
  String get twoFactorOff => 'Wyłączone';

  @override
  String get enable => 'Włącz';

  @override
  String get disable => 'Wyłącz';

  @override
  String get totpScan =>
      'Zeskanuj ten kod aplikacją uwierzytelniającą, a potem wpisz 6-cyfrowy kod, który pokaże.';

  @override
  String totpSecret(String secret) {
    return 'Sekret: $secret';
  }

  @override
  String get recoveryTitle => 'Kody odzyskiwania';

  @override
  String get recoveryHelp =>
      'Każdy kod pozwala zalogować się raz, gdy nie masz przy sobie telefonu. Widać je tylko teraz: schowaj je w bezpiecznym miejscu.';

  @override
  String get passkeys => 'Klucze dostępu';

  @override
  String get addPasskey => 'Dodaj klucz dostępu';

  @override
  String get noPasskeys => 'Brak kluczy dostępu.';

  @override
  String get synced => 'synchronizowany';

  @override
  String get passkeyName => 'Nazwa klucza dostępu';

  @override
  String get passkeyUnsupported =>
      'Klucze dostępu nie są dostępne na tym urządzeniu.';

  @override
  String get avatar => 'Awatar';

  @override
  String get uploadAvatar => 'Wgraj zdjęcie';

  @override
  String get dangerZone => 'Usuń konto';

  @override
  String get deleteAccountHelp =>
      'Twoje konto i wszystko, co w nim jest, zostanie usunięte na zawsze.';

  @override
  String get deleteAccountConfirm => 'Wpisz hasło, żeby usunąć konto.';

  @override
  String get users => 'Użytkownicy';

  @override
  String get invitations => 'Zaproszenia';

  @override
  String get settings => 'Ustawienia';

  @override
  String get auditLog => 'Dziennik zdarzeń';

  @override
  String get search => 'Szukaj';

  @override
  String get newUser => 'Nowy użytkownik';

  @override
  String get makeAdmin => 'Admin';

  @override
  String get disabled => 'Wyłączony';

  @override
  String get resetPassword => 'Zresetuj hasło';

  @override
  String get reset2fa => 'Zresetuj weryfikację dwuetapową';

  @override
  String get temporaryPassword => 'Hasło tymczasowe';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Przekaż je prywatnie użytkownikowi $name. Widać je tylko teraz i trzeba je zmienić przy pierwszym logowaniu.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Usunąć użytkownika $name i całą zawartość konta?';
  }

  @override
  String get newInvitation => 'Nowe zaproszenie';

  @override
  String get validHours => 'Ważne przez (godziny)';

  @override
  String get uses => 'Liczba użyć';

  @override
  String get note => 'Notka (opcjonalnie)';

  @override
  String get invitationLink => 'Link z zaproszeniem';

  @override
  String get invitationLinkHelp =>
      'Wyślij ten link graczowi. Widać go tylko teraz.';

  @override
  String invitationUses(int uses, int max) {
    return 'Użyto: $uses z $max';
  }

  @override
  String get invitationRevoked => 'unieważnione';

  @override
  String get invitationExpired => 'wygasło';

  @override
  String joinedBy(String names) {
    return 'Użyte przez: $names';
  }

  @override
  String get tableCreation => 'Kto może tworzyć stoły';

  @override
  String get everyone => 'Każdy gracz';

  @override
  String get adminsOnly => 'Tylko admini';

  @override
  String get maxUpload => 'Maksymalny rozmiar pliku (KiB)';

  @override
  String get loadMore => 'Wczytaj więcej';

  @override
  String get filterAction => 'Akcja (dokładna albo prefiks zakończony kropką)';

  @override
  String get errNetwork => 'Nie można połączyć się z serwerem.';

  @override
  String get errNotServer => 'Pod tym adresem nie ma serwera Oxi Poker.';

  @override
  String get errBadAddress => 'Wpisz adres w stylu poker.example.com.';

  @override
  String get errInvalidCredentials => 'Zła nazwa użytkownika lub hasło.';

  @override
  String get errRateLimited => 'Za dużo prób. Spróbuj ponownie za chwilę.';

  @override
  String get errInvalidCode => 'Ten kod jest nieprawidłowy.';

  @override
  String get errChallengeExpired =>
      'Logowanie trwało za długo. Zacznij od nowa.';

  @override
  String get errInvitationInvalid =>
      'Ten link z zaproszeniem jest nieprawidłowy.';

  @override
  String get errInvitationExpired => 'Ten link z zaproszeniem wygasł.';

  @override
  String get errInvitationUsed => 'Ten link z zaproszeniem został już użyty.';

  @override
  String get errBadUsername =>
      'Nazwa użytkownika ma od 3 do 32 znaków: litery, cyfry, kropki, myślniki lub podkreślenia.';

  @override
  String get errBadDisplayName => 'Wyświetlana nazwa ma od 1 do 64 znaków.';

  @override
  String get errBadPassword => 'Hasło ma od 10 do 256 znaków.';

  @override
  String get errUsernameTaken => 'Ta nazwa użytkownika jest zajęta.';

  @override
  String get errWrongPassword => 'Złe hasło.';

  @override
  String get errLastAdmin => 'Serwer potrzebuje co najmniej jednego admina.';

  @override
  String get errSelf => 'Tutaj nie możesz tego zrobić z własnym kontem.';

  @override
  String get errTooLarge => 'Plik jest za duży.';

  @override
  String get errBadImage => 'Użyj obrazka PNG, JPEG, GIF lub WebP.';

  @override
  String get errPasskeyRejected => 'Klucz dostępu nie został przyjęty.';

  @override
  String get errLastSignInMethod =>
      'To twój ostatni sposób logowania. Najpierw dodaj hasło albo inny klucz dostępu.';

  @override
  String get errBadInvitation =>
      'Godziny od 1 do 720, użycia od 1 do 100, notka do 200 znaków.';

  @override
  String get errBadSettings =>
      'Rozmiar pliku musi wynosić od 256 KiB do 20 MiB.';

  @override
  String errGeneric(String code) {
    return 'Coś poszło nie tak ($code).';
  }

  @override
  String get handHistory => 'Historia rozdań';

  @override
  String get createTable => 'Utwórz stół';

  @override
  String get create => 'Utwórz';

  @override
  String get noTables =>
      'Nie ma jeszcze otwartych stołów. Utwórz stół i zaproś znajomych.';

  @override
  String get closeTable => 'Zamknij stół';

  @override
  String closeTableConfirm(String name) {
    return 'Zamknąć stół $name? Trwające rozdanie zostanie anulowane, a każdy stack wróci do stanu sprzed rozdania.';
  }

  @override
  String blinds(int sb, int bb) {
    return 'Ciemne $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'Stack: $n';
  }

  @override
  String get connecting => 'Łączenie…';

  @override
  String get reconnecting => 'Utracono połączenie, ponowne łączenie…';

  @override
  String get serverRestarting =>
      'Serwer się restartuje. Trwające rozdanie zostanie anulowane, a żetony wrócą do graczy; stół wróci za chwilę.';

  @override
  String get tableName => 'Nazwa stołu';

  @override
  String get seats => 'Miejsca';

  @override
  String get smallBlind => 'Mała ciemna';

  @override
  String get bigBlind => 'Duża ciemna';

  @override
  String get startingStack => 'Stack początkowy';

  @override
  String get turnTime => 'Czas na ruch (sekundy)';

  @override
  String get allowSpectators => 'Pozwól na obserwatorów';

  @override
  String get errTableName => 'Nazwa musi mieć od 1 do 40 znaków.';

  @override
  String get errBlinds =>
      'Ciemne muszą wynosić co najmniej 1, a mała ciemna nie może być wyższa niż duża.';

  @override
  String get errStack =>
      'Stack początkowy musi wynosić co najmniej dwie duże ciemne.';

  @override
  String get errTurnTime => 'Czas na ruch musi wynosić od 5 do 300 sekund.';

  @override
  String get wsNotYourTurn => 'To nie twój ruch.';

  @override
  String get wsSeatTaken => 'To miejsce zostało właśnie zajęte.';

  @override
  String get wsAlreadySeated => 'Masz już miejsce przy tym stole.';

  @override
  String get wsIllegal => 'Ta akcja nie jest teraz możliwa.';

  @override
  String get wsSpectatorsOff =>
      'Przy tym stole nie ma obserwatorów. Zajmij miejsce, żeby dołączyć.';

  @override
  String get table => 'Stół';

  @override
  String get sitOut => 'Pauza';

  @override
  String get comeBack => 'Wracam';

  @override
  String get leaveSeat => 'Zwolnij miejsce';

  @override
  String get chat => 'Czat';

  @override
  String get tableClosed => 'Ten stół jest zamknięty.';

  @override
  String get backToLobby => 'Wróć do lobby';

  @override
  String get watchingHint =>
      'Obserwujesz grę. Wybierz wolne miejsce, żeby zagrać.';

  @override
  String get bustedHint =>
      'Brak żetonów. Wybierz Wracam w menu miejsca, żeby wykupić się ponownie.';

  @override
  String get sittingOutHint =>
      'Masz pauzę. Wybierz Wracam w menu miejsca, żeby zagrać następne rozdanie.';

  @override
  String get waitingForPlayers => 'Czekamy na graczy';

  @override
  String get nextHandSoon => 'Następne rozdanie za chwilę';

  @override
  String waitingFor(String name) {
    return 'Czekamy na: $name';
  }

  @override
  String potMain(String amount) {
    return 'Pula $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Pula boczna $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name wygrywa $amount';
  }

  @override
  String get sit => 'Usiądź tutaj';

  @override
  String get emptySeat => 'Wolne';

  @override
  String get sittingOut => 'Pauza';

  @override
  String get folded => 'Pas';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Podbij do $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Postaw $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Sprawdź $amount';
  }

  @override
  String get presetMin => 'Min';

  @override
  String get presetHalfPot => '½ puli';

  @override
  String get presetPot => 'Pula';

  @override
  String get presetAllIn => 'All-in';

  @override
  String get fold => 'Pas';

  @override
  String get check => 'Czek';

  @override
  String get bet => 'Postaw';

  @override
  String get chatNotStored =>
      'Widzą go gracze i obserwatorzy, nigdy nie jest zapisywany.';

  @override
  String get chatHint => 'Wiadomość';

  @override
  String get noHands => 'Nie rozegrano jeszcze żadnego rozdania.';

  @override
  String potLabel(String amount) {
    return 'pula $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who wpłaca małą ciemną $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who wpłaca dużą ciemną $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who dostaje $cards';
  }

  @override
  String evFold(String who) {
    return '$who pasuje';
  }

  @override
  String evCheck(String who) {
    return '$who czekuje';
  }

  @override
  String evCall(String who, String amount) {
    return '$who sprawdza $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who stawia $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who podbija do $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return 'Zwrot $amount dla: $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who pokazuje $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who wygrywa $amount';
  }

  @override
  String get replay => 'Odtwórz';

  @override
  String get yourCards => 'Twoje karty';

  @override
  String stepOf(int step, int total) {
    return '$step z $total';
  }

  @override
  String get stats => 'Twoje statystyki';

  @override
  String get handsPlayed => 'Rozegrane rozdania';

  @override
  String get handsWon => 'Wygrane rozdania';

  @override
  String get biggestPot => 'Największa wygrana pula';

  @override
  String get sngGames => 'Gry sit and go';

  @override
  String get sngWins => 'Wygrane sit and go';

  @override
  String get sngBest => 'Najlepsze miejsce';

  @override
  String get tableKind => 'Gra';

  @override
  String get kindCash => 'Gra cash';

  @override
  String get kindSng => 'Sit and go';

  @override
  String get structure => 'Poziomy ciemnych';

  @override
  String structureTurbo(int min) {
    return 'Turbo, poziom co $min min';
  }

  @override
  String structureRegular(int min) {
    return 'Normalne, poziom co $min min';
  }

  @override
  String structureSlow(int min) {
    return 'Wolne, poziom co $min min';
  }

  @override
  String get firstBlinds => 'Ciemne na pierwszym poziomie';

  @override
  String sngRegistering(int n) {
    return 'Rejestracja, zajęte miejsca: $n. Gospodarz rozpoczyna grę albo startuje ona sama, gdy wszystkie miejsca są zajęte.';
  }

  @override
  String get startGame => 'Rozpocznij grę';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Poziom $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'następnie $sb/$bb za $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'następnie $sb/$bb od kolejnego rozdania';
  }

  @override
  String get sngLastLevel => 'ostatni poziom';

  @override
  String get standings => 'Końcowa klasyfikacja';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Twoje miejsce: #$place';
  }

  @override
  String get wsSngStarted => 'Sit and go już się zaczął.';

  @override
  String get wsTooFewPlayers => 'Sit and go wymaga co najmniej dwóch graczy.';

  @override
  String get wsHostOnly => 'Tylko gospodarz albo admin może to zrobić.';

  @override
  String get appearance => 'Wygląd';

  @override
  String get theme => 'Motyw';

  @override
  String get themeClassic => 'Klasyczny';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Rewers kart';

  @override
  String get serverDefault => 'Domyślny serwera';

  @override
  String get defaultCardBack => 'Domyślny rewers kart';

  @override
  String get cardBacks => 'Rewersy kart';

  @override
  String get errBadTheme => 'Nieznany motyw.';

  @override
  String get errBadCardBack => 'Ten rewers kart nie jest dostępny.';

  @override
  String get errCardBackDefault => 'Nie można usunąć domyślnego rewersu kart.';

  @override
  String get uploadCardBack => 'Wgraj rewers kart';

  @override
  String get cardBackName => 'Nazwa rewersu kart';

  @override
  String get errTooManyCardBacks =>
      'Wgrano za dużo rewersów kart. Najpierw usuń jeden.';

  @override
  String get chatUserMenuHint =>
      'Stuknij wiadomość na czacie, żeby zablokować lub zgłosić autora.';

  @override
  String get blockUser => 'Zablokuj';

  @override
  String get reportUser => 'Zgłoś';

  @override
  String get muteInChat => 'Wycisz na czacie tego stołu';

  @override
  String get unmuteInChat => 'Cofnij wyciszenie na czacie tego stołu';

  @override
  String get removeSpectator => 'Usuń ze stołu';

  @override
  String userBlocked(String name) {
    return 'Zablokowano użytkownika $name. Nie zobaczysz już jego wiadomości na czacie.';
  }

  @override
  String reportTitle(String name) {
    return 'Zgłoś użytkownika $name';
  }

  @override
  String get reasonChat => 'Czat';

  @override
  String get reasonBehaviour => 'Zachowanie';

  @override
  String get reasonOther => 'Inne';

  @override
  String get reportNote => 'Co się stało? (opcjonalnie)';

  @override
  String get reportChatHint =>
      'Ostatnie wiadomości z czatu tego stołu trafią do zgłoszenia, żeby admin widział, co zostało napisane.';

  @override
  String get sendReport => 'Wyślij zgłoszenie';

  @override
  String get reportSent => 'Zgłoszenie wysłane do admina serwera.';

  @override
  String get blockedUsers => 'Zablokowani użytkownicy';

  @override
  String get noBlockedUsers =>
      'Nie masz zablokowanych osób. Stuknij wiadomość na czacie przy stole, żeby zablokować autora.';

  @override
  String get unblock => 'Odblokuj';

  @override
  String get reports => 'Zgłoszenia';

  @override
  String get showResolved => 'Pokaż rozwiązane zgłoszenia';

  @override
  String get noReports => 'Brak zgłoszeń.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter zgłasza: $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'rozwiązane przez: $name';
  }

  @override
  String get reportNoChat => 'To zgłoszenie nie zawiera wiadomości z czatu.';

  @override
  String get resolve => 'Oznacz jako rozwiązane';

  @override
  String get wsMuted => 'Gospodarz wyciszył cię na czacie tego stołu.';

  @override
  String get wsRemoved => 'Gospodarz usunął cię z tego stołu.';

  @override
  String get wsIsPlayer => 'Nie można usuwać graczy, tylko obserwatorów.';

  @override
  String get errBusy => 'Serwer jest zajęty. Spróbuj ponownie za chwilę.';

  @override
  String get errBadName => 'Nazwa ma od 1 do 64 znaków.';

  @override
  String get errBuiltIn => 'Nie można usuwać wbudowanych rewersów kart.';

  @override
  String get errTotpEnabled => 'Logowanie dwuetapowe jest już włączone.';

  @override
  String get errTotpNotStarted =>
      'Zacznij od nowa konfigurację logowania dwuetapowego.';

  @override
  String get errTotpNotEnabled => 'Logowanie dwuetapowe nie jest włączone.';

  @override
  String get errPasswordChangeRequired => 'Najpierw zmień hasło.';

  @override
  String get errTooManyTables =>
      'Na serwerze jest za dużo otwartych stołów. Spróbuj później.';

  @override
  String get errTooManyPasskeys =>
      'Masz za dużo kluczy dostępu. Najpierw usuń jeden.';

  @override
  String get errTooManyBlocks =>
      'Twoja lista zablokowanych jest pełna. Najpierw kogoś odblokuj.';

  @override
  String get errTooManyReports => 'Wysłano za dużo zgłoszeń. Spróbuj później.';

  @override
  String get errReportSelf => 'Nie możesz zgłosić samego siebie.';

  @override
  String get errBlockSelf => 'Nie możesz zablokować samego siebie.';

  @override
  String get errBadReport => 'Wybierz powód; notka może mieć do 500 znaków.';

  @override
  String get errAdminOnly => 'Tylko admin może to zrobić.';

  @override
  String get errNotFound => 'To już nie istnieje.';

  @override
  String get errUnauthenticated => 'Zaloguj się ponownie.';

  @override
  String get errBadRequest =>
      'Serwer nie zrozumiał żądania. Zaktualizuj aplikację.';

  @override
  String get errInternal => 'Na serwerze wystąpił błąd. Spróbuj ponownie.';

  @override
  String get wsNotSeated => 'Nie masz miejsca przy tym stole.';

  @override
  String get wsNotInHand => 'Nie bierzesz udziału w tym rozdaniu.';

  @override
  String get wsNoTable => 'Ten stół jest zamknięty.';

  @override
  String get wsNotSng => 'Rozpocząć można tylko sit and go.';

  @override
  String get wsBadChat => 'Wiadomość na czacie ma od 1 do 300 znaków.';

  @override
  String get wsBadSeat => 'To miejsce nie istnieje.';

  @override
  String get imagesFileType => 'Obrazy';

  @override
  String get defaultTableName => 'Piątkowa gra';

  @override
  String get language => 'Język';

  @override
  String get languageDevice => 'Język urządzenia';

  @override
  String get errMediaOff =>
      'Głos i wideo nie są skonfigurowane na tym serwerze.';

  @override
  String get errNotAtTable =>
      'Najpierw dołącz do stołu, aby używać głosu i wideo.';

  @override
  String get callJoin => 'Dołącz do głosu i wideo';

  @override
  String get callMuteMic => 'Wyłącz mikrofon tej osoby';

  @override
  String get callStopCamera => 'Wyłącz kamerę tej osoby';

  @override
  String get callRemoveUser => 'Usuń z rozmowy';

  @override
  String get callLeave => 'Opuść rozmowę';

  @override
  String get callMicOn => 'Włącz mikrofon';

  @override
  String get callMicOff => 'Wyłącz mikrofon';

  @override
  String get callCameraOn => 'Włącz kamerę';

  @override
  String get callCameraOff => 'Wyłącz kamerę';

  @override
  String get callSpeaker => 'Głośnik';

  @override
  String get callSwitchCamera => 'Przełącz kamerę';

  @override
  String get callConnecting => 'Łączenie rozmowy…';

  @override
  String get callLost =>
      'Rozmowa została przerwana. Gra toczy się dalej; dołącz ponownie, kiedy chcesz.';

  @override
  String get callRemoved => 'Usunięto cię z rozmowy.';

  @override
  String callInCall(int count) {
    return 'W rozmowie: $count';
  }
}
