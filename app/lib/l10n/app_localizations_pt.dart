// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Conectar a um servidor';

  @override
  String get serverHint => 'Endereço do servidor ou link de convite';

  @override
  String get serverHelp =>
      'Cole o link de convite que você recebeu do anfitrião ou o endereço do seu servidor de poker.';

  @override
  String get connect => 'Conectar';

  @override
  String get changeServer => 'Trocar de servidor';

  @override
  String serverVersion(String version) {
    return 'Servidor $version';
  }

  @override
  String get signInTitle => 'Entrar';

  @override
  String get username => 'Nome de usuário';

  @override
  String get displayName => 'Nome de exibição';

  @override
  String get displayNameOptional => 'Nome de exibição (opcional)';

  @override
  String get password => 'Senha';

  @override
  String get repeatPassword => 'Repita a senha';

  @override
  String get signIn => 'Entrar';

  @override
  String get signInPasskey => 'Entrar com uma chave de acesso';

  @override
  String get totpTitle => 'Código de dois fatores';

  @override
  String get totpHelp =>
      'Digite o código de 6 dígitos do seu app autenticador ou um dos seus códigos de recuperação.';

  @override
  String get code => 'Código';

  @override
  String get verify => 'Verificar';

  @override
  String get back => 'Voltar';

  @override
  String get inviteTitle => 'Entrar com um convite';

  @override
  String inviteNote(String note) {
    return 'Recado do anfitrião: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Link válido até $date';
  }

  @override
  String get createAccount => 'Criar conta';

  @override
  String get createWithPasskey => 'Criar conta com uma chave de acesso';

  @override
  String get orPassword => 'ou escolha uma senha';

  @override
  String get passwordsDiffer => 'As senhas não coincidem.';

  @override
  String lobbyWelcome(String name) {
    return 'Bem-vindo, $name';
  }

  @override
  String get lobbySoon => 'As mesas abrem na próxima versão.';

  @override
  String get account => 'Conta';

  @override
  String get admin => 'Administração';

  @override
  String get signOut => 'Sair';

  @override
  String get save => 'Salvar';

  @override
  String get saved => 'Salvo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get delete => 'Excluir';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get remove => 'Remover';

  @override
  String get rename => 'Renomear';

  @override
  String get profile => 'Perfil';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get currentPassword => 'Senha atual';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get passwordChanged =>
      'Senha alterada. Suas outras sessões foram encerradas.';

  @override
  String get mustChangeTitle => 'Escolha uma nova senha';

  @override
  String get mustChangeHelp =>
      'O admin deu a você uma senha temporária. Escolha a sua para continuar.';

  @override
  String get sessions => 'Sessões';

  @override
  String get thisDevice => 'este dispositivo';

  @override
  String get revoke => 'Encerrar';

  @override
  String get revokeOthers => 'Sair de todos os outros lugares';

  @override
  String lastSeen(String date) {
    return 'visto por último em $date';
  }

  @override
  String get twoFactor => 'Login em dois fatores';

  @override
  String twoFactorOn(int count) {
    return 'Ativado, $count códigos de recuperação restantes';
  }

  @override
  String get twoFactorOff => 'Desativado';

  @override
  String get enable => 'Ativar';

  @override
  String get disable => 'Desativar';

  @override
  String get totpScan =>
      'Escaneie este código com seu app autenticador e digite o código de 6 dígitos que ele mostrar.';

  @override
  String totpSecret(String secret) {
    return 'Chave secreta: $secret';
  }

  @override
  String get recoveryTitle => 'Códigos de recuperação';

  @override
  String get recoveryHelp =>
      'Cada código faz o seu login uma vez quando o celular não estiver por perto. Eles só aparecem agora: guarde-os em um lugar seguro.';

  @override
  String get passkeys => 'Chaves de acesso';

  @override
  String get addPasskey => 'Adicionar chave de acesso';

  @override
  String get noPasskeys => 'Nenhuma chave de acesso ainda.';

  @override
  String get synced => 'sincronizada';

  @override
  String get passkeyName => 'Nome da chave de acesso';

  @override
  String get passkeyUnsupported =>
      'Chaves de acesso não estão disponíveis neste dispositivo.';

  @override
  String get avatar => 'Foto de perfil';

  @override
  String get uploadAvatar => 'Enviar foto';

  @override
  String get dangerZone => 'Excluir conta';

  @override
  String get deleteAccountHelp =>
      'Sua conta e tudo o que há nela serão excluídos para sempre.';

  @override
  String get deleteAccountConfirm => 'Digite sua senha para excluir sua conta.';

  @override
  String get users => 'Usuários';

  @override
  String get invitations => 'Convites';

  @override
  String get settings => 'Configurações';

  @override
  String get auditLog => 'Registro de auditoria';

  @override
  String get search => 'Buscar';

  @override
  String get newUser => 'Novo usuário';

  @override
  String get makeAdmin => 'Administrador';

  @override
  String get disabled => 'Desativado';

  @override
  String get resetPassword => 'Redefinir senha';

  @override
  String get reset2fa => 'Redefinir dois fatores';

  @override
  String get temporaryPassword => 'Senha temporária';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Passe para $name em particular. Ela só aparece agora e deve ser trocada no primeiro login.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Excluir $name e tudo o que há na conta?';
  }

  @override
  String get newInvitation => 'Novo convite';

  @override
  String get validHours => 'Validade (horas)';

  @override
  String get uses => 'Usos';

  @override
  String get note => 'Recado (opcional)';

  @override
  String get invitationLink => 'Link de convite';

  @override
  String get invitationLinkHelp =>
      'Envie este link para o jogador. Ele só aparece agora.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses de $max usados';
  }

  @override
  String get invitationRevoked => 'revogado';

  @override
  String get invitationExpired => 'expirado';

  @override
  String joinedBy(String names) {
    return 'Entraram: $names';
  }

  @override
  String get tableCreation => 'Quem pode criar mesas';

  @override
  String get everyone => 'Todos os jogadores';

  @override
  String get adminsOnly => 'Só administradores';

  @override
  String get maxUpload => 'Tamanho máximo de envio (KiB)';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get filterAction => 'Ação (exata, ou prefixo terminado em ponto)';

  @override
  String get errNetwork => 'Não foi possível acessar o servidor.';

  @override
  String get errNotServer =>
      'Nenhum servidor Oxi Poker responde neste endereço.';

  @override
  String get errBadAddress => 'Digite um endereço como poker.example.com.';

  @override
  String get errInvalidCredentials => 'Usuário ou senha incorretos.';

  @override
  String get errRateLimited =>
      'Tentativas demais. Tente de novo daqui a pouco.';

  @override
  String get errInvalidCode => 'Esse código não é válido.';

  @override
  String get errChallengeExpired => 'O login demorou demais. Comece de novo.';

  @override
  String get errInvitationInvalid => 'Este link de convite não é válido.';

  @override
  String get errInvitationExpired => 'Este link de convite expirou.';

  @override
  String get errInvitationUsed => 'Este link de convite já foi usado.';

  @override
  String get errBadUsername =>
      'Nomes de usuário têm de 3 a 32 letras, números, pontos, hifens ou sublinhados.';

  @override
  String get errBadDisplayName => 'Nomes de exibição têm de 1 a 64 caracteres.';

  @override
  String get errBadPassword => 'Senhas têm de 10 a 256 caracteres.';

  @override
  String get errUsernameTaken => 'Esse nome de usuário já está em uso.';

  @override
  String get errWrongPassword => 'A senha está incorreta.';

  @override
  String get errLastAdmin =>
      'O servidor precisa de pelo menos um administrador.';

  @override
  String get errSelf =>
      'Você não pode fazer isso com a sua própria conta aqui.';

  @override
  String get errTooLarge => 'O arquivo é grande demais.';

  @override
  String get errBadImage => 'Use uma imagem PNG, JPEG, GIF ou WebP.';

  @override
  String get errPasskeyRejected => 'A chave de acesso não foi aceita.';

  @override
  String get errLastSignInMethod =>
      'Esta é sua última forma de entrar. Adicione uma senha ou outra chave de acesso antes.';

  @override
  String get errBadInvitation =>
      'Horas de 1 a 720, usos de 1 a 100, recado de até 200 caracteres.';

  @override
  String get errBadSettings =>
      'O tamanho de envio deve ficar entre 256 KiB e 20 MiB.';

  @override
  String errGeneric(String code) {
    return 'Algo deu errado ($code).';
  }

  @override
  String get handHistory => 'Histórico de mãos';

  @override
  String get createTable => 'Criar mesa';

  @override
  String get create => 'Criar';

  @override
  String get noTables =>
      'Nenhuma mesa aberta ainda. Crie uma e chame seus amigos.';

  @override
  String get closeTable => 'Fechar mesa';

  @override
  String closeTableConfirm(String name) {
    return 'Fechar a mesa $name? Uma mão em andamento é cancelada e cada stack volta ao que era.';
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
  String get connecting => 'Conectando…';

  @override
  String get reconnecting => 'Conexão perdida, reconectando…';

  @override
  String get serverRestarting =>
      'O servidor está reiniciando. A mão em jogo é cancelada e as fichas voltam; a mesa retorna em instantes.';

  @override
  String get tableName => 'Nome da mesa';

  @override
  String get seats => 'Lugares';

  @override
  String get smallBlind => 'Small blind';

  @override
  String get bigBlind => 'Big blind';

  @override
  String get startingStack => 'Stack inicial';

  @override
  String get turnTime => 'Tempo por jogada (segundos)';

  @override
  String get allowSpectators => 'Permitir espectadores';

  @override
  String get errTableName => 'O nome precisa ter de 1 a 40 caracteres.';

  @override
  String get errBlinds =>
      'Os blinds devem ser no mínimo 1, e o small blind não pode passar do big blind.';

  @override
  String get errStack =>
      'O stack inicial deve ser de pelo menos dois big blinds.';

  @override
  String get errTurnTime => 'O tempo por jogada deve ser de 5 a 300 segundos.';

  @override
  String get wsNotYourTurn => 'Não é a sua vez.';

  @override
  String get wsSeatTaken => 'Esse lugar acabou de ser ocupado.';

  @override
  String get wsAlreadySeated => 'Você já tem um lugar nesta mesa.';

  @override
  String get wsIllegal => 'Essa ação não é possível agora.';

  @override
  String get wsSpectatorsOff =>
      'Esta mesa não aceita espectadores. Sente-se para participar.';

  @override
  String get table => 'Mesa';

  @override
  String get sitOut => 'Ficar fora';

  @override
  String get comeBack => 'Voltar ao jogo';

  @override
  String get leaveSeat => 'Sair do lugar';

  @override
  String get chat => 'Chat';

  @override
  String get tableClosed => 'Esta mesa está fechada.';

  @override
  String get backToLobby => 'Voltar ao lobby';

  @override
  String get watchingHint =>
      'Você está assistindo. Escolha um lugar vazio para jogar.';

  @override
  String get bustedHint =>
      'Sem fichas. Use Voltar ao jogo no menu do lugar para fazer um novo buy-in.';

  @override
  String get sittingOutHint =>
      'Você está fora da mesa. Use Voltar ao jogo no menu do lugar para jogar a próxima mão.';

  @override
  String get waitingForPlayers => 'Aguardando jogadores';

  @override
  String get nextHandSoon => 'A próxima mão começa em instantes';

  @override
  String waitingFor(String name) {
    return 'Aguardando $name';
  }

  @override
  String potMain(String amount) {
    return 'Pote $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Pote paralelo $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name ganha $amount';
  }

  @override
  String get sit => 'Sentar aqui';

  @override
  String get emptySeat => 'Vazio';

  @override
  String get sittingOut => 'Fora';

  @override
  String get folded => 'Desistiu';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Aumentar para $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Apostar $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Pagar $amount';
  }

  @override
  String get presetMin => 'Mín';

  @override
  String get presetHalfPot => '½ pote';

  @override
  String get presetPot => 'Pote';

  @override
  String get presetAllIn => 'All-in';

  @override
  String get fold => 'Desistir';

  @override
  String get check => 'Passar';

  @override
  String get bet => 'Apostar';

  @override
  String get chatNotStored =>
      'Visto por jogadores e espectadores, nunca é salvo.';

  @override
  String get chatHint => 'Mensagem';

  @override
  String get noHands => 'Nenhuma mão jogada ainda.';

  @override
  String potLabel(String amount) {
    return 'pote $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who paga o small blind $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who paga o big blind $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who recebe $cards';
  }

  @override
  String evFold(String who) {
    return '$who desiste';
  }

  @override
  String evCheck(String who) {
    return '$who passa';
  }

  @override
  String evCall(String who, String amount) {
    return '$who paga $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who aposta $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who aumenta para $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount devolvido a $who';
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
    return '$who ganha $amount';
  }

  @override
  String get replay => 'Rever';

  @override
  String get yourCards => 'Suas cartas';

  @override
  String stepOf(int step, int total) {
    return '$step de $total';
  }

  @override
  String get stats => 'Suas estatísticas';

  @override
  String get handsPlayed => 'Mãos jogadas';

  @override
  String get handsWon => 'Mãos ganhas';

  @override
  String get biggestPot => 'Maior pote ganho';

  @override
  String get sngGames => 'Partidas de sit and go';

  @override
  String get sngWins => 'Vitórias em sit and go';

  @override
  String get sngBest => 'Melhor colocação';

  @override
  String get tableKind => 'Modalidade';

  @override
  String get kindCash => 'Cash game';

  @override
  String get kindSng => 'Sit and go';

  @override
  String get structure => 'Níveis de blinds';

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
  String get firstBlinds => 'Blinds do primeiro nível';

  @override
  String sngRegistering(int n) {
    return 'Inscrições: $n sentados. O anfitrião inicia a partida, ou ela começa quando todos os lugares forem ocupados.';
  }

  @override
  String get startGame => 'Iniciar a partida';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Nível $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'próximo $sb/$bb em $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'próximo $sb/$bb a partir da próxima mão';
  }

  @override
  String get sngLastLevel => 'último nível';

  @override
  String get standings => 'Classificação final';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Você terminou em $placeº';
  }

  @override
  String get wsSngStarted => 'O sit and go já começou.';

  @override
  String get wsTooFewPlayers =>
      'Um sit and go precisa de pelo menos dois jogadores.';

  @override
  String get wsHostOnly =>
      'Só o anfitrião ou um administrador pode fazer isso.';

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get themeClassic => 'Clássico';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Verso das cartas';

  @override
  String get serverDefault => 'Padrão do servidor';

  @override
  String get defaultCardBack => 'Verso padrão das cartas';

  @override
  String get cardBacks => 'Versos das cartas';

  @override
  String get errBadTheme => 'Tema desconhecido.';

  @override
  String get errBadCardBack => 'Esse verso de carta não está disponível.';

  @override
  String get errCardBackDefault =>
      'O verso padrão das cartas não pode ser excluído.';

  @override
  String get uploadCardBack => 'Enviar um verso de carta';

  @override
  String get cardBackName => 'Nome do verso de carta';

  @override
  String get errTooManyCardBacks =>
      'Há versos de carta enviados demais. Exclua um antes.';

  @override
  String get chatUserMenuHint =>
      'Toque em uma linha do chat para bloquear ou denunciar o autor.';

  @override
  String get blockUser => 'Bloquear';

  @override
  String get reportUser => 'Denunciar';

  @override
  String get muteInChat => 'Silenciar no chat desta mesa';

  @override
  String get unmuteInChat => 'Reativar no chat desta mesa';

  @override
  String get removeSpectator => 'Remover da mesa';

  @override
  String userBlocked(String name) {
    return '$name foi bloqueado. Você não vê mais as mensagens dele no chat.';
  }

  @override
  String reportTitle(String name) {
    return 'Denunciar $name';
  }

  @override
  String get reasonChat => 'Chat';

  @override
  String get reasonBehaviour => 'Comportamento';

  @override
  String get reasonOther => 'Outro';

  @override
  String get reportNote => 'O que aconteceu? (opcional)';

  @override
  String get reportChatHint =>
      'As últimas linhas do chat desta mesa vão junto com a denúncia, para o admin ver o que foi dito.';

  @override
  String get sendReport => 'Enviar denúncia';

  @override
  String get reportSent => 'Denúncia enviada ao admin do servidor.';

  @override
  String get blockedUsers => 'Usuários bloqueados';

  @override
  String get noBlockedUsers =>
      'Você não bloqueou ninguém. Toque em uma linha do chat numa mesa para bloquear o autor.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get reports => 'Denúncias';

  @override
  String get showResolved => 'Mostrar denúncias resolvidas';

  @override
  String get noReports => 'Nenhuma denúncia.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter denunciou $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'resolvida por $name';
  }

  @override
  String get reportNoChat => 'Nenhuma linha de chat nesta denúncia.';

  @override
  String get resolve => 'Marcar como resolvida';

  @override
  String get wsMuted => 'O anfitrião silenciou você no chat desta mesa.';

  @override
  String get wsRemoved => 'O anfitrião removeu você desta mesa.';

  @override
  String get wsIsPlayer =>
      'Jogadores não podem ser removidos; só espectadores.';

  @override
  String get errBusy => 'O servidor está ocupado. Tente de novo em instantes.';

  @override
  String get errBadName => 'Nomes têm de 1 a 64 caracteres.';

  @override
  String get errBuiltIn => 'Versos de carta embutidos não podem ser excluídos.';

  @override
  String get errTotpEnabled => 'O login em dois fatores já está ativado.';

  @override
  String get errTotpNotStarted =>
      'Comece a configuração de dois fatores de novo.';

  @override
  String get errTotpNotEnabled => 'O login em dois fatores não está ativado.';

  @override
  String get errPasswordChangeRequired => 'Altere sua senha primeiro.';

  @override
  String get errTooManyTables =>
      'O servidor tem mesas abertas demais. Tente de novo mais tarde.';

  @override
  String get errTooManyPasskeys =>
      'Você tem chaves de acesso demais. Exclua uma antes.';

  @override
  String get errTooManyBlocks =>
      'Sua lista de bloqueio está cheia. Desbloqueie alguém antes.';

  @override
  String get errTooManyReports =>
      'Você enviou denúncias demais. Tente de novo mais tarde.';

  @override
  String get errReportSelf => 'Você não pode denunciar a si mesmo.';

  @override
  String get errBlockSelf => 'Você não pode bloquear a si mesmo.';

  @override
  String get errBadReport =>
      'Escolha um motivo; o recado tem até 500 caracteres.';

  @override
  String get errAdminOnly => 'Só um administrador pode fazer isso.';

  @override
  String get errNotFound => 'Isso não existe mais.';

  @override
  String get errUnauthenticated => 'Entre de novo.';

  @override
  String get errBadRequest =>
      'O servidor não entendeu a solicitação. Atualize o app.';

  @override
  String get errInternal => 'O servidor teve um erro. Tente de novo.';

  @override
  String get wsNotSeated => 'Você não tem lugar nesta mesa.';

  @override
  String get wsNotInHand => 'Você não está nesta mão.';

  @override
  String get wsNoTable => 'Esta mesa está fechada.';

  @override
  String get wsNotSng => 'Só um sit and go pode ser iniciado.';

  @override
  String get wsBadChat => 'Linhas de chat têm de 1 a 300 caracteres.';

  @override
  String get wsBadSeat => 'Esse lugar não existe.';

  @override
  String get imagesFileType => 'Imagens';

  @override
  String get defaultTableName => 'Jogo de sexta';

  @override
  String get language => 'Idioma';

  @override
  String get languageDevice => 'Idioma do dispositivo';

  @override
  String get errMediaOff =>
      'Voz e vídeo não estão configurados neste servidor.';

  @override
  String get errNotAtTable => 'Entre na mesa primeiro para usar voz e vídeo.';

  @override
  String get callJoin => 'Entrar na voz e vídeo';

  @override
  String get callLeave => 'Sair da chamada';

  @override
  String get callMicOn => 'Ligar microfone';

  @override
  String get callMicOff => 'Desligar microfone';

  @override
  String get callCameraOn => 'Ligar câmera';

  @override
  String get callCameraOff => 'Desligar câmera';

  @override
  String get callSpeaker => 'Alto-falante';

  @override
  String get callSwitchCamera => 'Trocar câmera';

  @override
  String get callConnecting => 'Conectando a chamada…';

  @override
  String get callLost =>
      'A chamada caiu. O jogo continua; entre de novo quando quiser.';

  @override
  String get callRemoved => 'Você foi removido da chamada.';

  @override
  String callInCall(int count) {
    return 'Na chamada: $count';
  }
}
