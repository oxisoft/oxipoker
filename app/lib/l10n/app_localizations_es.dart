// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Conectarse a un servidor';

  @override
  String get serverHint => 'Dirección del servidor o enlace de invitación';

  @override
  String get serverHelp =>
      'Pega el enlace de invitación que te dio tu anfitrión, o la dirección de tu servidor de póker.';

  @override
  String get connect => 'Conectar';

  @override
  String get changeServer => 'Cambiar de servidor';

  @override
  String serverVersion(String version) {
    return 'Servidor $version';
  }

  @override
  String get signInTitle => 'Iniciar sesión';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get displayName => 'Nombre visible';

  @override
  String get displayNameOptional => 'Nombre visible (opcional)';

  @override
  String get password => 'Contraseña';

  @override
  String get repeatPassword => 'Repite la contraseña';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signInPasskey => 'Iniciar sesión con una llave de acceso';

  @override
  String get totpTitle => 'Código de dos pasos';

  @override
  String get totpHelp =>
      'Escribe el código de 6 dígitos de tu app de autenticación, o uno de tus códigos de recuperación.';

  @override
  String get code => 'Código';

  @override
  String get verify => 'Verificar';

  @override
  String get back => 'Atrás';

  @override
  String get inviteTitle => 'Únete con una invitación';

  @override
  String inviteNote(String note) {
    return 'Nota de tu anfitrión: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Enlace válido hasta el $date';
  }

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get createWithPasskey => 'Crear cuenta con una llave de acceso';

  @override
  String get orPassword => 'o elige una contraseña';

  @override
  String get passwordsDiffer => 'Las contraseñas no coinciden.';

  @override
  String lobbyWelcome(String name) {
    return 'Hola, $name';
  }

  @override
  String get lobbySoon => 'Las mesas llegan en la próxima versión.';

  @override
  String get account => 'Cuenta';

  @override
  String get admin => 'Administración';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get save => 'Guardar';

  @override
  String get saved => 'Guardado';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get remove => 'Quitar';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get profile => 'Perfil';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get passwordChanged =>
      'Contraseña cambiada. Se cerraron tus otras sesiones.';

  @override
  String get mustChangeTitle => 'Elige una nueva contraseña';

  @override
  String get mustChangeHelp =>
      'Tu administrador te dio una contraseña temporal. Elige la tuya para continuar.';

  @override
  String get sessions => 'Sesiones';

  @override
  String get thisDevice => 'este dispositivo';

  @override
  String get revoke => 'Cerrar sesión';

  @override
  String get revokeOthers => 'Cerrar sesión en los demás dispositivos';

  @override
  String lastSeen(String date) {
    return 'última vez el $date';
  }

  @override
  String get twoFactor => 'Verificación en dos pasos';

  @override
  String twoFactorOn(int count) {
    return 'Activada, quedan $count códigos de recuperación';
  }

  @override
  String get twoFactorOff => 'Desactivada';

  @override
  String get enable => 'Activar';

  @override
  String get disable => 'Desactivar';

  @override
  String get totpScan =>
      'Escanea este código con tu app de autenticación y escribe el código de 6 dígitos que muestra.';

  @override
  String totpSecret(String secret) {
    return 'Clave secreta: $secret';
  }

  @override
  String get recoveryTitle => 'Códigos de recuperación';

  @override
  String get recoveryHelp =>
      'Cada código te permite entrar una vez si no tienes el móvil a mano. Solo se muestran ahora: guárdalos en un lugar seguro.';

  @override
  String get passkeys => 'Llaves de acceso';

  @override
  String get addPasskey => 'Añadir una llave de acceso';

  @override
  String get noPasskeys => 'Aún no hay llaves de acceso.';

  @override
  String get synced => 'sincronizada';

  @override
  String get passkeyName => 'Nombre de la llave de acceso';

  @override
  String get passkeyUnsupported =>
      'Las llaves de acceso no están disponibles en este dispositivo.';

  @override
  String get avatar => 'Avatar';

  @override
  String get uploadAvatar => 'Subir imagen';

  @override
  String get dangerZone => 'Eliminar cuenta';

  @override
  String get deleteAccountHelp =>
      'Tu cuenta y todo lo que contiene se eliminan para siempre.';

  @override
  String get deleteAccountConfirm =>
      'Escribe tu contraseña para eliminar tu cuenta.';

  @override
  String get users => 'Usuarios';

  @override
  String get invitations => 'Invitaciones';

  @override
  String get settings => 'Ajustes';

  @override
  String get auditLog => 'Registro de auditoría';

  @override
  String get search => 'Buscar';

  @override
  String get newUser => 'Nuevo usuario';

  @override
  String get makeAdmin => 'Admin';

  @override
  String get disabled => 'Desactivado';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get reset2fa => 'Restablecer dos pasos';

  @override
  String get temporaryPassword => 'Contraseña temporal';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Dásela a $name en privado. Solo se muestra ahora y debe cambiarse al iniciar sesión por primera vez.';
  }

  @override
  String deleteUserConfirm(String name) {
    return '¿Eliminar a $name y todo lo que hay en su cuenta?';
  }

  @override
  String get newInvitation => 'Nueva invitación';

  @override
  String get validHours => 'Válida durante (horas)';

  @override
  String get uses => 'Usos';

  @override
  String get note => 'Nota (opcional)';

  @override
  String get invitationLink => 'Enlace de invitación';

  @override
  String get invitationLinkHelp =>
      'Envía este enlace al jugador. Solo se muestra ahora.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses de $max usados';
  }

  @override
  String get invitationRevoked => 'revocada';

  @override
  String get invitationExpired => 'caducada';

  @override
  String joinedBy(String names) {
    return 'Se unieron: $names';
  }

  @override
  String get tableCreation => 'Quién puede crear mesas';

  @override
  String get everyone => 'Todos los jugadores';

  @override
  String get adminsOnly => 'Solo administradores';

  @override
  String get maxUpload => 'Tamaño máximo de subida (KiB)';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get filterAction => 'Acción (exacta, o prefijo que termine en punto)';

  @override
  String get errNetwork => 'No se puede conectar con el servidor.';

  @override
  String get errNotServer =>
      'No hay ningún servidor de Oxi Poker en esta dirección.';

  @override
  String get errBadAddress => 'Escribe una dirección como poker.example.com.';

  @override
  String get errInvalidCredentials => 'Usuario o contraseña incorrectos.';

  @override
  String get errRateLimited =>
      'Demasiados intentos. Vuelve a intentarlo en un rato.';

  @override
  String get errInvalidCode => 'Ese código no es válido.';

  @override
  String get errChallengeExpired =>
      'El inicio de sesión tardó demasiado. Empieza de nuevo.';

  @override
  String get errInvitationInvalid => 'Este enlace de invitación no es válido.';

  @override
  String get errInvitationExpired => 'Este enlace de invitación ha caducado.';

  @override
  String get errInvitationUsed => 'Este enlace de invitación ya se ha usado.';

  @override
  String get errBadUsername =>
      'El nombre de usuario tiene de 3 a 32 letras, números, puntos, guiones o guiones bajos.';

  @override
  String get errBadDisplayName =>
      'El nombre visible tiene de 1 a 64 caracteres.';

  @override
  String get errBadPassword => 'La contraseña tiene de 10 a 256 caracteres.';

  @override
  String get errUsernameTaken => 'Ese nombre de usuario ya está en uso.';

  @override
  String get errWrongPassword => 'La contraseña es incorrecta.';

  @override
  String get errLastAdmin => 'El servidor necesita al menos un administrador.';

  @override
  String get errSelf => 'Aquí no puedes hacer eso con tu propia cuenta.';

  @override
  String get errTooLarge => 'El archivo es demasiado grande.';

  @override
  String get errBadImage => 'Usa una imagen PNG, JPEG, GIF o WebP.';

  @override
  String get errPasskeyRejected => 'La llave de acceso no fue aceptada.';

  @override
  String get errLastSignInMethod =>
      'Es tu última forma de iniciar sesión. Primero añade una contraseña u otra llave de acceso.';

  @override
  String get errBadInvitation =>
      'Horas de 1 a 720, usos de 1 a 100, nota de hasta 200 caracteres.';

  @override
  String get errBadSettings =>
      'El tamaño de subida debe estar entre 256 KiB y 20 MiB.';

  @override
  String errGeneric(String code) {
    return 'Algo salió mal ($code).';
  }

  @override
  String get handHistory => 'Historial de manos';

  @override
  String get createTable => 'Crear mesa';

  @override
  String get create => 'Crear';

  @override
  String get noTables =>
      'Aún no hay mesas abiertas. Crea una e invita a tus amigos.';

  @override
  String get closeTable => 'Cerrar mesa';

  @override
  String closeTableConfirm(String name) {
    return '¿Cerrar la mesa $name? La mano en curso se cancela y cada stack vuelve a como estaba.';
  }

  @override
  String blinds(int sb, int bb) {
    return 'Ciegas $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'Stack $n';
  }

  @override
  String get connecting => 'Conectando…';

  @override
  String get reconnecting => 'Conexión perdida, reconectando…';

  @override
  String get serverRestarting =>
      'El servidor se está reiniciando. La mano en juego se cancela y sus fichas se devuelven; la mesa vuelve en un momento.';

  @override
  String get tableName => 'Nombre de la mesa';

  @override
  String get seats => 'Asientos';

  @override
  String get smallBlind => 'Ciega pequeña';

  @override
  String get bigBlind => 'Ciega grande';

  @override
  String get startingStack => 'Stack inicial';

  @override
  String get turnTime => 'Tiempo por turno (segundos)';

  @override
  String get allowSpectators => 'Permitir espectadores';

  @override
  String get errTableName => 'El nombre necesita de 1 a 40 caracteres.';

  @override
  String get errBlinds =>
      'Las ciegas deben ser al menos 1, y la ciega pequeña no puede superar la grande.';

  @override
  String get errStack =>
      'El stack inicial debe ser de al menos dos ciegas grandes.';

  @override
  String get errTurnTime => 'El tiempo por turno debe ser de 5 a 300 segundos.';

  @override
  String get wsNotYourTurn => 'No es tu turno.';

  @override
  String get wsSeatTaken => 'Alguien acaba de ocupar ese asiento.';

  @override
  String get wsAlreadySeated => 'Ya tienes un asiento en esta mesa.';

  @override
  String get wsIllegal => 'Esa acción no es posible ahora.';

  @override
  String get wsSpectatorsOff =>
      'Esta mesa no admite espectadores. Siéntate para unirte.';

  @override
  String get table => 'Mesa';

  @override
  String get sitOut => 'Ausentarse';

  @override
  String get comeBack => 'Volver';

  @override
  String get leaveSeat => 'Dejar el asiento';

  @override
  String get chat => 'Chat';

  @override
  String get tableClosed => 'Esta mesa está cerrada.';

  @override
  String get backToLobby => 'Volver al lobby';

  @override
  String get watchingHint =>
      'Estás mirando. Elige un asiento libre para jugar.';

  @override
  String get bustedHint =>
      'Te quedaste sin fichas. Usa Volver en el menú del asiento para recomprar.';

  @override
  String get sittingOutHint =>
      'Estás ausente. Usa Volver en el menú del asiento para jugar la próxima mano.';

  @override
  String get waitingForPlayers => 'Esperando jugadores';

  @override
  String get nextHandSoon => 'La próxima mano empieza en un momento';

  @override
  String waitingFor(String name) {
    return 'Esperando a $name';
  }

  @override
  String potMain(String amount) {
    return 'Bote $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Bote secundario $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name gana $amount';
  }

  @override
  String get sit => 'Sentarse aquí';

  @override
  String get emptySeat => 'Libre';

  @override
  String get sittingOut => 'Ausente';

  @override
  String get folded => 'Retirado';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Subir a $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Apostar $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Igualar $amount';
  }

  @override
  String get presetMin => 'Mín';

  @override
  String get presetHalfPot => '½ bote';

  @override
  String get presetPot => 'Bote';

  @override
  String get presetAllIn => 'All-in';

  @override
  String get fold => 'Retirarse';

  @override
  String get check => 'Pasar';

  @override
  String get bet => 'Apostar';

  @override
  String get chatNotStored =>
      'Lo ven jugadores y espectadores, nunca se guarda.';

  @override
  String get chatHint => 'Mensaje';

  @override
  String get noHands => 'Aún no se han jugado manos.';

  @override
  String potLabel(String amount) {
    return 'bote $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who pone la ciega pequeña $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who pone la ciega grande $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who recibe $cards';
  }

  @override
  String evFold(String who) {
    return '$who se retira';
  }

  @override
  String evCheck(String who) {
    return '$who pasa';
  }

  @override
  String evCall(String who, String amount) {
    return '$who iguala $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who apuesta $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who sube a $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return 'Se devuelven $amount a $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who muestra $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who gana $amount';
  }

  @override
  String get replay => 'Repetición';

  @override
  String get yourCards => 'Tus cartas';

  @override
  String stepOf(int step, int total) {
    return '$step de $total';
  }

  @override
  String get stats => 'Tus estadísticas';

  @override
  String get handsPlayed => 'Manos jugadas';

  @override
  String get handsWon => 'Manos ganadas';

  @override
  String get biggestPot => 'Mayor bote ganado';

  @override
  String get sngGames => 'Partidas sit and go';

  @override
  String get sngWins => 'Victorias en sit and go';

  @override
  String get sngBest => 'Mejor puesto';

  @override
  String get tableKind => 'Partida';

  @override
  String get kindCash => 'Partida cash';

  @override
  String get kindSng => 'Sit and go';

  @override
  String get structure => 'Niveles de ciegas';

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
    return 'Lento, $min min';
  }

  @override
  String get firstBlinds => 'Ciegas del primer nivel';

  @override
  String sngRegistering(int n) {
    return 'Inscripción: $n sentados. El anfitrión inicia la partida, o empieza cuando se ocupan todos los asientos.';
  }

  @override
  String get startGame => 'Empezar la partida';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Nivel $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'siguiente $sb/$bb en $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'siguiente $sb/$bb desde la próxima mano';
  }

  @override
  String get sngLastLevel => 'último nivel';

  @override
  String get standings => 'Clasificación final';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Terminaste en el puesto #$place';
  }

  @override
  String get wsSngStarted => 'El sit and go ya ha empezado.';

  @override
  String get wsTooFewPlayers =>
      'Un sit and go necesita al menos dos jugadores.';

  @override
  String get wsHostOnly =>
      'Solo el anfitrión o un administrador puede hacer eso.';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get themeClassic => 'Clásico';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Reverso de cartas';

  @override
  String get serverDefault => 'Predeterminado del servidor';

  @override
  String get defaultCardBack => 'Reverso predeterminado';

  @override
  String get cardBacks => 'Reversos de cartas';

  @override
  String get errBadTheme => 'Tema desconocido.';

  @override
  String get errBadCardBack => 'Ese reverso no está disponible.';

  @override
  String get errCardBackDefault =>
      'El reverso predeterminado no se puede eliminar.';

  @override
  String get uploadCardBack => 'Subir un reverso';

  @override
  String get cardBackName => 'Nombre del reverso';

  @override
  String get errTooManyCardBacks =>
      'Hay demasiados reversos subidos. Elimina uno primero.';

  @override
  String get chatUserMenuHint =>
      'Toca una línea del chat para bloquear o denunciar a su autor.';

  @override
  String get blockUser => 'Bloquear';

  @override
  String get reportUser => 'Denunciar';

  @override
  String get muteInChat => 'Silenciar en el chat de esta mesa';

  @override
  String get unmuteInChat => 'Quitar silencio en el chat de esta mesa';

  @override
  String get removeSpectator => 'Expulsar de la mesa';

  @override
  String userBlocked(String name) {
    return '$name está bloqueado. Ya no verás sus mensajes.';
  }

  @override
  String reportTitle(String name) {
    return 'Denunciar a $name';
  }

  @override
  String get reasonChat => 'Chat';

  @override
  String get reasonBehaviour => 'Comportamiento';

  @override
  String get reasonOther => 'Otro';

  @override
  String get reportNote => '¿Qué pasó? (opcional)';

  @override
  String get reportChatHint =>
      'Las últimas líneas del chat de esta mesa se envían con la denuncia, para que el administrador vea lo que se dijo.';

  @override
  String get sendReport => 'Enviar denuncia';

  @override
  String get reportSent => 'Denuncia enviada al administrador del servidor.';

  @override
  String get blockedUsers => 'Usuarios bloqueados';

  @override
  String get noBlockedUsers =>
      'No has bloqueado a nadie. Toca una línea del chat en una mesa para bloquear a su autor.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get reports => 'Denuncias';

  @override
  String get showResolved => 'Mostrar denuncias resueltas';

  @override
  String get noReports => 'No hay denuncias.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter denunció a $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'resuelta por $name';
  }

  @override
  String get reportNoChat => 'Esta denuncia no tiene líneas de chat.';

  @override
  String get resolve => 'Marcar como resuelta';

  @override
  String get wsMuted => 'El anfitrión te silenció en el chat de esta mesa.';

  @override
  String get wsRemoved => 'El anfitrión te expulsó de esta mesa.';

  @override
  String get wsIsPlayer =>
      'No se puede expulsar a jugadores; solo a espectadores.';

  @override
  String get errBusy =>
      'El servidor está ocupado. Vuelve a intentarlo en un momento.';

  @override
  String get errBadName => 'Los nombres tienen de 1 a 64 caracteres.';

  @override
  String get errBuiltIn => 'Los reversos incluidos no se pueden eliminar.';

  @override
  String get errTotpEnabled => 'La verificación en dos pasos ya está activada.';

  @override
  String get errTotpNotStarted =>
      'Vuelve a empezar la configuración de dos pasos.';

  @override
  String get errTotpNotEnabled =>
      'La verificación en dos pasos no está activada.';

  @override
  String get errPasswordChangeRequired => 'Primero cambia tu contraseña.';

  @override
  String get errTooManyTables =>
      'El servidor tiene demasiadas mesas abiertas. Inténtalo más tarde.';

  @override
  String get errTooManyPasskeys =>
      'Tienes demasiadas llaves de acceso. Elimina una primero.';

  @override
  String get errTooManyBlocks =>
      'Tu lista de bloqueados está llena. Desbloquea a alguien primero.';

  @override
  String get errTooManyReports =>
      'Has enviado demasiadas denuncias. Inténtalo más tarde.';

  @override
  String get errReportSelf => 'No puedes denunciarte a ti mismo.';

  @override
  String get errBlockSelf => 'No puedes bloquearte a ti mismo.';

  @override
  String get errBadReport =>
      'Elige un motivo; la nota tiene hasta 500 caracteres.';

  @override
  String get errAdminOnly => 'Solo un administrador puede hacer eso.';

  @override
  String get errNotFound => 'Eso ya no existe.';

  @override
  String get errUnauthenticated => 'Vuelve a iniciar sesión.';

  @override
  String get errBadRequest =>
      'El servidor no entendió la solicitud. Actualiza la app.';

  @override
  String get errInternal => 'El servidor tuvo un error. Inténtalo de nuevo.';

  @override
  String get wsNotSeated => 'No tienes asiento en esta mesa.';

  @override
  String get wsNotInHand => 'No estás en esta mano.';

  @override
  String get wsNoTable => 'Esta mesa está cerrada.';

  @override
  String get wsNotSng => 'Solo se puede iniciar un sit and go.';

  @override
  String get wsBadChat => 'Las líneas del chat tienen de 1 a 300 caracteres.';

  @override
  String get wsBadSeat => 'Ese asiento no existe.';

  @override
  String get imagesFileType => 'Imágenes';

  @override
  String get defaultTableName => 'Partida del viernes';

  @override
  String get language => 'Idioma';

  @override
  String get languageDevice => 'Idioma del dispositivo';

  @override
  String get errMediaOff =>
      'La voz y el vídeo no están configurados en este servidor.';

  @override
  String get errNotAtTable => 'Únete primero a la mesa para usar voz y vídeo.';

  @override
  String get callJoin => 'Unirse a voz y vídeo';

  @override
  String get callLeave => 'Salir de la llamada';

  @override
  String get callMicOn => 'Activar micrófono';

  @override
  String get callMicOff => 'Desactivar micrófono';

  @override
  String get callCameraOn => 'Activar cámara';

  @override
  String get callCameraOff => 'Desactivar cámara';

  @override
  String get callSpeaker => 'Altavoz';

  @override
  String get callSwitchCamera => 'Cambiar cámara';

  @override
  String get callConnecting => 'Conectando la llamada…';

  @override
  String get callLost =>
      'La llamada se cortó. La partida sigue; vuelve a unirte cuando quieras.';

  @override
  String get callRemoved => 'Te han sacado de la llamada.';

  @override
  String callInCall(int count) {
    return 'En la llamada: $count';
  }
}
