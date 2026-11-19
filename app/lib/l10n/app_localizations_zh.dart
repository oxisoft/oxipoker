// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => '连接服务器';

  @override
  String get serverHint => '服务器地址或邀请链接';

  @override
  String get serverHelp => '粘贴房主发给你的邀请链接，或你的扑克服务器地址。';

  @override
  String get connect => '连接';

  @override
  String get changeServer => '更换服务器';

  @override
  String serverVersion(String version) {
    return '服务器 $version';
  }

  @override
  String get signInTitle => '登录';

  @override
  String get username => '用户名';

  @override
  String get displayName => '显示名称';

  @override
  String get displayNameOptional => '显示名称（可选）';

  @override
  String get password => '密码';

  @override
  String get repeatPassword => '再次输入密码';

  @override
  String get signIn => '登录';

  @override
  String get signInPasskey => '使用通行密钥登录';

  @override
  String get totpTitle => '两步验证码';

  @override
  String get totpHelp => '请输入身份验证器应用中的 6 位验证码，或任一恢复码。';

  @override
  String get code => '验证码';

  @override
  String get verify => '验证';

  @override
  String get back => '返回';

  @override
  String get inviteTitle => '通过邀请加入';

  @override
  String inviteNote(String note) {
    return '房主留言：$note';
  }

  @override
  String inviteExpires(String date) {
    return '链接有效期至 $date';
  }

  @override
  String get createAccount => '创建账户';

  @override
  String get createWithPasskey => '使用通行密钥创建账户';

  @override
  String get orPassword => '或设置密码';

  @override
  String get passwordsDiffer => '两次输入的密码不一致。';

  @override
  String lobbyWelcome(String name) {
    return '欢迎，$name';
  }

  @override
  String get lobbySoon => '牌桌将在下个版本开放。';

  @override
  String get account => '账户';

  @override
  String get admin => '管理';

  @override
  String get signOut => '退出登录';

  @override
  String get save => '保存';

  @override
  String get saved => '已保存';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get delete => '删除';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get remove => '移除';

  @override
  String get rename => '重命名';

  @override
  String get profile => '个人资料';

  @override
  String get changePassword => '修改密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get passwordChanged => '密码已修改，你的其他会话已退出登录。';

  @override
  String get mustChangeTitle => '设置新密码';

  @override
  String get mustChangeHelp => '管理员给了你一个临时密码，请设置你自己的密码后继续。';

  @override
  String get sessions => '会话';

  @override
  String get thisDevice => '本设备';

  @override
  String get revoke => '退出登录';

  @override
  String get revokeOthers => '退出其他所有设备';

  @override
  String lastSeen(String date) {
    return '最近活动 $date';
  }

  @override
  String get twoFactor => '两步验证登录';

  @override
  String twoFactorOn(int count) {
    return '已开启，剩余 $count 个恢复码';
  }

  @override
  String get twoFactorOff => '已关闭';

  @override
  String get enable => '开启';

  @override
  String get disable => '关闭';

  @override
  String get totpScan => '用身份验证器应用扫描此二维码，然后输入显示的 6 位验证码。';

  @override
  String totpSecret(String secret) {
    return '密钥：$secret';
  }

  @override
  String get recoveryTitle => '恢复码';

  @override
  String get recoveryHelp => '手机不在身边时，每个恢复码可登录一次。恢复码仅显示这一次，请妥善保存。';

  @override
  String get passkeys => '通行密钥';

  @override
  String get addPasskey => '添加通行密钥';

  @override
  String get noPasskeys => '还没有通行密钥。';

  @override
  String get synced => '已同步';

  @override
  String get passkeyName => '通行密钥名称';

  @override
  String get passkeyUnsupported => '此设备不支持通行密钥。';

  @override
  String get avatar => '头像';

  @override
  String get uploadAvatar => '上传图片';

  @override
  String get dangerZone => '删除账户';

  @override
  String get deleteAccountHelp => '你的账户及其中的所有内容将被永久删除。';

  @override
  String get deleteAccountConfirm => '请输入密码以删除账户。';

  @override
  String get users => '用户';

  @override
  String get invitations => '邀请';

  @override
  String get settings => '设置';

  @override
  String get auditLog => '审计日志';

  @override
  String get search => '搜索';

  @override
  String get newUser => '新用户';

  @override
  String get makeAdmin => '管理员';

  @override
  String get disabled => '已停用';

  @override
  String get resetPassword => '重置密码';

  @override
  String get reset2fa => '重置两步验证';

  @override
  String get temporaryPassword => '临时密码';

  @override
  String temporaryPasswordHelp(String name) {
    return '请私下发给 $name。密码仅显示这一次，首次登录时必须修改。';
  }

  @override
  String deleteUserConfirm(String name) {
    return '删除 $name 及其账户中的所有内容？';
  }

  @override
  String get newInvitation => '新建邀请';

  @override
  String get validHours => '有效期（小时）';

  @override
  String get uses => '使用次数';

  @override
  String get note => '留言（可选）';

  @override
  String get invitationLink => '邀请链接';

  @override
  String get invitationLinkHelp => '请把此链接发给玩家。链接仅显示这一次。';

  @override
  String invitationUses(int uses, int max) {
    return '已使用 $uses/$max 次';
  }

  @override
  String get invitationRevoked => '已撤销';

  @override
  String get invitationExpired => '已过期';

  @override
  String joinedBy(String names) {
    return '已加入：$names';
  }

  @override
  String get tableCreation => '谁可以创建牌桌';

  @override
  String get everyone => '所有玩家';

  @override
  String get adminsOnly => '仅管理员';

  @override
  String get maxUpload => '最大上传大小（KiB）';

  @override
  String get loadMore => '加载更多';

  @override
  String get filterAction => '操作（完全匹配，或以点结尾的前缀）';

  @override
  String get errNetwork => '无法连接到服务器。';

  @override
  String get errNotServer => '此地址上没有 Oxi Poker 服务器响应。';

  @override
  String get errBadAddress => '请输入类似 poker.example.com 的地址。';

  @override
  String get errInvalidCredentials => '用户名或密码错误。';

  @override
  String get errRateLimited => '尝试次数过多，请稍后再试。';

  @override
  String get errInvalidCode => '验证码无效。';

  @override
  String get errChallengeExpired => '登录超时，请重新开始。';

  @override
  String get errInvitationInvalid => '此邀请链接无效。';

  @override
  String get errInvitationExpired => '此邀请链接已过期。';

  @override
  String get errInvitationUsed => '此邀请链接已被使用。';

  @override
  String get errBadUsername => '用户名为 3 到 32 个字母、数字、点、连字符或下划线。';

  @override
  String get errBadDisplayName => '显示名称为 1 到 64 个字符。';

  @override
  String get errBadPassword => '密码为 10 到 256 个字符。';

  @override
  String get errUsernameTaken => '该用户名已被占用。';

  @override
  String get errWrongPassword => '密码错误。';

  @override
  String get errLastAdmin => '服务器至少需要一名管理员。';

  @override
  String get errSelf => '无法在此对你自己的账户执行此操作。';

  @override
  String get errTooLarge => '文件过大。';

  @override
  String get errBadImage => '请使用 PNG、JPEG、GIF 或 WebP 图片。';

  @override
  String get errPasskeyRejected => '通行密钥未被接受。';

  @override
  String get errLastSignInMethod => '这是你最后一种登录方式。请先添加密码或其他通行密钥。';

  @override
  String get errBadInvitation => '小时数 1 到 720，使用次数 1 到 100，留言最多 200 个字符。';

  @override
  String get errBadSettings => '上传大小必须在 256 KiB 到 20 MiB 之间。';

  @override
  String errGeneric(String code) {
    return '出错了（$code）。';
  }

  @override
  String get handHistory => '牌局记录';

  @override
  String get createTable => '创建牌桌';

  @override
  String get create => '创建';

  @override
  String get noTables => '还没有开放的牌桌。创建一张，邀请你的朋友吧。';

  @override
  String get closeTable => '关闭牌桌';

  @override
  String closeTableConfirm(String name) {
    return '关闭牌桌 $name？进行中的一手牌将被取消，所有筹码恢复原状。';
  }

  @override
  String blinds(int sb, int bb) {
    return '盲注 $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return '筹码 $n';
  }

  @override
  String get connecting => '正在连接…';

  @override
  String get reconnecting => '连接已断开，正在重新连接…';

  @override
  String get serverRestarting => '服务器正在重启。进行中的一手牌将被取消，筹码退回；牌桌稍后恢复。';

  @override
  String get tableName => '牌桌名称';

  @override
  String get seats => '座位数';

  @override
  String get smallBlind => '小盲';

  @override
  String get bigBlind => '大盲';

  @override
  String get startingStack => '初始筹码';

  @override
  String get turnTime => '行动时间（秒）';

  @override
  String get allowSpectators => '允许旁观';

  @override
  String get errTableName => '名称需为 1 到 40 个字符。';

  @override
  String get errBlinds => '盲注至少为 1，且小盲不能大于大盲。';

  @override
  String get errStack => '初始筹码至少为两个大盲。';

  @override
  String get errTurnTime => '行动时间需为 5 到 300 秒。';

  @override
  String get wsNotYourTurn => '还没轮到你。';

  @override
  String get wsSeatTaken => '该座位刚刚被占了。';

  @override
  String get wsAlreadySeated => '你已在此牌桌入座。';

  @override
  String get wsIllegal => '现在无法执行此操作。';

  @override
  String get wsSpectatorsOff => '此牌桌不允许旁观，请入座加入。';

  @override
  String get table => '牌桌';

  @override
  String get sitOut => '暂离';

  @override
  String get comeBack => '回来';

  @override
  String get leaveSeat => '离开座位';

  @override
  String get chat => '聊天';

  @override
  String get tableClosed => '此牌桌已关闭。';

  @override
  String get backToLobby => '返回大厅';

  @override
  String get watchingHint => '你正在旁观。选择一个空座位即可参与。';

  @override
  String get bustedHint => '筹码已输光。在座位菜单中点“回来”即可重新买入。';

  @override
  String get sittingOutHint => '你已暂离。在座位菜单中点“回来”即可参与下一手牌。';

  @override
  String get waitingForPlayers => '等待玩家加入';

  @override
  String get nextHandSoon => '下一手牌即将开始';

  @override
  String waitingFor(String name) {
    return '等待 $name';
  }

  @override
  String potMain(String amount) {
    return '底池 $amount';
  }

  @override
  String potSide(int n, String amount) {
    return '边池 $n：$amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name 赢得 $amount';
  }

  @override
  String get sit => '坐这里';

  @override
  String get emptySeat => '空位';

  @override
  String get sittingOut => '暂离中';

  @override
  String get folded => '已弃牌';

  @override
  String get allIn => '全下';

  @override
  String allInTo(String amount) {
    return '全下 $amount';
  }

  @override
  String raiseTo(String amount) {
    return '加注到 $amount';
  }

  @override
  String betAmount(String amount) {
    return '下注 $amount';
  }

  @override
  String callAmount(String amount) {
    return '跟注 $amount';
  }

  @override
  String get presetMin => '最小';

  @override
  String get presetHalfPot => '½ 底池';

  @override
  String get presetPot => '底池';

  @override
  String get presetAllIn => '全下';

  @override
  String get fold => '弃牌';

  @override
  String get check => '过牌';

  @override
  String get bet => '下注';

  @override
  String get chatNotStored => '玩家和旁观者可见，绝不保存。';

  @override
  String get chatHint => '消息';

  @override
  String get noHands => '还没有打过牌。';

  @override
  String potLabel(String amount) {
    return '底池 $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who 下小盲 $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who 下大盲 $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who 拿到 $cards';
  }

  @override
  String evFold(String who) {
    return '$who 弃牌';
  }

  @override
  String evCheck(String who) {
    return '$who 过牌';
  }

  @override
  String evCall(String who, String amount) {
    return '$who 跟注 $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who 下注 $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who 加注到 $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount 退还给 $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street：$cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who 亮牌 $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who 赢得 $amount';
  }

  @override
  String get replay => '回放';

  @override
  String get yourCards => '你的手牌';

  @override
  String stepOf(int step, int total) {
    return '$step/$total';
  }

  @override
  String get stats => '我的战绩';

  @override
  String get handsPlayed => '已玩手数';

  @override
  String get handsWon => '获胜手数';

  @override
  String get biggestPot => '赢得的最大底池';

  @override
  String get sngGames => '坐满即玩场次';

  @override
  String get sngWins => '坐满即玩夺冠';

  @override
  String get sngBest => '最佳名次';

  @override
  String get tableKind => '玩法';

  @override
  String get kindCash => '现金局';

  @override
  String get kindSng => '坐满即玩';

  @override
  String get structure => '盲注级别';

  @override
  String structureTurbo(int min) {
    return '快速，$min 分钟';
  }

  @override
  String structureRegular(int min) {
    return '标准，$min 分钟';
  }

  @override
  String structureSlow(int min) {
    return '慢速，$min 分钟';
  }

  @override
  String get firstBlinds => '第一级盲注';

  @override
  String sngRegistering(int n) {
    return '报名中：已有 $n 人入座。由房主开始，或坐满后自动开始。';
  }

  @override
  String get startGame => '开始比赛';

  @override
  String sngLevel(int n, int sb, int bb) {
    return '第 $n 级：$sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return '$time 后升至 $sb/$bb';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return '下一手牌起升至 $sb/$bb';
  }

  @override
  String get sngLastLevel => '最后一级';

  @override
  String get standings => '最终排名';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return '你获得第 $place 名';
  }

  @override
  String get wsSngStarted => '该坐满即玩比赛已经开始。';

  @override
  String get wsTooFewPlayers => '坐满即玩至少需要两名玩家。';

  @override
  String get wsHostOnly => '只有房主或管理员可以执行此操作。';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get themeClassic => '经典';

  @override
  String get themeCyberpunk => '赛博朋克';

  @override
  String get cardBack => '牌背';

  @override
  String get serverDefault => '服务器默认';

  @override
  String get defaultCardBack => '默认牌背';

  @override
  String get cardBacks => '牌背';

  @override
  String get errBadTheme => '未知主题。';

  @override
  String get errBadCardBack => '该牌背不可用。';

  @override
  String get errCardBackDefault => '无法删除默认牌背。';

  @override
  String get uploadCardBack => '上传牌背';

  @override
  String get cardBackName => '牌背名称';

  @override
  String get errTooManyCardBacks => '上传的牌背过多，请先删除一个。';

  @override
  String get chatUserMenuHint => '点按一条聊天消息，即可屏蔽或举报发送者。';

  @override
  String get blockUser => '屏蔽';

  @override
  String get reportUser => '举报';

  @override
  String get muteInChat => '在此牌桌聊天中禁言';

  @override
  String get unmuteInChat => '在此牌桌聊天中解除禁言';

  @override
  String get removeSpectator => '移出牌桌';

  @override
  String userBlocked(String name) {
    return '已屏蔽 $name，你将不再看到其聊天消息。';
  }

  @override
  String reportTitle(String name) {
    return '举报 $name';
  }

  @override
  String get reasonChat => '聊天';

  @override
  String get reasonBehaviour => '行为';

  @override
  String get reasonOther => '其他';

  @override
  String get reportNote => '发生了什么？（可选）';

  @override
  String get reportChatHint => '此牌桌最近的聊天记录会随举报一并发送，方便管理员了解情况。';

  @override
  String get sendReport => '发送举报';

  @override
  String get reportSent => '举报已发送给服务器管理员。';

  @override
  String get blockedUsers => '已屏蔽的用户';

  @override
  String get noBlockedUsers => '你还没有屏蔽任何人。在牌桌上点按一条聊天消息即可屏蔽发送者。';

  @override
  String get unblock => '取消屏蔽';

  @override
  String get reports => '举报';

  @override
  String get showResolved => '显示已处理的举报';

  @override
  String get noReports => '没有举报。';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter 举报了 $reported';
  }

  @override
  String resolvedBy(String name) {
    return '由 $name 处理';
  }

  @override
  String get reportNoChat => '此举报未附带聊天记录。';

  @override
  String get resolve => '标记为已处理';

  @override
  String get wsMuted => '房主已在此牌桌聊天中将你禁言。';

  @override
  String get wsRemoved => '房主已将你移出此牌桌。';

  @override
  String get wsIsPlayer => '无法移出玩家，只能移出旁观者。';

  @override
  String get errBusy => '服务器繁忙，请稍后再试。';

  @override
  String get errBadName => '名称为 1 到 64 个字符。';

  @override
  String get errBuiltIn => '无法删除内置牌背。';

  @override
  String get errTotpEnabled => '两步验证登录已开启。';

  @override
  String get errTotpNotStarted => '请重新开始设置两步验证。';

  @override
  String get errTotpNotEnabled => '两步验证登录未开启。';

  @override
  String get errPasswordChangeRequired => '请先修改密码。';

  @override
  String get errTooManyTables => '服务器上开放的牌桌过多，请稍后再试。';

  @override
  String get errTooManyPasskeys => '通行密钥过多，请先删除一个。';

  @override
  String get errTooManyBlocks => '屏蔽列表已满，请先取消屏蔽某人。';

  @override
  String get errTooManyReports => '你发送的举报过多，请稍后再试。';

  @override
  String get errReportSelf => '你不能举报自己。';

  @override
  String get errBlockSelf => '你不能屏蔽自己。';

  @override
  String get errBadReport => '请选择原因；留言最多 500 个字符。';

  @override
  String get errAdminOnly => '只有管理员可以执行此操作。';

  @override
  String get errNotFound => '该内容已不存在。';

  @override
  String get errUnauthenticated => '请重新登录。';

  @override
  String get errBadRequest => '服务器无法识别该请求，请更新应用。';

  @override
  String get errInternal => '服务器出错，请重试。';

  @override
  String get wsNotSeated => '你在此牌桌没有座位。';

  @override
  String get wsNotInHand => '你不在这手牌中。';

  @override
  String get wsNoTable => '此牌桌已关闭。';

  @override
  String get wsNotSng => '只有坐满即玩比赛可以手动开始。';

  @override
  String get wsBadChat => '聊天消息为 1 到 300 个字符。';

  @override
  String get wsBadSeat => '该座位不存在。';

  @override
  String get imagesFileType => '图片';

  @override
  String get defaultTableName => '周五牌局';

  @override
  String get language => '语言';

  @override
  String get languageDevice => '设备语言';
}
