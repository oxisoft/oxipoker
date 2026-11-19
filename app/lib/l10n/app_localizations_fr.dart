// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Se connecter à un serveur';

  @override
  String get serverHint => 'Adresse du serveur ou lien d\'invitation';

  @override
  String get serverHelp =>
      'Colle le lien d\'invitation reçu de ton hôte, ou l\'adresse de ton serveur de poker.';

  @override
  String get connect => 'Se connecter';

  @override
  String get changeServer => 'Changer de serveur';

  @override
  String serverVersion(String version) {
    return 'Serveur $version';
  }

  @override
  String get signInTitle => 'Connexion';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get displayNameOptional => 'Nom affiché (facultatif)';

  @override
  String get password => 'Mot de passe';

  @override
  String get repeatPassword => 'Répète le mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signInPasskey => 'Se connecter avec une clé d\'accès';

  @override
  String get totpTitle => 'Code de double authentification';

  @override
  String get totpHelp =>
      'Saisis le code à 6 chiffres de ton appli d\'authentification, ou l\'un de tes codes de secours.';

  @override
  String get code => 'Code';

  @override
  String get verify => 'Vérifier';

  @override
  String get back => 'Retour';

  @override
  String get inviteTitle => 'Rejoindre avec une invitation';

  @override
  String inviteNote(String note) {
    return 'Note de ton hôte : $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Lien valable jusqu\'au $date';
  }

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createWithPasskey => 'Créer un compte avec une clé d\'accès';

  @override
  String get orPassword => 'ou choisis un mot de passe';

  @override
  String get passwordsDiffer => 'Les mots de passe ne correspondent pas.';

  @override
  String lobbyWelcome(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String get lobbySoon => 'Les tables ouvrent dans la prochaine version.';

  @override
  String get account => 'Compte';

  @override
  String get admin => 'Administration';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get save => 'Enregistrer';

  @override
  String get saved => 'Enregistré';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get delete => 'Supprimer';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get remove => 'Retirer';

  @override
  String get rename => 'Renommer';

  @override
  String get profile => 'Profil';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get passwordChanged =>
      'Mot de passe changé. Tes autres sessions ont été déconnectées.';

  @override
  String get mustChangeTitle => 'Choisis un nouveau mot de passe';

  @override
  String get mustChangeHelp =>
      'Ton admin t\'a donné un mot de passe temporaire. Choisis le tien pour continuer.';

  @override
  String get sessions => 'Sessions';

  @override
  String get thisDevice => 'cet appareil';

  @override
  String get revoke => 'Déconnecter';

  @override
  String get revokeOthers => 'Déconnecter tous les autres appareils';

  @override
  String lastSeen(String date) {
    return 'vu le $date';
  }

  @override
  String get twoFactor => 'Double authentification';

  @override
  String twoFactorOn(int count) {
    return 'Activée, $count codes de secours restants';
  }

  @override
  String get twoFactorOff => 'Désactivée';

  @override
  String get enable => 'Activer';

  @override
  String get disable => 'Désactiver';

  @override
  String get totpScan =>
      'Scanne ce code avec ton appli d\'authentification, puis saisis le code à 6 chiffres affiché.';

  @override
  String totpSecret(String secret) {
    return 'Secret : $secret';
  }

  @override
  String get recoveryTitle => 'Codes de secours';

  @override
  String get recoveryHelp =>
      'Chaque code te connecte une seule fois quand tu n\'as pas ton téléphone. Ils ne s\'affichent que maintenant : garde-les en lieu sûr.';

  @override
  String get passkeys => 'Clés d\'accès';

  @override
  String get addPasskey => 'Ajouter une clé d\'accès';

  @override
  String get noPasskeys => 'Aucune clé d\'accès pour l\'instant.';

  @override
  String get synced => 'synchronisée';

  @override
  String get passkeyName => 'Nom de la clé d\'accès';

  @override
  String get passkeyUnsupported =>
      'Les clés d\'accès ne sont pas disponibles sur cet appareil.';

  @override
  String get avatar => 'Avatar';

  @override
  String get uploadAvatar => 'Envoyer une image';

  @override
  String get dangerZone => 'Supprimer le compte';

  @override
  String get deleteAccountHelp =>
      'Ton compte et tout son contenu sont supprimés définitivement.';

  @override
  String get deleteAccountConfirm =>
      'Saisis ton mot de passe pour supprimer ton compte.';

  @override
  String get users => 'Utilisateurs';

  @override
  String get invitations => 'Invitations';

  @override
  String get settings => 'Réglages';

  @override
  String get auditLog => 'Journal d\'audit';

  @override
  String get search => 'Rechercher';

  @override
  String get newUser => 'Nouvel utilisateur';

  @override
  String get makeAdmin => 'Admin';

  @override
  String get disabled => 'Désactivé';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get reset2fa => 'Réinitialiser la double authentification';

  @override
  String get temporaryPassword => 'Mot de passe temporaire';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Transmets-le à $name en privé. Il ne s\'affiche que maintenant et devra être changé à la première connexion.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Supprimer $name et tout le contenu du compte ?';
  }

  @override
  String get newInvitation => 'Nouvelle invitation';

  @override
  String get validHours => 'Valable pendant (heures)';

  @override
  String get uses => 'Utilisations';

  @override
  String get note => 'Note (facultatif)';

  @override
  String get invitationLink => 'Lien d\'invitation';

  @override
  String get invitationLinkHelp =>
      'Envoie ce lien au joueur. Il ne s\'affiche que maintenant.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses sur $max utilisées';
  }

  @override
  String get invitationRevoked => 'révoquée';

  @override
  String get invitationExpired => 'expirée';

  @override
  String joinedBy(String names) {
    return 'Ont rejoint : $names';
  }

  @override
  String get tableCreation => 'Qui peut créer des tables';

  @override
  String get everyone => 'Tous les joueurs';

  @override
  String get adminsOnly => 'Admins uniquement';

  @override
  String get maxUpload => 'Taille maximale d\'envoi (Kio)';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get filterAction =>
      'Action (exacte, ou préfixe finissant par un point)';

  @override
  String get errNetwork => 'Impossible de joindre le serveur.';

  @override
  String get errNotServer =>
      'Aucun serveur Oxi Poker ne répond à cette adresse.';

  @override
  String get errBadAddress => 'Saisis une adresse du type poker.example.com.';

  @override
  String get errInvalidCredentials =>
      'Nom d\'utilisateur ou mot de passe incorrect.';

  @override
  String get errRateLimited => 'Trop de tentatives. Réessaie dans un moment.';

  @override
  String get errInvalidCode => 'Ce code n\'est pas valide.';

  @override
  String get errChallengeExpired =>
      'La connexion a pris trop de temps. Recommence.';

  @override
  String get errInvitationInvalid => 'Ce lien d\'invitation n\'est pas valide.';

  @override
  String get errInvitationExpired => 'Ce lien d\'invitation a expiré.';

  @override
  String get errInvitationUsed => 'Ce lien d\'invitation a déjà été utilisé.';

  @override
  String get errBadUsername =>
      'Les noms d\'utilisateur font 3 à 32 caractères : lettres, chiffres, points, tirets ou tirets bas.';

  @override
  String get errBadDisplayName => 'Les noms affichés font 1 à 64 caractères.';

  @override
  String get errBadPassword => 'Les mots de passe font 10 à 256 caractères.';

  @override
  String get errUsernameTaken => 'Ce nom d\'utilisateur est déjà pris.';

  @override
  String get errWrongPassword => 'Le mot de passe est incorrect.';

  @override
  String get errLastAdmin => 'Le serveur a besoin d\'au moins un admin.';

  @override
  String get errSelf => 'Tu ne peux pas faire ça sur ton propre compte ici.';

  @override
  String get errTooLarge => 'Le fichier est trop volumineux.';

  @override
  String get errBadImage => 'Utilise une image PNG, JPEG, GIF ou WebP.';

  @override
  String get errPasskeyRejected => 'La clé d\'accès n\'a pas été acceptée.';

  @override
  String get errLastSignInMethod =>
      'C\'est ton dernier moyen de connexion. Ajoute d\'abord un mot de passe ou une autre clé d\'accès.';

  @override
  String get errBadInvitation =>
      'Heures de 1 à 720, utilisations de 1 à 100, note de 200 caractères maximum.';

  @override
  String get errBadSettings =>
      'La taille d\'envoi doit être comprise entre 256 Kio et 20 Mio.';

  @override
  String errGeneric(String code) {
    return 'Un problème est survenu ($code).';
  }

  @override
  String get handHistory => 'Historique des mains';

  @override
  String get createTable => 'Créer une table';

  @override
  String get create => 'Créer';

  @override
  String get noTables =>
      'Aucune table ouverte pour l\'instant. Crées-en une et invite tes amis.';

  @override
  String get closeTable => 'Fermer la table';

  @override
  String closeTableConfirm(String name) {
    return 'Fermer la table $name ? La main en cours est annulée et chaque stack revient à son état précédent.';
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
  String get connecting => 'Connexion…';

  @override
  String get reconnecting => 'Connexion perdue, reconnexion…';

  @override
  String get serverRestarting =>
      'Le serveur redémarre. La main en cours est annulée et les jetons sont rendus ; la table revient dans un instant.';

  @override
  String get tableName => 'Nom de la table';

  @override
  String get seats => 'Places';

  @override
  String get smallBlind => 'Petite blind';

  @override
  String get bigBlind => 'Grosse blind';

  @override
  String get startingStack => 'Stack de départ';

  @override
  String get turnTime => 'Temps de parole (secondes)';

  @override
  String get allowSpectators => 'Autoriser les spectateurs';

  @override
  String get errTableName => 'Le nom doit faire 1 à 40 caractères.';

  @override
  String get errBlinds =>
      'Les blinds doivent valoir au moins 1, et la petite blind ne pas dépasser la grosse blind.';

  @override
  String get errStack =>
      'Le stack de départ doit valoir au moins deux grosses blinds.';

  @override
  String get errTurnTime => 'Le temps de parole doit être de 5 à 300 secondes.';

  @override
  String get wsNotYourTurn => 'Ce n\'est pas à toi de parler.';

  @override
  String get wsSeatTaken => 'Cette place vient d\'être prise.';

  @override
  String get wsAlreadySeated => 'Tu as déjà une place à cette table.';

  @override
  String get wsIllegal => 'Cette action n\'est pas possible pour le moment.';

  @override
  String get wsSpectatorsOff =>
      'Cette table n\'accepte pas de spectateurs. Prends une place pour la rejoindre.';

  @override
  String get table => 'Table';

  @override
  String get sitOut => 'Faire une pause';

  @override
  String get comeBack => 'Revenir';

  @override
  String get leaveSeat => 'Quitter la place';

  @override
  String get chat => 'Chat';

  @override
  String get tableClosed => 'Cette table est fermée.';

  @override
  String get backToLobby => 'Retour au lobby';

  @override
  String get watchingHint => 'Tu regardes. Choisis une place libre pour jouer.';

  @override
  String get bustedHint =>
      'Plus de jetons. Utilise Revenir dans le menu de la place pour te recaver.';

  @override
  String get sittingOutHint =>
      'Tu es en pause. Utilise Revenir dans le menu de la place pour jouer la prochaine main.';

  @override
  String get waitingForPlayers => 'En attente de joueurs';

  @override
  String get nextHandSoon => 'La prochaine main commence dans un instant';

  @override
  String waitingFor(String name) {
    return 'En attente de $name';
  }

  @override
  String potMain(String amount) {
    return 'Pot $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Pot annexe $n : $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name gagne $amount';
  }

  @override
  String get sit => 'S\'asseoir ici';

  @override
  String get emptySeat => 'Libre';

  @override
  String get sittingOut => 'En pause';

  @override
  String get folded => 'Couché';

  @override
  String get allIn => 'Tapis';

  @override
  String allInTo(String amount) {
    return 'Tapis $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Relancer à $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Miser $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Suivre $amount';
  }

  @override
  String get presetMin => 'Min';

  @override
  String get presetHalfPot => '½ pot';

  @override
  String get presetPot => 'Pot';

  @override
  String get presetAllIn => 'Tapis';

  @override
  String get fold => 'Se coucher';

  @override
  String get check => 'Parole';

  @override
  String get bet => 'Miser';

  @override
  String get chatNotStored =>
      'Visible par les joueurs et les spectateurs, jamais enregistré.';

  @override
  String get chatHint => 'Message';

  @override
  String get noHands => 'Aucune main jouée pour l\'instant.';

  @override
  String potLabel(String amount) {
    return 'pot $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who paie la petite blind $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who paie la grosse blind $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who reçoit $cards';
  }

  @override
  String evFold(String who) {
    return '$who se couche';
  }

  @override
  String evCheck(String who) {
    return '$who checke';
  }

  @override
  String evCall(String who, String amount) {
    return '$who suit $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who mise $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who relance à $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount rendu à $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street : $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who montre $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who gagne $amount';
  }

  @override
  String get replay => 'Revoir';

  @override
  String get yourCards => 'Tes cartes';

  @override
  String stepOf(int step, int total) {
    return '$step sur $total';
  }

  @override
  String get stats => 'Tes stats';

  @override
  String get handsPlayed => 'Mains jouées';

  @override
  String get handsWon => 'Mains gagnées';

  @override
  String get biggestPot => 'Plus gros pot gagné';

  @override
  String get sngGames => 'Parties de sit and go';

  @override
  String get sngWins => 'Sit and go gagnés';

  @override
  String get sngBest => 'Meilleure place';

  @override
  String get tableKind => 'Partie';

  @override
  String get kindCash => 'Cash game';

  @override
  String get kindSng => 'Sit and go';

  @override
  String get structure => 'Niveaux de blinds';

  @override
  String structureTurbo(int min) {
    return 'Turbo, $min min';
  }

  @override
  String structureRegular(int min) {
    return 'Normal, $min min';
  }

  @override
  String structureSlow(int min) {
    return 'Lent, $min min';
  }

  @override
  String get firstBlinds => 'Blinds du premier niveau';

  @override
  String sngRegistering(int n) {
    return 'Inscriptions : $n assis. L\'hôte lance la partie, ou elle démarre quand toutes les places sont prises.';
  }

  @override
  String get startGame => 'Lancer la partie';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Niveau $n : $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'ensuite $sb/$bb dans $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'ensuite $sb/$bb dès la prochaine main';
  }

  @override
  String get sngLastLevel => 'dernier niveau';

  @override
  String get standings => 'Classement final';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Tu as terminé #$place';
  }

  @override
  String get wsSngStarted => 'Le sit and go a déjà commencé.';

  @override
  String get wsTooFewPlayers => 'Un sit and go demande au moins deux joueurs.';

  @override
  String get wsHostOnly => 'Seul l\'hôte ou un admin peut faire ça.';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get themeClassic => 'Classique';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Dos de carte';

  @override
  String get serverDefault => 'Par défaut du serveur';

  @override
  String get defaultCardBack => 'Dos de carte par défaut';

  @override
  String get cardBacks => 'Dos de carte';

  @override
  String get errBadTheme => 'Thème inconnu.';

  @override
  String get errBadCardBack => 'Ce dos de carte n\'est pas disponible.';

  @override
  String get errCardBackDefault =>
      'Le dos de carte par défaut ne peut pas être supprimé.';

  @override
  String get uploadCardBack => 'Envoyer un dos de carte';

  @override
  String get cardBackName => 'Nom du dos de carte';

  @override
  String get errTooManyCardBacks =>
      'Il y a trop de dos de carte envoyés. Supprimes-en un d\'abord.';

  @override
  String get chatUserMenuHint =>
      'Touche une ligne du chat pour bloquer ou signaler son auteur.';

  @override
  String get blockUser => 'Bloquer';

  @override
  String get reportUser => 'Signaler';

  @override
  String get muteInChat => 'Rendre muet dans le chat de cette table';

  @override
  String get unmuteInChat => 'Réactiver dans le chat de cette table';

  @override
  String get removeSpectator => 'Retirer de la table';

  @override
  String userBlocked(String name) {
    return '$name est bloqué. Tu ne vois plus ses messages.';
  }

  @override
  String reportTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String get reasonChat => 'Chat';

  @override
  String get reasonBehaviour => 'Comportement';

  @override
  String get reasonOther => 'Autre';

  @override
  String get reportNote => 'Que s\'est-il passé ? (facultatif)';

  @override
  String get reportChatHint =>
      'Les dernières lignes du chat de cette table sont jointes au signalement, pour que l\'admin voie ce qui a été dit.';

  @override
  String get sendReport => 'Envoyer le signalement';

  @override
  String get reportSent => 'Signalement envoyé à l\'admin du serveur.';

  @override
  String get blockedUsers => 'Utilisateurs bloqués';

  @override
  String get noBlockedUsers =>
      'Tu n\'as bloqué personne. Touche une ligne du chat à une table pour bloquer son auteur.';

  @override
  String get unblock => 'Débloquer';

  @override
  String get reports => 'Signalements';

  @override
  String get showResolved => 'Afficher les signalements résolus';

  @override
  String get noReports => 'Aucun signalement.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter a signalé $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'résolu par $name';
  }

  @override
  String get reportNoChat => 'Aucune ligne de chat avec ce signalement.';

  @override
  String get resolve => 'Marquer comme résolu';

  @override
  String get wsMuted => 'L\'hôte t\'a rendu muet dans le chat de cette table.';

  @override
  String get wsRemoved => 'L\'hôte t\'a retiré de cette table.';

  @override
  String get wsIsPlayer =>
      'Les joueurs ne peuvent pas être retirés, seulement les spectateurs.';

  @override
  String get errBusy => 'Le serveur est occupé. Réessaie dans un instant.';

  @override
  String get errBadName => 'Les noms font 1 à 64 caractères.';

  @override
  String get errBuiltIn =>
      'Les dos de carte intégrés ne peuvent pas être supprimés.';

  @override
  String get errTotpEnabled => 'La double authentification est déjà activée.';

  @override
  String get errTotpNotStarted =>
      'Relance la configuration de la double authentification.';

  @override
  String get errTotpNotEnabled =>
      'La double authentification n\'est pas activée.';

  @override
  String get errPasswordChangeRequired => 'Change d\'abord ton mot de passe.';

  @override
  String get errTooManyTables =>
      'Le serveur a trop de tables ouvertes. Réessaie plus tard.';

  @override
  String get errTooManyPasskeys =>
      'Tu as trop de clés d\'accès. Supprimes-en une d\'abord.';

  @override
  String get errTooManyBlocks =>
      'Ta liste de blocage est pleine. Débloque quelqu\'un d\'abord.';

  @override
  String get errTooManyReports =>
      'Tu as envoyé trop de signalements. Réessaie plus tard.';

  @override
  String get errReportSelf => 'Tu ne peux pas te signaler toi-même.';

  @override
  String get errBlockSelf => 'Tu ne peux pas te bloquer toi-même.';

  @override
  String get errBadReport =>
      'Choisis un motif ; la note fait 500 caractères maximum.';

  @override
  String get errAdminOnly => 'Seul un admin peut faire ça.';

  @override
  String get errNotFound => 'Ça n\'existe plus.';

  @override
  String get errUnauthenticated => 'Reconnecte-toi.';

  @override
  String get errBadRequest =>
      'Le serveur n\'a pas compris la requête. Mets l\'appli à jour.';

  @override
  String get errInternal => 'Le serveur a rencontré une erreur. Réessaie.';

  @override
  String get wsNotSeated => 'Tu n\'as pas de place à cette table.';

  @override
  String get wsNotInHand => 'Tu ne participes pas à cette main.';

  @override
  String get wsNoTable => 'Cette table est fermée.';

  @override
  String get wsNotSng => 'Seul un sit and go peut être lancé.';

  @override
  String get wsBadChat => 'Les messages du chat font 1 à 300 caractères.';

  @override
  String get wsBadSeat => 'Cette place n\'existe pas.';

  @override
  String get imagesFileType => 'Images';

  @override
  String get defaultTableName => 'Partie du vendredi';

  @override
  String get language => 'Langue';

  @override
  String get languageDevice => 'Langue de l\'appareil';
}
