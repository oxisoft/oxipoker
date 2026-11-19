// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Підключення до сервера';

  @override
  String get serverHint => 'Адреса сервера або посилання-запрошення';

  @override
  String get serverHelp =>
      'Встав посилання-запрошення від організатора або адресу свого покер-сервера.';

  @override
  String get connect => 'Підключитися';

  @override
  String get changeServer => 'Змінити сервер';

  @override
  String serverVersion(String version) {
    return 'Сервер $version';
  }

  @override
  String get signInTitle => 'Вхід';

  @override
  String get username => 'Ім\'я користувача';

  @override
  String get displayName => 'Відображуване ім\'я';

  @override
  String get displayNameOptional => 'Відображуване ім\'я (необов\'язково)';

  @override
  String get password => 'Пароль';

  @override
  String get repeatPassword => 'Повтори пароль';

  @override
  String get signIn => 'Увійти';

  @override
  String get signInPasskey => 'Увійти з ключем доступу';

  @override
  String get totpTitle => 'Код двофакторної перевірки';

  @override
  String get totpHelp =>
      'Введи 6-значний код із застосунку-автентифікатора або один із кодів відновлення.';

  @override
  String get code => 'Код';

  @override
  String get verify => 'Перевірити';

  @override
  String get back => 'Назад';

  @override
  String get inviteTitle => 'Приєднатися за запрошенням';

  @override
  String inviteNote(String note) {
    return 'Нотатка від організатора: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Посилання дійсне до $date';
  }

  @override
  String get createAccount => 'Створити акаунт';

  @override
  String get createWithPasskey => 'Створити акаунт із ключем доступу';

  @override
  String get orPassword => 'або вибери пароль';

  @override
  String get passwordsDiffer => 'Паролі не збігаються.';

  @override
  String lobbyWelcome(String name) {
    return 'Вітаємо, $name';
  }

  @override
  String get lobbySoon => 'Столи з\'являться в наступному випуску.';

  @override
  String get account => 'Акаунт';

  @override
  String get admin => 'Адмін';

  @override
  String get signOut => 'Вийти';

  @override
  String get save => 'Зберегти';

  @override
  String get saved => 'Збережено';

  @override
  String get cancel => 'Скасувати';

  @override
  String get close => 'Закрити';

  @override
  String get delete => 'Видалити';

  @override
  String get copy => 'Копіювати';

  @override
  String get copied => 'Скопійовано';

  @override
  String get remove => 'Прибрати';

  @override
  String get rename => 'Перейменувати';

  @override
  String get profile => 'Профіль';

  @override
  String get changePassword => 'Змінити пароль';

  @override
  String get currentPassword => 'Поточний пароль';

  @override
  String get newPassword => 'Новий пароль';

  @override
  String get passwordChanged => 'Пароль змінено. Інші твої сеанси завершено.';

  @override
  String get mustChangeTitle => 'Вибери новий пароль';

  @override
  String get mustChangeHelp =>
      'Адмін дав тобі тимчасовий пароль. Вибери свій, щоб продовжити.';

  @override
  String get sessions => 'Сеанси';

  @override
  String get thisDevice => 'цей пристрій';

  @override
  String get revoke => 'Вийти';

  @override
  String get revokeOthers => 'Вийти на всіх інших пристроях';

  @override
  String lastSeen(String date) {
    return 'востаннє $date';
  }

  @override
  String get twoFactor => 'Двофакторний вхід';

  @override
  String twoFactorOn(int count) {
    return 'Увімкнено, залишилось кодів відновлення: $count';
  }

  @override
  String get twoFactorOff => 'Вимкнено';

  @override
  String get enable => 'Увімкнути';

  @override
  String get disable => 'Вимкнути';

  @override
  String get totpScan =>
      'Відскануй цей код застосунком-автентифікатором і введи 6-значний код, який він покаже.';

  @override
  String totpSecret(String secret) {
    return 'Секрет: $secret';
  }

  @override
  String get recoveryTitle => 'Коди відновлення';

  @override
  String get recoveryHelp =>
      'Кожен код дає змогу увійти один раз, коли телефона немає під рукою. Їх показано лише зараз: збережи їх у надійному місці.';

  @override
  String get passkeys => 'Ключі доступу';

  @override
  String get addPasskey => 'Додати ключ доступу';

  @override
  String get noPasskeys => 'Ключів доступу ще немає.';

  @override
  String get synced => 'синхронізовано';

  @override
  String get passkeyName => 'Назва ключа доступу';

  @override
  String get passkeyUnsupported =>
      'Ключі доступу недоступні на цьому пристрої.';

  @override
  String get avatar => 'Аватар';

  @override
  String get uploadAvatar => 'Завантажити зображення';

  @override
  String get dangerZone => 'Видалити акаунт';

  @override
  String get deleteAccountHelp =>
      'Твій акаунт і все, що в ньому є, буде видалено назавжди.';

  @override
  String get deleteAccountConfirm => 'Введи пароль, щоб видалити акаунт.';

  @override
  String get users => 'Користувачі';

  @override
  String get invitations => 'Запрошення';

  @override
  String get settings => 'Налаштування';

  @override
  String get auditLog => 'Журнал аудиту';

  @override
  String get search => 'Пошук';

  @override
  String get newUser => 'Новий користувач';

  @override
  String get makeAdmin => 'Адмін';

  @override
  String get disabled => 'Вимкнено';

  @override
  String get resetPassword => 'Скинути пароль';

  @override
  String get reset2fa => 'Скинути двофакторний вхід';

  @override
  String get temporaryPassword => 'Тимчасовий пароль';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Передай його користувачу $name особисто. Його показано лише зараз, і його треба змінити під час першого входу.';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Видалити $name і все, що є в акаунті?';
  }

  @override
  String get newInvitation => 'Нове запрошення';

  @override
  String get validHours => 'Дійсне (годин)';

  @override
  String get uses => 'Використань';

  @override
  String get note => 'Нотатка (необов\'язково)';

  @override
  String get invitationLink => 'Посилання-запрошення';

  @override
  String get invitationLinkHelp =>
      'Надішли це посилання гравцю. Його показано лише зараз.';

  @override
  String invitationUses(int uses, int max) {
    return 'Використано: $uses з $max';
  }

  @override
  String get invitationRevoked => 'відкликано';

  @override
  String get invitationExpired => 'прострочено';

  @override
  String joinedBy(String names) {
    return 'Приєдналися: $names';
  }

  @override
  String get tableCreation => 'Хто може створювати столи';

  @override
  String get everyone => 'Усі гравці';

  @override
  String get adminsOnly => 'Лише адміни';

  @override
  String get maxUpload => 'Макс. розмір завантаження (КіБ)';

  @override
  String get loadMore => 'Завантажити ще';

  @override
  String get filterAction => 'Дія (точно або префікс із крапкою в кінці)';

  @override
  String get errNetwork => 'Сервер недоступний.';

  @override
  String get errNotServer => 'За цією адресою немає сервера Oxi Poker.';

  @override
  String get errBadAddress => 'Введи адресу на кшталт poker.example.com.';

  @override
  String get errInvalidCredentials =>
      'Неправильне ім\'я користувача або пароль.';

  @override
  String get errRateLimited => 'Забагато спроб. Спробуй трохи пізніше.';

  @override
  String get errInvalidCode => 'Цей код недійсний.';

  @override
  String get errChallengeExpired => 'Вхід тривав надто довго. Почни знову.';

  @override
  String get errInvitationInvalid => 'Це посилання-запрошення недійсне.';

  @override
  String get errInvitationExpired =>
      'Термін дії цього посилання-запрошення минув.';

  @override
  String get errInvitationUsed => 'Це посилання-запрошення вже використано.';

  @override
  String get errBadUsername =>
      'Ім\'я користувача: від 3 до 32 символів (літери, цифри, крапки, дефіси або підкреслення).';

  @override
  String get errBadDisplayName => 'Відображуване ім\'я: від 1 до 64 символів.';

  @override
  String get errBadPassword => 'Пароль: від 10 до 256 символів.';

  @override
  String get errUsernameTaken => 'Це ім\'я користувача вже зайняте.';

  @override
  String get errWrongPassword => 'Неправильний пароль.';

  @override
  String get errLastAdmin => 'На сервері має бути хоча б один адмін.';

  @override
  String get errSelf => 'Тут цього не можна зробити з власним акаунтом.';

  @override
  String get errTooLarge => 'Файл завеликий.';

  @override
  String get errBadImage => 'Використай зображення PNG, JPEG, GIF або WebP.';

  @override
  String get errPasskeyRejected => 'Ключ доступу не прийнято.';

  @override
  String get errLastSignInMethod =>
      'Це твій останній спосіб входу. Спершу додай пароль або інший ключ доступу.';

  @override
  String get errBadInvitation =>
      'Годин від 1 до 720, використань від 1 до 100, нотатка до 200 символів.';

  @override
  String get errBadSettings =>
      'Розмір завантаження має бути від 256 КіБ до 20 МіБ.';

  @override
  String errGeneric(String code) {
    return 'Щось пішло не так ($code).';
  }

  @override
  String get handHistory => 'Історія роздач';

  @override
  String get createTable => 'Створити стіл';

  @override
  String get create => 'Створити';

  @override
  String get noTables =>
      'Відкритих столів ще немає. Створи стіл і запроси друзів.';

  @override
  String get closeTable => 'Закрити стіл';

  @override
  String closeTableConfirm(String name) {
    return 'Закрити стіл $name? Поточну роздачу буде скасовано, а всі стеки повернуться до попереднього стану.';
  }

  @override
  String blinds(int sb, int bb) {
    return 'Блайнди $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'Стек $n';
  }

  @override
  String get connecting => 'Підключення…';

  @override
  String get reconnecting => 'Зв\'язок втрачено, перепідключення…';

  @override
  String get serverRestarting =>
      'Сервер перезапускається. Поточну роздачу скасовано, фішки повернуто; стіл скоро повернеться.';

  @override
  String get tableName => 'Назва столу';

  @override
  String get seats => 'Місця';

  @override
  String get smallBlind => 'Малий блайнд';

  @override
  String get bigBlind => 'Великий блайнд';

  @override
  String get startingStack => 'Початковий стек';

  @override
  String get turnTime => 'Час на хід (секунд)';

  @override
  String get allowSpectators => 'Дозволити глядачів';

  @override
  String get errTableName => 'Назва: від 1 до 40 символів.';

  @override
  String get errBlinds =>
      'Блайнди мають бути не менше 1, а малий блайнд не більший за великий.';

  @override
  String get errStack =>
      'Початковий стек має бути щонайменше два великі блайнди.';

  @override
  String get errTurnTime => 'Час на хід: від 5 до 300 секунд.';

  @override
  String get wsNotYourTurn => 'Зараз не твій хід.';

  @override
  String get wsSeatTaken => 'Це місце щойно зайняли.';

  @override
  String get wsAlreadySeated => 'Ти вже маєш місце за цим столом.';

  @override
  String get wsIllegal => 'Ця дія зараз неможлива.';

  @override
  String get wsSpectatorsOff =>
      'За цим столом немає глядачів. Сядь, щоб приєднатися.';

  @override
  String get table => 'Стіл';

  @override
  String get sitOut => 'Пропустити';

  @override
  String get comeBack => 'Повернутися';

  @override
  String get leaveSeat => 'Звільнити місце';

  @override
  String get chat => 'Чат';

  @override
  String get tableClosed => 'Цей стіл закрито.';

  @override
  String get backToLobby => 'Назад у лобі';

  @override
  String get watchingHint => 'Ти спостерігаєш. Вибери вільне місце, щоб грати.';

  @override
  String get bustedHint =>
      'Фішки закінчилися. Натисни «Повернутися» в меню місця, щоб зайти знову.';

  @override
  String get sittingOutHint =>
      'Ти пропускаєш гру. Натисни «Повернутися» в меню місця, щоб зіграти наступну роздачу.';

  @override
  String get waitingForPlayers => 'Чекаємо на гравців';

  @override
  String get nextHandSoon => 'Наступна роздача ось-ось почнеться';

  @override
  String waitingFor(String name) {
    return 'Чекаємо на $name';
  }

  @override
  String potMain(String amount) {
    return 'Банк $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Сайд-пот $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name виграє $amount';
  }

  @override
  String get sit => 'Сісти тут';

  @override
  String get emptySeat => 'Вільно';

  @override
  String get sittingOut => 'Пропускає';

  @override
  String get folded => 'Фолд';

  @override
  String get allIn => 'Олл-ін';

  @override
  String allInTo(String amount) {
    return 'Олл-ін $amount';
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
  String get presetMin => 'Мін';

  @override
  String get presetHalfPot => '½ банку';

  @override
  String get presetPot => 'Банк';

  @override
  String get presetAllIn => 'Олл-ін';

  @override
  String get fold => 'Фолд';

  @override
  String get check => 'Чек';

  @override
  String get bet => 'Бет';

  @override
  String get chatNotStored =>
      'Бачать гравці й глядачі, ніколи не зберігається.';

  @override
  String get chatHint => 'Повідомлення';

  @override
  String get noHands => 'Ще не зіграно жодної роздачі.';

  @override
  String potLabel(String amount) {
    return 'банк $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who ставить малий блайнд $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who ставить великий блайнд $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who отримує $cards';
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
    return '$who повернуто $amount';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who показує $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who виграє $amount';
  }

  @override
  String get replay => 'Повтор';

  @override
  String get yourCards => 'Твої карти';

  @override
  String stepOf(int step, int total) {
    return '$step з $total';
  }

  @override
  String get stats => 'Твоя статистика';

  @override
  String get handsPlayed => 'Зіграно роздач';

  @override
  String get handsWon => 'Виграно роздач';

  @override
  String get biggestPot => 'Найбільший виграний банк';

  @override
  String get sngGames => 'Ігри сіт-енд-гоу';

  @override
  String get sngWins => 'Перемоги в сіт-енд-гоу';

  @override
  String get sngBest => 'Найкраще місце';

  @override
  String get tableKind => 'Гра';

  @override
  String get kindCash => 'Кеш-гра';

  @override
  String get kindSng => 'Сіт-енд-гоу';

  @override
  String get structure => 'Рівні блайндів';

  @override
  String structureTurbo(int min) {
    return 'Турбо, $min хв';
  }

  @override
  String structureRegular(int min) {
    return 'Звичайна, $min хв';
  }

  @override
  String structureSlow(int min) {
    return 'Повільна, $min хв';
  }

  @override
  String get firstBlinds => 'Блайнди першого рівня';

  @override
  String sngRegistering(int n) {
    return 'Реєстрація, гравців за столом: $n. Організатор запускає гру, або вона почнеться, коли всі місця буде зайнято.';
  }

  @override
  String get startGame => 'Почати гру';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Рівень $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'далі $sb/$bb через $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'далі $sb/$bb з наступної роздачі';
  }

  @override
  String get sngLastLevel => 'останній рівень';

  @override
  String get standings => 'Підсумкова таблиця';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'Твоє місце: #$place';
  }

  @override
  String get wsSngStarted => 'Сіт-енд-гоу вже почався.';

  @override
  String get wsTooFewPlayers =>
      'Для сіт-енд-гоу потрібно щонайменше два гравці.';

  @override
  String get wsHostOnly => 'Це може зробити лише організатор або адмін.';

  @override
  String get appearance => 'Вигляд';

  @override
  String get theme => 'Тема';

  @override
  String get themeClassic => 'Класична';

  @override
  String get themeCyberpunk => 'Кіберпанк';

  @override
  String get cardBack => 'Сорочка карт';

  @override
  String get serverDefault => 'Як на сервері';

  @override
  String get defaultCardBack => 'Типова сорочка карт';

  @override
  String get cardBacks => 'Сорочки карт';

  @override
  String get errBadTheme => 'Невідома тема.';

  @override
  String get errBadCardBack => 'Ця сорочка карт недоступна.';

  @override
  String get errCardBackDefault => 'Типову сорочку карт не можна видалити.';

  @override
  String get uploadCardBack => 'Завантажити сорочку карт';

  @override
  String get cardBackName => 'Назва сорочки';

  @override
  String get errTooManyCardBacks =>
      'Завантажено забагато сорочок карт. Спершу видали одну.';

  @override
  String get chatUserMenuHint =>
      'Торкнися рядка в чаті, щоб заблокувати автора або поскаржитися на нього.';

  @override
  String get blockUser => 'Заблокувати';

  @override
  String get reportUser => 'Поскаржитися';

  @override
  String get muteInChat => 'Вимкнути звук у чаті цього столу';

  @override
  String get unmuteInChat => 'Увімкнути звук у чаті цього столу';

  @override
  String get removeSpectator => 'Прибрати зі столу';

  @override
  String userBlocked(String name) {
    return '$name заблоковано. Ти більше не бачиш повідомлень цього гравця.';
  }

  @override
  String reportTitle(String name) {
    return 'Скарга на $name';
  }

  @override
  String get reasonChat => 'Чат';

  @override
  String get reasonBehaviour => 'Поведінка';

  @override
  String get reasonOther => 'Інше';

  @override
  String get reportNote => 'Що сталося? (необов\'язково)';

  @override
  String get reportChatHint =>
      'Останні рядки чату цього столу буде додано до скарги, щоб адмін бачив, що було сказано.';

  @override
  String get sendReport => 'Надіслати скаргу';

  @override
  String get reportSent => 'Скаргу надіслано адміну сервера.';

  @override
  String get blockedUsers => 'Заблоковані користувачі';

  @override
  String get noBlockedUsers =>
      'Ти нікого не заблокував. Торкнися рядка в чаті за столом, щоб заблокувати автора.';

  @override
  String get unblock => 'Розблокувати';

  @override
  String get reports => 'Скарги';

  @override
  String get showResolved => 'Показати розглянуті скарги';

  @override
  String get noReports => 'Скарг немає.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter поскаржився на $reported';
  }

  @override
  String resolvedBy(String name) {
    return 'розглянуто: $name';
  }

  @override
  String get reportNoChat => 'До цієї скарги не додано рядків чату.';

  @override
  String get resolve => 'Позначити розглянутою';

  @override
  String get wsMuted => 'Організатор вимкнув тобі звук у чаті цього столу.';

  @override
  String get wsRemoved => 'Організатор прибрав тебе з цього столу.';

  @override
  String get wsIsPlayer => 'Гравців прибрати не можна, лише глядачів.';

  @override
  String get errBusy => 'Сервер зайнятий. Спробуй за мить.';

  @override
  String get errBadName => 'Назва: від 1 до 64 символів.';

  @override
  String get errBuiltIn => 'Вбудовані сорочки карт не можна видалити.';

  @override
  String get errTotpEnabled => 'Двофакторний вхід уже ввімкнено.';

  @override
  String get errTotpNotStarted =>
      'Почни налаштування двофакторного входу знову.';

  @override
  String get errTotpNotEnabled => 'Двофакторний вхід не ввімкнено.';

  @override
  String get errPasswordChangeRequired => 'Спершу зміни пароль.';

  @override
  String get errTooManyTables =>
      'На сервері забагато відкритих столів. Спробуй пізніше.';

  @override
  String get errTooManyPasskeys =>
      'У тебе забагато ключів доступу. Спершу видали один.';

  @override
  String get errTooManyBlocks =>
      'Твій список блокування заповнено. Спершу когось розблокуй.';

  @override
  String get errTooManyReports =>
      'Ти надіслав забагато скарг. Спробуй пізніше.';

  @override
  String get errReportSelf => 'Не можна скаржитися на себе.';

  @override
  String get errBlockSelf => 'Не можна заблокувати себе.';

  @override
  String get errBadReport => 'Вибери причину; нотатка до 500 символів.';

  @override
  String get errAdminOnly => 'Це може зробити лише адмін.';

  @override
  String get errNotFound => 'Цього вже не існує.';

  @override
  String get errUnauthenticated => 'Увійди знову.';

  @override
  String get errBadRequest => 'Сервер не зрозумів запит. Онови застосунок.';

  @override
  String get errInternal => 'На сервері сталася помилка. Спробуй ще раз.';

  @override
  String get wsNotSeated => 'У тебе немає місця за цим столом.';

  @override
  String get wsNotInHand => 'Ти не береш участі в цій роздачі.';

  @override
  String get wsNoTable => 'Цей стіл закрито.';

  @override
  String get wsNotSng => 'Запустити можна лише сіт-енд-гоу.';

  @override
  String get wsBadChat => 'Рядок чату: від 1 до 300 символів.';

  @override
  String get wsBadSeat => 'Такого місця немає.';

  @override
  String get imagesFileType => 'Зображення';

  @override
  String get defaultTableName => 'П\'ятнична гра';

  @override
  String get language => 'Мова';

  @override
  String get languageDevice => 'Мова пристрою';

  @override
  String get errMediaOff => 'Голос і відео на цьому сервері не налаштовані.';

  @override
  String get errNotAtTable =>
      'Спершу приєднайтеся до столу, щоб користуватися голосом і відео.';

  @override
  String get callJoin => 'Приєднатися до голосу й відео';

  @override
  String get callMuteMic => 'Вимкнути мікрофон';

  @override
  String get callStopCamera => 'Вимкнути камеру';

  @override
  String get callRemoveUser => 'Прибрати з дзвінка';

  @override
  String get callLeave => 'Вийти з дзвінка';

  @override
  String get callMicOn => 'Увімкнути мікрофон';

  @override
  String get callMicOff => 'Вимкнути мікрофон';

  @override
  String get callCameraOn => 'Увімкнути камеру';

  @override
  String get callCameraOff => 'Вимкнути камеру';

  @override
  String get callSpeaker => 'Динамік';

  @override
  String get callSwitchCamera => 'Змінити камеру';

  @override
  String get callConnecting => 'Підключення до дзвінка…';

  @override
  String get callLost =>
      'Дзвінок обірвався. Гра триває; приєднуйтеся знову, коли захочете.';

  @override
  String get callRemoved => 'Вас вилучили з дзвінка.';

  @override
  String get callMicRefused =>
      'Oxi Poker не має доступу до мікрофона. Дозвольте його в налаштуваннях системи або браузера і спробуйте знову.';

  @override
  String get callCameraRefused =>
      'Oxi Poker не має доступу до камери. Дозвольте її в налаштуваннях системи або браузера і спробуйте знову.';

  @override
  String get callHttpsHint =>
      'Браузери дають доступ до камери й мікрофона лише сторінкам, відкритим через HTTPS.';

  @override
  String get callBackgroundTitle => 'Дзвінок Oxi Poker';

  @override
  String get callBackgroundText =>
      'Мікрофон лишається увімкненим, поки застосунок у фоні.';

  @override
  String callInCall(int count) {
    return 'У дзвінку: $count';
  }
}
