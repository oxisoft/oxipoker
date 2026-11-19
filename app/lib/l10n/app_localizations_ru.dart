// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Подключение к серверу';

  @override
  String get serverHint => 'Адрес сервера или ссылка-приглашение';

  @override
  String get serverHelp =>
      'Вставь ссылку-приглашение от хоста или адрес своего покерного сервера.';

  @override
  String get connect => 'Подключиться';

  @override
  String get changeServer => 'Сменить сервер';

  @override
  String serverVersion(String version) {
    return 'Сервер $version';
  }

  @override
  String get signInTitle => 'Вход';

  @override
  String get username => 'Имя пользователя';

  @override
  String get displayName => 'Отображаемое имя';

  @override
  String get displayNameOptional => 'Отображаемое имя (необязательно)';

  @override
  String get password => 'Пароль';

  @override
  String get repeatPassword => 'Повтори пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get signInPasskey => 'Войти с ключом доступа';

  @override
  String get totpTitle => 'Код двухфакторной защиты';

  @override
  String get totpHelp =>
      'Введи 6-значный код из приложения-аутентификатора или один из кодов восстановления.';

  @override
  String get code => 'Код';

  @override
  String get verify => 'Проверить';

  @override
  String get back => 'Назад';

  @override
  String get inviteTitle => 'Вход по приглашению';

  @override
  String inviteNote(String note) {
    return 'Заметка от хоста: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Ссылка действует до $date';
  }

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get createWithPasskey => 'Создать аккаунт с ключом доступа';

  @override
  String get orPassword => 'или задай пароль';

  @override
  String get passwordsDiffer => 'Пароли не совпадают.';

  @override
  String lobbyWelcome(String name) {
    return 'Добро пожаловать, $name';
  }

  @override
  String get lobbySoon => 'Столы появятся в следующей версии.';

  @override
  String get account => 'Аккаунт';

  @override
  String get admin => 'Админка';

  @override
  String get signOut => 'Выйти';

  @override
  String get save => 'Сохранить';

  @override
  String get saved => 'Сохранено';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get delete => 'Удалить';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано';

  @override
  String get remove => 'Убрать';

  @override
  String get rename => 'Переименовать';

  @override
  String get profile => 'Профиль';

  @override
  String get changePassword => 'Сменить пароль';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get passwordChanged => 'Пароль изменён. Остальные сеансы завершены.';

  @override
  String get mustChangeTitle => 'Задай новый пароль';

  @override
  String get mustChangeHelp =>
      'Админ выдал тебе временный пароль. Чтобы продолжить, задай свой.';

  @override
  String get sessions => 'Сеансы';

  @override
  String get thisDevice => 'это устройство';

  @override
  String get revoke => 'Завершить';

  @override
  String get revokeOthers => 'Выйти на всех других устройствах';

  @override
  String lastSeen(String date) {
    return 'последняя активность: $date';
  }

  @override
  String get twoFactor => 'Двухфакторный вход';

  @override
  String twoFactorOn(int count) {
    return 'Включён, осталось кодов восстановления: $count';
  }

  @override
  String get twoFactorOff => 'Выключен';

  @override
  String get enable => 'Включить';

  @override
  String get disable => 'Выключить';

  @override
  String get totpScan =>
      'Отсканируй этот код приложением-аутентификатором, затем введи показанный 6-значный код.';

  @override
  String totpSecret(String secret) {
    return 'Секрет: $secret';
  }

  @override
  String get recoveryTitle => 'Коды восстановления';

  @override
  String get recoveryHelp =>
      'Каждый код позволяет войти один раз, если телефона нет под рукой. Они показаны только сейчас: сохрани их в надёжном месте.';

  @override
  String get passkeys => 'Ключи доступа';

  @override
  String get addPasskey => 'Добавить ключ доступа';

  @override
  String get noPasskeys => 'Ключей доступа пока нет.';

  @override
  String get synced => 'синхронизирован';

  @override
  String get passkeyName => 'Название ключа';

  @override
  String get passkeyUnsupported =>
      'Ключи доступа на этом устройстве недоступны.';

  @override
  String get avatar => 'Аватар';

  @override
  String get uploadAvatar => 'Загрузить картинку';

  @override
  String get dangerZone => 'Удаление аккаунта';

  @override
  String get deleteAccountHelp =>
      'Аккаунт и все его данные будут удалены навсегда.';

  @override
  String get deleteAccountConfirm => 'Введи пароль, чтобы удалить аккаунт.';

  @override
  String get users => 'Пользователи';

  @override
  String get invitations => 'Приглашения';

  @override
  String get settings => 'Настройки';

  @override
  String get auditLog => 'Журнал действий';

  @override
  String get search => 'Поиск';

  @override
  String get newUser => 'Новый пользователь';

  @override
  String get makeAdmin => 'Админ';

  @override
  String get disabled => 'Отключён';

  @override
  String get resetPassword => 'Сбросить пароль';

  @override
  String get reset2fa => 'Сбросить двухфакторку';

  @override
  String get temporaryPassword => 'Временный пароль';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Передай его пользователю $name лично. Он показан только сейчас, и при первом входе его нужно сменить.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Удалить $name вместе со всеми данными аккаунта?';
  }

  @override
  String get newInvitation => 'Новое приглашение';

  @override
  String get validHours => 'Срок действия (часы)';

  @override
  String get uses => 'Использований';

  @override
  String get note => 'Заметка (необязательно)';

  @override
  String get invitationLink => 'Ссылка-приглашение';

  @override
  String get invitationLinkHelp =>
      'Отправь эту ссылку игроку. Она показана только сейчас.';

  @override
  String invitationUses(int uses, int max) {
    return 'Использовано: $uses из $max';
  }

  @override
  String get invitationRevoked => 'отозвано';

  @override
  String get invitationExpired => 'истекло';

  @override
  String joinedBy(String names) {
    return 'Присоединились: $names';
  }

  @override
  String get tableCreation => 'Кто может создавать столы';

  @override
  String get everyone => 'Все игроки';

  @override
  String get adminsOnly => 'Только админы';

  @override
  String get maxUpload => 'Макс. размер загрузки (КиБ)';

  @override
  String get loadMore => 'Загрузить ещё';

  @override
  String get filterAction => 'Действие (точно или префикс с точкой на конце)';

  @override
  String get errNetwork => 'Сервер недоступен.';

  @override
  String get errNotServer => 'По этому адресу нет сервера Oxi Poker.';

  @override
  String get errBadAddress => 'Введи адрес вида poker.example.com.';

  @override
  String get errInvalidCredentials => 'Неверное имя пользователя или пароль.';

  @override
  String get errRateLimited => 'Слишком много попыток. Попробуй чуть позже.';

  @override
  String get errInvalidCode => 'Этот код недействителен.';

  @override
  String get errChallengeExpired =>
      'Вход занял слишком много времени. Начни заново.';

  @override
  String get errInvitationInvalid => 'Эта ссылка-приглашение недействительна.';

  @override
  String get errInvitationExpired => 'Срок действия ссылки-приглашения истёк.';

  @override
  String get errInvitationUsed => 'Эта ссылка-приглашение уже использована.';

  @override
  String get errBadUsername =>
      'Имя пользователя: от 3 до 32 букв, цифр, точек, дефисов или подчёркиваний.';

  @override
  String get errBadDisplayName => 'Отображаемое имя: от 1 до 64 символов.';

  @override
  String get errBadPassword => 'Пароль: от 10 до 256 символов.';

  @override
  String get errUsernameTaken => 'Это имя пользователя уже занято.';

  @override
  String get errWrongPassword => 'Неверный пароль.';

  @override
  String get errLastAdmin => 'На сервере должен остаться хотя бы один админ.';

  @override
  String get errSelf => 'Здесь это нельзя сделать со своим аккаунтом.';

  @override
  String get errTooLarge => 'Файл слишком большой.';

  @override
  String get errBadImage => 'Нужна картинка в формате PNG, JPEG, GIF или WebP.';

  @override
  String get errPasskeyRejected => 'Ключ доступа не принят.';

  @override
  String get errLastSignInMethod =>
      'Это твой последний способ входа. Сначала добавь пароль или другой ключ доступа.';

  @override
  String get errBadInvitation =>
      'Часы: от 1 до 720, использований: от 1 до 100, заметка: до 200 символов.';

  @override
  String get errBadSettings =>
      'Размер загрузки должен быть от 256 КиБ до 20 МиБ.';

  @override
  String errGeneric(String code) {
    return 'Что-то пошло не так ($code).';
  }

  @override
  String get handHistory => 'История раздач';

  @override
  String get createTable => 'Создать стол';

  @override
  String get create => 'Создать';

  @override
  String get noTables =>
      'Открытых столов пока нет. Создай свой и позови друзей.';

  @override
  String get closeTable => 'Закрыть стол';

  @override
  String closeTableConfirm(String name) {
    return 'Закрыть стол $name? Текущая раздача отменится, и все стеки вернутся к прежним значениям.';
  }

  @override
  String blinds(int sb, int bb) {
    return 'Блайнды $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'Стек $n';
  }

  @override
  String get connecting => 'Подключение…';

  @override
  String get reconnecting => 'Связь потеряна, переподключаемся…';

  @override
  String get serverRestarting =>
      'Сервер перезапускается. Текущая раздача отменяется, фишки возвращаются; стол вернётся через мгновение.';

  @override
  String get tableName => 'Название стола';

  @override
  String get seats => 'Мест';

  @override
  String get smallBlind => 'Малый блайнд';

  @override
  String get bigBlind => 'Большой блайнд';

  @override
  String get startingStack => 'Стартовый стек';

  @override
  String get turnTime => 'Время на ход (секунды)';

  @override
  String get allowSpectators => 'Разрешить зрителей';

  @override
  String get errTableName => 'Название: от 1 до 40 символов.';

  @override
  String get errBlinds =>
      'Блайнды должны быть не меньше 1, а малый блайнд не больше большого.';

  @override
  String get errStack =>
      'Стартовый стек должен быть не меньше двух больших блайндов.';

  @override
  String get errTurnTime => 'Время на ход: от 5 до 300 секунд.';

  @override
  String get wsNotYourTurn => 'Сейчас не твой ход.';

  @override
  String get wsSeatTaken => 'Это место только что заняли.';

  @override
  String get wsAlreadySeated => 'У тебя уже есть место за этим столом.';

  @override
  String get wsIllegal => 'Сейчас это действие невозможно.';

  @override
  String get wsSpectatorsOff =>
      'За этим столом нет зрителей. Займи место, чтобы присоединиться.';

  @override
  String get table => 'Стол';

  @override
  String get sitOut => 'Пропускать раздачи';

  @override
  String get comeBack => 'Вернуться';

  @override
  String get leaveSeat => 'Встать из-за стола';

  @override
  String get chat => 'Чат';

  @override
  String get tableClosed => 'Этот стол закрыт.';

  @override
  String get backToLobby => 'В лобби';

  @override
  String get watchingHint =>
      'Ты зритель. Выбери свободное место, чтобы играть.';

  @override
  String get bustedHint =>
      'Фишки закончились. Нажми «Вернуться» в меню места, чтобы закупиться снова.';

  @override
  String get sittingOutHint =>
      'Ты пропускаешь раздачи. Нажми «Вернуться» в меню места, чтобы сыграть следующую.';

  @override
  String get waitingForPlayers => 'Ждём игроков';

  @override
  String get nextHandSoon => 'Следующая раздача вот-вот начнётся';

  @override
  String waitingFor(String name) {
    return 'Ждём: $name';
  }

  @override
  String potMain(String amount) {
    return 'Банк $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Побочный банк $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name выигрывает $amount';
  }

  @override
  String get sit => 'Сесть сюда';

  @override
  String get emptySeat => 'Свободно';

  @override
  String get sittingOut => 'Пропускает';

  @override
  String get folded => 'Фолд';

  @override
  String get allIn => 'Олл-ин';

  @override
  String allInTo(String amount) {
    return 'Олл-ин $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Рейз до $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Бет $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Колл $amount';
  }

  @override
  String get presetMin => 'Мин.';

  @override
  String get presetHalfPot => '½ банка';

  @override
  String get presetPot => 'Банк';

  @override
  String get presetAllIn => 'Олл-ин';

  @override
  String get fold => 'Фолд';

  @override
  String get check => 'Чек';

  @override
  String get bet => 'Бет';

  @override
  String get chatNotStored => 'Видят игроки и зрители, нигде не сохраняется.';

  @override
  String get chatHint => 'Сообщение';

  @override
  String get noHands => 'Раздач пока не было.';

  @override
  String potLabel(String amount) {
    return 'банк $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who ставит малый блайнд $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who ставит большой блайнд $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who получает $cards';
  }

  @override
  String evFold(String who) {
    return '$who: фолд';
  }

  @override
  String evCheck(String who) {
    return '$who: чек';
  }

  @override
  String evCall(String who, String amount) {
    return '$who: колл $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who: бет $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who: рейз до $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount возвращено игроку $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who показывает $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who выигрывает $amount';
  }

  @override
  String get replay => 'Повтор';

  @override
  String get yourCards => 'Твои карты';

  @override
  String stepOf(int step, int total) {
    return '$step из $total';
  }

  @override
  String get stats => 'Твоя статистика';

  @override
  String get handsPlayed => 'Сыграно раздач';

  @override
  String get handsWon => 'Выиграно раздач';

  @override
  String get biggestPot => 'Самый крупный выигранный банк';

  @override
  String get sngGames => 'Сыграно сит-энд-гоу';

  @override
  String get sngWins => 'Победы в сит-энд-гоу';

  @override
  String get sngBest => 'Лучшее место';

  @override
  String get tableKind => 'Игра';

  @override
  String get kindCash => 'Кэш-игра';

  @override
  String get kindSng => 'Сит-энд-гоу';

  @override
  String get structure => 'Уровни блайндов';

  @override
  String structureTurbo(int min) {
    return 'Турбо, $min мин';
  }

  @override
  String structureRegular(int min) {
    return 'Обычные, $min мин';
  }

  @override
  String structureSlow(int min) {
    return 'Медленные, $min мин';
  }

  @override
  String get firstBlinds => 'Блайнды первого уровня';

  @override
  String sngRegistering(int n) {
    return 'Регистрация, игроков за столом: $n. Хост запускает игру, или она начнётся, когда все места займут.';
  }

  @override
  String get startGame => 'Начать игру';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Уровень $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'далее $sb/$bb через $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'далее $sb/$bb со следующей раздачи';
  }

  @override
  String get sngLastLevel => 'последний уровень';

  @override
  String get standings => 'Итоговые места';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Твоё место: #$place';
  }

  @override
  String get wsSngStarted => 'Сит-энд-гоу уже начался.';

  @override
  String get wsTooFewPlayers => 'Для сит-энд-гоу нужно минимум два игрока.';

  @override
  String get wsHostOnly => 'Это может сделать только хост или админ.';

  @override
  String get appearance => 'Оформление';

  @override
  String get theme => 'Тема';

  @override
  String get themeClassic => 'Классика';

  @override
  String get themeCyberpunk => 'Киберпанк';

  @override
  String get cardBack => 'Рубашка карт';

  @override
  String get serverDefault => 'Как на сервере';

  @override
  String get defaultCardBack => 'Рубашка по умолчанию';

  @override
  String get cardBacks => 'Рубашки карт';

  @override
  String get errBadTheme => 'Неизвестная тема.';

  @override
  String get errBadCardBack => 'Эта рубашка недоступна.';

  @override
  String get errCardBackDefault => 'Рубашку по умолчанию удалить нельзя.';

  @override
  String get uploadCardBack => 'Загрузить рубашку';

  @override
  String get cardBackName => 'Название рубашки';

  @override
  String get errTooManyCardBacks =>
      'Загружено слишком много рубашек. Сначала удали одну.';

  @override
  String get chatUserMenuHint =>
      'Нажми на сообщение в чате, чтобы заблокировать автора или пожаловаться на него.';

  @override
  String get blockUser => 'Заблокировать';

  @override
  String get reportUser => 'Пожаловаться';

  @override
  String get muteInChat => 'Заглушить в чате этого стола';

  @override
  String get unmuteInChat => 'Включить звук в чате этого стола';

  @override
  String get removeSpectator => 'Убрать со стола';

  @override
  String userBlocked(String name) {
    return 'Пользователь $name заблокирован. Его сообщения в чате больше не видны.';
  }

  @override
  String reportTitle(String name) {
    return 'Жалоба на $name';
  }

  @override
  String get reasonChat => 'Чат';

  @override
  String get reasonBehaviour => 'Поведение';

  @override
  String get reasonOther => 'Другое';

  @override
  String get reportNote => 'Что случилось? (необязательно)';

  @override
  String get reportChatHint =>
      'К жалобе прикладываются последние сообщения чата этого стола, чтобы админ видел, что было сказано.';

  @override
  String get sendReport => 'Отправить жалобу';

  @override
  String get reportSent => 'Жалоба отправлена админу сервера.';

  @override
  String get blockedUsers => 'Заблокированные';

  @override
  String get noBlockedUsers =>
      'Ты никого не заблокировал. Нажми на сообщение в чате за столом, чтобы заблокировать автора.';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get reports => 'Жалобы';

  @override
  String get showResolved => 'Показать рассмотренные жалобы';

  @override
  String get noReports => 'Жалоб нет.';

  @override
  String reportLine(String reporter, String reported) {
    return 'Жалоба от $reporter на $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'рассмотрено: $name';
  }

  @override
  String get reportNoChat => 'К этой жалобе не приложены сообщения чата.';

  @override
  String get resolve => 'Отметить как рассмотренную';

  @override
  String get wsMuted => 'Хост заглушил тебя в чате этого стола.';

  @override
  String get wsRemoved => 'Хост убрал тебя с этого стола.';

  @override
  String get wsIsPlayer => 'Убрать можно только зрителей, не игроков.';

  @override
  String get errBusy => 'Сервер занят. Попробуй через минутку.';

  @override
  String get errBadName => 'Имя: от 1 до 64 символов.';

  @override
  String get errBuiltIn => 'Встроенные рубашки удалить нельзя.';

  @override
  String get errTotpEnabled => 'Двухфакторный вход уже включён.';

  @override
  String get errTotpNotStarted =>
      'Начни настройку двухфакторного входа заново.';

  @override
  String get errTotpNotEnabled => 'Двухфакторный вход не включён.';

  @override
  String get errPasswordChangeRequired => 'Сначала смени пароль.';

  @override
  String get errTooManyTables =>
      'На сервере слишком много открытых столов. Попробуй позже.';

  @override
  String get errTooManyPasskeys =>
      'У тебя слишком много ключей доступа. Сначала удали один.';

  @override
  String get errTooManyBlocks =>
      'Список блокировки заполнен. Сначала разблокируй кого-нибудь.';

  @override
  String get errTooManyReports =>
      'Ты отправил слишком много жалоб. Попробуй позже.';

  @override
  String get errReportSelf => 'Нельзя пожаловаться на самого себя.';

  @override
  String get errBlockSelf => 'Нельзя заблокировать самого себя.';

  @override
  String get errBadReport => 'Выбери причину; заметка: до 500 символов.';

  @override
  String get errAdminOnly => 'Это может сделать только админ.';

  @override
  String get errNotFound => 'Этого больше не существует.';

  @override
  String get errUnauthenticated => 'Войди снова.';

  @override
  String get errBadRequest => 'Сервер не понял запрос. Обнови приложение.';

  @override
  String get errInternal => 'На сервере произошла ошибка. Попробуй ещё раз.';

  @override
  String get wsNotSeated => 'У тебя нет места за этим столом.';

  @override
  String get wsNotInHand => 'Ты не участвуешь в этой раздаче.';

  @override
  String get wsNoTable => 'Этот стол закрыт.';

  @override
  String get wsNotSng => 'Запустить можно только сит-энд-гоу.';

  @override
  String get wsBadChat => 'Сообщение в чате: от 1 до 300 символов.';

  @override
  String get wsBadSeat => 'Такого места нет.';

  @override
  String get imagesFileType => 'Изображения';

  @override
  String get defaultTableName => 'Пятничная игра';

  @override
  String get language => 'Язык';

  @override
  String get languageDevice => 'Язык устройства';
}
