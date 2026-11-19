// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Connettiti a un server';

  @override
  String get serverHint => 'Indirizzo del server o link d\'invito';

  @override
  String get serverHelp =>
      'Incolla il link d\'invito che ti ha dato l\'host, o l\'indirizzo del tuo server di poker.';

  @override
  String get connect => 'Connetti';

  @override
  String get changeServer => 'Cambia server';

  @override
  String serverVersion(String version) {
    return 'Server $version';
  }

  @override
  String get signInTitle => 'Accedi';

  @override
  String get username => 'Nome utente';

  @override
  String get displayName => 'Nome visualizzato';

  @override
  String get displayNameOptional => 'Nome visualizzato (facoltativo)';

  @override
  String get password => 'Password';

  @override
  String get repeatPassword => 'Ripeti la password';

  @override
  String get signIn => 'Accedi';

  @override
  String get signInPasskey => 'Accedi con una passkey';

  @override
  String get totpTitle => 'Codice a due fattori';

  @override
  String get totpHelp =>
      'Inserisci il codice a 6 cifre della tua app di autenticazione, o uno dei tuoi codici di recupero.';

  @override
  String get code => 'Codice';

  @override
  String get verify => 'Verifica';

  @override
  String get back => 'Indietro';

  @override
  String get inviteTitle => 'Entra con un invito';

  @override
  String inviteNote(String note) {
    return 'Nota dall\'host: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Link valido fino al $date';
  }

  @override
  String get createAccount => 'Crea account';

  @override
  String get createWithPasskey => 'Crea account con una passkey';

  @override
  String get orPassword => 'oppure scegli una password';

  @override
  String get passwordsDiffer => 'Le password non coincidono.';

  @override
  String lobbyWelcome(String name) {
    return 'Benvenuto, $name';
  }

  @override
  String get lobbySoon => 'I tavoli arrivano nella prossima versione.';

  @override
  String get account => 'Account';

  @override
  String get admin => 'Amministrazione';

  @override
  String get signOut => 'Esci';

  @override
  String get save => 'Salva';

  @override
  String get saved => 'Salvato';

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get delete => 'Elimina';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String get remove => 'Rimuovi';

  @override
  String get rename => 'Rinomina';

  @override
  String get profile => 'Profilo';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get currentPassword => 'Password attuale';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get passwordChanged =>
      'Password cambiata. Le tue altre sessioni sono state disconnesse.';

  @override
  String get mustChangeTitle => 'Scegli una nuova password';

  @override
  String get mustChangeHelp =>
      'L\'admin ti ha dato una password temporanea. Scegline una tua per continuare.';

  @override
  String get sessions => 'Sessioni';

  @override
  String get thisDevice => 'questo dispositivo';

  @override
  String get revoke => 'Disconnetti';

  @override
  String get revokeOthers => 'Disconnetti tutti gli altri dispositivi';

  @override
  String lastSeen(String date) {
    return 'ultimo accesso $date';
  }

  @override
  String get twoFactor => 'Accesso a due fattori';

  @override
  String twoFactorOn(int count) {
    return 'Attivo, $count codici di recupero rimasti';
  }

  @override
  String get twoFactorOff => 'Disattivato';

  @override
  String get enable => 'Attiva';

  @override
  String get disable => 'Disattiva';

  @override
  String get totpScan =>
      'Scansiona questo codice con la tua app di autenticazione, poi inserisci il codice a 6 cifre che mostra.';

  @override
  String totpSecret(String secret) {
    return 'Chiave segreta: $secret';
  }

  @override
  String get recoveryTitle => 'Codici di recupero';

  @override
  String get recoveryHelp =>
      'Ogni codice ti fa accedere una volta quando non hai il telefono a portata di mano. Li vedi solo ora: conservali in un posto sicuro.';

  @override
  String get passkeys => 'Passkey';

  @override
  String get addPasskey => 'Aggiungi una passkey';

  @override
  String get noPasskeys => 'Ancora nessuna passkey.';

  @override
  String get synced => 'sincronizzata';

  @override
  String get passkeyName => 'Nome della passkey';

  @override
  String get passkeyUnsupported =>
      'Le passkey non sono disponibili su questo dispositivo.';

  @override
  String get avatar => 'Avatar';

  @override
  String get uploadAvatar => 'Carica immagine';

  @override
  String get dangerZone => 'Elimina account';

  @override
  String get deleteAccountHelp =>
      'Il tuo account e tutto il suo contenuto vengono eliminati per sempre.';

  @override
  String get deleteAccountConfirm =>
      'Inserisci la password per eliminare il tuo account.';

  @override
  String get users => 'Utenti';

  @override
  String get invitations => 'Inviti';

  @override
  String get settings => 'Impostazioni';

  @override
  String get auditLog => 'Registro attività';

  @override
  String get search => 'Cerca';

  @override
  String get newUser => 'Nuovo utente';

  @override
  String get makeAdmin => 'Admin';

  @override
  String get disabled => 'Disattivato';

  @override
  String get resetPassword => 'Reimposta password';

  @override
  String get reset2fa => 'Reimposta due fattori';

  @override
  String get temporaryPassword => 'Password temporanea';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Dalla a $name in privato. La vedi solo ora e va cambiata al primo accesso.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Eliminare $name e tutto il contenuto dell\'account?';
  }

  @override
  String get newInvitation => 'Nuovo invito';

  @override
  String get validHours => 'Validità (ore)';

  @override
  String get uses => 'Utilizzi';

  @override
  String get note => 'Nota (facoltativa)';

  @override
  String get invitationLink => 'Link d\'invito';

  @override
  String get invitationLinkHelp =>
      'Manda questo link al giocatore. Lo vedi solo ora.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses di $max usati';
  }

  @override
  String get invitationRevoked => 'revocato';

  @override
  String get invitationExpired => 'scaduto';

  @override
  String joinedBy(String names) {
    return 'Entrati: $names';
  }

  @override
  String get tableCreation => 'Chi può creare tavoli';

  @override
  String get everyone => 'Tutti i giocatori';

  @override
  String get adminsOnly => 'Solo gli admin';

  @override
  String get maxUpload => 'Dimensione massima upload (KiB)';

  @override
  String get loadMore => 'Carica altro';

  @override
  String get filterAction =>
      'Azione (esatta, o prefisso che finisce con un punto)';

  @override
  String get errNetwork => 'Impossibile raggiungere il server.';

  @override
  String get errNotServer =>
      'Nessun server Oxi Poker risponde a questo indirizzo.';

  @override
  String get errBadAddress => 'Inserisci un indirizzo tipo poker.example.com.';

  @override
  String get errInvalidCredentials => 'Nome utente o password errati.';

  @override
  String get errRateLimited => 'Troppi tentativi. Riprova tra un po\'.';

  @override
  String get errInvalidCode => 'Questo codice non è valido.';

  @override
  String get errChallengeExpired =>
      'L\'accesso ha richiesto troppo tempo. Ricomincia.';

  @override
  String get errInvitationInvalid => 'Questo link d\'invito non è valido.';

  @override
  String get errInvitationExpired => 'Questo link d\'invito è scaduto.';

  @override
  String get errInvitationUsed => 'Questo link d\'invito è già stato usato.';

  @override
  String get errBadUsername =>
      'Il nome utente ha da 3 a 32 lettere, cifre, punti, trattini o trattini bassi.';

  @override
  String get errBadDisplayName =>
      'Il nome visualizzato ha da 1 a 64 caratteri.';

  @override
  String get errBadPassword => 'La password ha da 10 a 256 caratteri.';

  @override
  String get errUsernameTaken => 'Questo nome utente è già in uso.';

  @override
  String get errWrongPassword => 'La password è sbagliata.';

  @override
  String get errLastAdmin => 'Il server ha bisogno di almeno un admin.';

  @override
  String get errSelf => 'Qui non puoi farlo sul tuo account.';

  @override
  String get errTooLarge => 'Il file è troppo grande.';

  @override
  String get errBadImage => 'Usa un\'immagine PNG, JPEG, GIF o WebP.';

  @override
  String get errPasskeyRejected => 'La passkey non è stata accettata.';

  @override
  String get errLastSignInMethod =>
      'Questo è il tuo ultimo modo per accedere. Prima aggiungi una password o un\'altra passkey.';

  @override
  String get errBadInvitation =>
      'Ore da 1 a 720, utilizzi da 1 a 100, nota fino a 200 caratteri.';

  @override
  String get errBadSettings =>
      'La dimensione upload deve essere tra 256 KiB e 20 MiB.';

  @override
  String errGeneric(String code) {
    return 'Qualcosa è andato storto ($code).';
  }

  @override
  String get handHistory => 'Storico mani';

  @override
  String get createTable => 'Crea tavolo';

  @override
  String get create => 'Crea';

  @override
  String get noTables =>
      'Ancora nessun tavolo aperto. Creane uno e invita i tuoi amici.';

  @override
  String get closeTable => 'Chiudi tavolo';

  @override
  String closeTableConfirm(String name) {
    return 'Chiudere il tavolo $name? La mano in corso viene annullata e ogni stack torna com\'era.';
  }

  @override
  String blinds(int sb, int bb) {
    return 'Blind $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'Stack $n';
  }

  @override
  String get connecting => 'Connessione…';

  @override
  String get reconnecting => 'Connessione persa, riconnessione…';

  @override
  String get serverRestarting =>
      'Il server si sta riavviando. La mano in gioco viene annullata e le fiche tornano indietro; il tavolo riapre tra un attimo.';

  @override
  String get tableName => 'Nome del tavolo';

  @override
  String get seats => 'Posti';

  @override
  String get smallBlind => 'Small blind';

  @override
  String get bigBlind => 'Big blind';

  @override
  String get startingStack => 'Stack iniziale';

  @override
  String get turnTime => 'Tempo per turno (secondi)';

  @override
  String get allowSpectators => 'Consenti spettatori';

  @override
  String get errTableName => 'Il nome deve avere da 1 a 40 caratteri.';

  @override
  String get errBlinds =>
      'I blind devono essere almeno 1, e lo small blind non oltre il big blind.';

  @override
  String get errStack =>
      'Lo stack iniziale deve essere almeno di due big blind.';

  @override
  String get errTurnTime =>
      'Il tempo per turno deve essere tra 5 e 300 secondi.';

  @override
  String get wsNotYourTurn => 'Non è il tuo turno.';

  @override
  String get wsSeatTaken => 'Quel posto è appena stato preso.';

  @override
  String get wsAlreadySeated => 'Hai già un posto a questo tavolo.';

  @override
  String get wsIllegal => 'Questa azione non è possibile adesso.';

  @override
  String get wsSpectatorsOff =>
      'Questo tavolo non ammette spettatori. Siediti per partecipare.';

  @override
  String get table => 'Tavolo';

  @override
  String get sitOut => 'Sit out';

  @override
  String get comeBack => 'Rientra';

  @override
  String get leaveSeat => 'Lascia il posto';

  @override
  String get chat => 'Chat';

  @override
  String get tableClosed => 'Questo tavolo è chiuso.';

  @override
  String get backToLobby => 'Torna alla lobby';

  @override
  String get watchingHint =>
      'Stai guardando. Scegli un posto libero per giocare.';

  @override
  String get bustedHint =>
      'Hai finito le fiche. Usa Rientra nel menu del posto per fare un nuovo buy-in.';

  @override
  String get sittingOutHint =>
      'Sei in sit out. Usa Rientra nel menu del posto per giocare la prossima mano.';

  @override
  String get waitingForPlayers => 'In attesa di giocatori';

  @override
  String get nextHandSoon => 'La prossima mano inizia tra un attimo';

  @override
  String waitingFor(String name) {
    return 'In attesa di $name';
  }

  @override
  String potMain(String amount) {
    return 'Piatto $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Piatto laterale $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name vince $amount';
  }

  @override
  String get sit => 'Siediti qui';

  @override
  String get emptySeat => 'Libero';

  @override
  String get sittingOut => 'In sit out';

  @override
  String get folded => 'Ha passato';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Rilancia a $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Punta $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Chiama $amount';
  }

  @override
  String get presetMin => 'Min';

  @override
  String get presetHalfPot => '½ piatto';

  @override
  String get presetPot => 'Piatto';

  @override
  String get presetAllIn => 'All-in';

  @override
  String get fold => 'Passa';

  @override
  String get check => 'Check';

  @override
  String get bet => 'Punta';

  @override
  String get chatNotStored => 'Visibile a giocatori e spettatori, mai salvata.';

  @override
  String get chatHint => 'Messaggio';

  @override
  String get noHands => 'Ancora nessuna mano giocata.';

  @override
  String potLabel(String amount) {
    return 'piatto $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who mette lo small blind $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who mette il big blind $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who riceve $cards';
  }

  @override
  String evFold(String who) {
    return '$who passa';
  }

  @override
  String evCheck(String who) {
    return '$who fa check';
  }

  @override
  String evCall(String who, String amount) {
    return '$who chiama $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who punta $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who rilancia a $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount restituiti a $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who mostra $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who vince $amount';
  }

  @override
  String get replay => 'Rivedi';

  @override
  String get yourCards => 'Le tue carte';

  @override
  String stepOf(int step, int total) {
    return '$step di $total';
  }

  @override
  String get stats => 'Le tue statistiche';

  @override
  String get handsPlayed => 'Mani giocate';

  @override
  String get handsWon => 'Mani vinte';

  @override
  String get biggestPot => 'Piatto più grande vinto';

  @override
  String get sngGames => 'Partite sit and go';

  @override
  String get sngWins => 'Vittorie sit and go';

  @override
  String get sngBest => 'Miglior piazzamento';

  @override
  String get tableKind => 'Partita';

  @override
  String get kindCash => 'Cash game';

  @override
  String get kindSng => 'Sit and go';

  @override
  String get structure => 'Livelli dei blind';

  @override
  String structureTurbo(int min) {
    return 'Turbo, $min min';
  }

  @override
  String structureRegular(int min) {
    return 'Normale, $min min';
  }

  @override
  String structureSlow(int min) {
    return 'Lento, $min min';
  }

  @override
  String get firstBlinds => 'Blind del primo livello';

  @override
  String sngRegistering(int n) {
    return 'Iscrizioni: $n seduti. L\'host avvia la partita, oppure parte quando tutti i posti sono occupati.';
  }

  @override
  String get startGame => 'Avvia la partita';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Livello $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'prossimo $sb/$bb tra $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'prossimo $sb/$bb dalla prossima mano';
  }

  @override
  String get sngLastLevel => 'ultimo livello';

  @override
  String get standings => 'Classifica finale';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Sei arrivato $place°';
  }

  @override
  String get wsSngStarted => 'Il sit and go è già iniziato.';

  @override
  String get wsTooFewPlayers => 'Un sit and go richiede almeno due giocatori.';

  @override
  String get wsHostOnly => 'Solo l\'host o un admin può farlo.';

  @override
  String get appearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get themeClassic => 'Classico';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Dorso delle carte';

  @override
  String get serverDefault => 'Predefinito del server';

  @override
  String get defaultCardBack => 'Dorso predefinito';

  @override
  String get cardBacks => 'Dorsi delle carte';

  @override
  String get errBadTheme => 'Tema sconosciuto.';

  @override
  String get errBadCardBack => 'Questo dorso non è disponibile.';

  @override
  String get errCardBackDefault =>
      'Il dorso predefinito non può essere eliminato.';

  @override
  String get uploadCardBack => 'Carica un dorso';

  @override
  String get cardBackName => 'Nome del dorso';

  @override
  String get errTooManyCardBacks =>
      'Ci sono troppi dorsi caricati. Eliminane prima uno.';

  @override
  String get chatUserMenuHint =>
      'Tocca una riga della chat per bloccare o segnalare l\'autore.';

  @override
  String get blockUser => 'Blocca';

  @override
  String get reportUser => 'Segnala';

  @override
  String get muteInChat => 'Silenzia nella chat di questo tavolo';

  @override
  String get unmuteInChat => 'Riattiva nella chat di questo tavolo';

  @override
  String get removeSpectator => 'Rimuovi dal tavolo';

  @override
  String userBlocked(String name) {
    return '$name è bloccato. Non vedi più i suoi messaggi in chat.';
  }

  @override
  String reportTitle(String name) {
    return 'Segnala $name';
  }

  @override
  String get reasonChat => 'Chat';

  @override
  String get reasonBehaviour => 'Comportamento';

  @override
  String get reasonOther => 'Altro';

  @override
  String get reportNote => 'Cos\'è successo? (facoltativo)';

  @override
  String get reportChatHint =>
      'Le ultime righe della chat di questo tavolo vengono allegate alla segnalazione, così l\'admin vede cosa è stato detto.';

  @override
  String get sendReport => 'Invia segnalazione';

  @override
  String get reportSent => 'Segnalazione inviata all\'admin del server.';

  @override
  String get blockedUsers => 'Utenti bloccati';

  @override
  String get noBlockedUsers =>
      'Non hai bloccato nessuno. Tocca una riga della chat a un tavolo per bloccarne l\'autore.';

  @override
  String get unblock => 'Sblocca';

  @override
  String get reports => 'Segnalazioni';

  @override
  String get showResolved => 'Mostra segnalazioni risolte';

  @override
  String get noReports => 'Nessuna segnalazione.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter ha segnalato $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'risolta da $name';
  }

  @override
  String get reportNoChat => 'Nessuna riga di chat in questa segnalazione.';

  @override
  String get resolve => 'Segna come risolta';

  @override
  String get wsMuted => 'L\'host ti ha silenziato nella chat di questo tavolo.';

  @override
  String get wsRemoved => 'L\'host ti ha rimosso da questo tavolo.';

  @override
  String get wsIsPlayer =>
      'I giocatori non possono essere rimossi; solo gli spettatori.';

  @override
  String get errBusy => 'Il server è occupato. Riprova tra un attimo.';

  @override
  String get errBadName => 'I nomi hanno da 1 a 64 caratteri.';

  @override
  String get errBuiltIn => 'I dorsi integrati non possono essere eliminati.';

  @override
  String get errTotpEnabled => 'L\'accesso a due fattori è già attivo.';

  @override
  String get errTotpNotStarted => 'Ricomincia la configurazione a due fattori.';

  @override
  String get errTotpNotEnabled => 'L\'accesso a due fattori non è attivo.';

  @override
  String get errPasswordChangeRequired => 'Prima cambia la password.';

  @override
  String get errTooManyTables =>
      'Il server ha troppi tavoli aperti. Riprova più tardi.';

  @override
  String get errTooManyPasskeys => 'Hai troppe passkey. Eliminane prima una.';

  @override
  String get errTooManyBlocks =>
      'La tua lista di blocchi è piena. Sblocca prima qualcuno.';

  @override
  String get errTooManyReports =>
      'Hai inviato troppe segnalazioni. Riprova più tardi.';

  @override
  String get errReportSelf => 'Non puoi segnalare te stesso.';

  @override
  String get errBlockSelf => 'Non puoi bloccare te stesso.';

  @override
  String get errBadReport =>
      'Scegli un motivo; la nota ha al massimo 500 caratteri.';

  @override
  String get errAdminOnly => 'Solo un admin può farlo.';

  @override
  String get errNotFound => 'Non esiste più.';

  @override
  String get errUnauthenticated => 'Accedi di nuovo.';

  @override
  String get errBadRequest =>
      'Il server non ha capito la richiesta. Aggiorna l\'app.';

  @override
  String get errInternal => 'Il server ha avuto un errore. Riprova.';

  @override
  String get wsNotSeated => 'Non hai un posto a questo tavolo.';

  @override
  String get wsNotInHand => 'Non sei in questa mano.';

  @override
  String get wsNoTable => 'Questo tavolo è chiuso.';

  @override
  String get wsNotSng => 'Si può avviare solo un sit and go.';

  @override
  String get wsBadChat => 'Le righe di chat hanno da 1 a 300 caratteri.';

  @override
  String get wsBadSeat => 'Quel posto non esiste.';

  @override
  String get imagesFileType => 'Immagini';

  @override
  String get defaultTableName => 'Partita del venerdì';

  @override
  String get language => 'Lingua';

  @override
  String get languageDevice => 'Lingua del dispositivo';

  @override
  String get errMediaOff =>
      'Voce e video non sono configurati su questo server.';

  @override
  String get errNotAtTable =>
      'Unisciti prima al tavolo per usare voce e video.';

  @override
  String get callJoin => 'Entra in voce e video';

  @override
  String get callMuteMic => 'Spegni il suo microfono';

  @override
  String get callStopCamera => 'Spegni la sua fotocamera';

  @override
  String get callRemoveUser => 'Togli dalla chiamata';

  @override
  String get callLeave => 'Esci dalla chiamata';

  @override
  String get callMicOn => 'Attiva microfono';

  @override
  String get callMicOff => 'Disattiva microfono';

  @override
  String get callCameraOn => 'Attiva fotocamera';

  @override
  String get callCameraOff => 'Disattiva fotocamera';

  @override
  String get callSpeaker => 'Altoparlante';

  @override
  String get callSwitchCamera => 'Cambia fotocamera';

  @override
  String get callConnecting => 'Connessione alla chiamata…';

  @override
  String get callLost =>
      'La chiamata è caduta. La partita continua; rientra quando vuoi.';

  @override
  String get callRemoved => 'Sei stato rimosso dalla chiamata.';

  @override
  String get callMicRefused =>
      'Oxi Poker non può usare il microfono. Consentilo nelle impostazioni del sistema o del browser e riprova.';

  @override
  String get callCameraRefused =>
      'Oxi Poker non può usare la fotocamera. Consentila nelle impostazioni del sistema o del browser e riprova.';

  @override
  String get callHttpsHint =>
      'I browser consentono fotocamera e microfono solo nelle pagine aperte via HTTPS.';

  @override
  String get callBackgroundTitle => 'Chiamata Oxi Poker';

  @override
  String get callBackgroundText =>
      'Il microfono resta attivo mentre l\'app è in background.';

  @override
  String callInCall(int count) {
    return 'Nella chiamata: $count';
  }
}
