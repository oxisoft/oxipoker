// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'サーバーに接続';

  @override
  String get serverHint => 'サーバーアドレスまたは招待リンク';

  @override
  String get serverHelp => 'ホストから届いた招待リンク、またはポーカーサーバーのアドレスを貼り付けてください。';

  @override
  String get connect => '接続';

  @override
  String get changeServer => 'サーバーを変更';

  @override
  String serverVersion(String version) {
    return 'サーバー $version';
  }

  @override
  String get signInTitle => 'サインイン';

  @override
  String get username => 'ユーザー名';

  @override
  String get displayName => '表示名';

  @override
  String get displayNameOptional => '表示名（任意）';

  @override
  String get password => 'パスワード';

  @override
  String get repeatPassword => 'パスワード（確認）';

  @override
  String get signIn => 'サインイン';

  @override
  String get signInPasskey => 'パスキーでサインイン';

  @override
  String get totpTitle => '2段階認証コード';

  @override
  String get totpHelp => '認証アプリに表示される6桁のコード、またはリカバリーコードを入力してください。';

  @override
  String get code => 'コード';

  @override
  String get verify => '確認';

  @override
  String get back => '戻る';

  @override
  String get inviteTitle => '招待で参加';

  @override
  String inviteNote(String note) {
    return 'ホストからのメモ: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'リンクの有効期限: $date';
  }

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get createWithPasskey => 'パスキーでアカウントを作成';

  @override
  String get orPassword => 'またはパスワードを設定';

  @override
  String get passwordsDiffer => 'パスワードが一致しません。';

  @override
  String lobbyWelcome(String name) {
    return 'ようこそ、$nameさん';
  }

  @override
  String get lobbySoon => 'テーブルは次のリリースで公開されます。';

  @override
  String get account => 'アカウント';

  @override
  String get admin => '管理';

  @override
  String get signOut => 'サインアウト';

  @override
  String get save => '保存';

  @override
  String get saved => '保存しました';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get delete => '削除';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get remove => '削除';

  @override
  String get rename => '名前を変更';

  @override
  String get profile => 'プロフィール';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get passwordChanged => 'パスワードを変更しました。他のセッションはサインアウトされました。';

  @override
  String get mustChangeTitle => '新しいパスワードを設定';

  @override
  String get mustChangeHelp => '管理者から仮パスワードが発行されています。続けるにはご自身のパスワードを設定してください。';

  @override
  String get sessions => 'セッション';

  @override
  String get thisDevice => 'このデバイス';

  @override
  String get revoke => 'サインアウト';

  @override
  String get revokeOthers => '他のすべての場所からサインアウト';

  @override
  String lastSeen(String date) {
    return '最終アクセス $date';
  }

  @override
  String get twoFactor => '2段階認証';

  @override
  String twoFactorOn(int count) {
    return 'オン（リカバリーコード残り$count個）';
  }

  @override
  String get twoFactorOff => 'オフ';

  @override
  String get enable => 'オンにする';

  @override
  String get disable => 'オフにする';

  @override
  String get totpScan => '認証アプリでこのコードをスキャンし、表示される6桁のコードを入力してください。';

  @override
  String totpSecret(String secret) {
    return 'シークレット: $secret';
  }

  @override
  String get recoveryTitle => 'リカバリーコード';

  @override
  String get recoveryHelp =>
      'スマートフォンが手元にないとき、各コードで1回だけサインインできます。表示されるのは今だけなので、安全な場所に保管してください。';

  @override
  String get passkeys => 'パスキー';

  @override
  String get addPasskey => 'パスキーを追加';

  @override
  String get noPasskeys => 'パスキーはまだありません。';

  @override
  String get synced => '同期済み';

  @override
  String get passkeyName => 'パスキー名';

  @override
  String get passkeyUnsupported => 'このデバイスではパスキーを使用できません。';

  @override
  String get avatar => 'アバター';

  @override
  String get uploadAvatar => '画像をアップロード';

  @override
  String get dangerZone => 'アカウントを削除';

  @override
  String get deleteAccountHelp => 'アカウントとそのすべてのデータが完全に削除されます。';

  @override
  String get deleteAccountConfirm => 'アカウントを削除するにはパスワードを入力してください。';

  @override
  String get users => 'ユーザー';

  @override
  String get invitations => '招待';

  @override
  String get settings => '設定';

  @override
  String get auditLog => '監査ログ';

  @override
  String get search => '検索';

  @override
  String get newUser => '新規ユーザー';

  @override
  String get makeAdmin => '管理者';

  @override
  String get disabled => '無効';

  @override
  String get resetPassword => 'パスワードをリセット';

  @override
  String get reset2fa => '2段階認証をリセット';

  @override
  String get temporaryPassword => '仮パスワード';

  @override
  String temporaryPasswordHelp(String name) {
    return '$nameさんに個別に伝えてください。表示されるのは今だけで、初回サインイン時に変更が必要です。';
  }

  @override
  String deleteUserConfirm(String name) {
    return '$nameさんとアカウント内のすべてのデータを削除しますか？';
  }

  @override
  String get newInvitation => '新しい招待';

  @override
  String get validHours => '有効期間（時間）';

  @override
  String get uses => '使用回数';

  @override
  String get note => 'メモ（任意）';

  @override
  String get invitationLink => '招待リンク';

  @override
  String get invitationLinkHelp => 'このリンクをプレイヤーに送ってください。表示されるのは今だけです。';

  @override
  String invitationUses(int uses, int max) {
    return '$max回中$uses回使用';
  }

  @override
  String get invitationRevoked => '取り消し済み';

  @override
  String get invitationExpired => '期限切れ';

  @override
  String joinedBy(String names) {
    return '参加者: $names';
  }

  @override
  String get tableCreation => 'テーブルを作成できる人';

  @override
  String get everyone => '全プレイヤー';

  @override
  String get adminsOnly => '管理者のみ';

  @override
  String get maxUpload => '最大アップロードサイズ（KiB）';

  @override
  String get loadMore => 'さらに読み込む';

  @override
  String get filterAction => 'アクション（完全一致、またはドットで終わる接頭辞）';

  @override
  String get errNetwork => 'サーバーに接続できません。';

  @override
  String get errNotServer => 'このアドレスに Oxi Poker サーバーが見つかりません。';

  @override
  String get errBadAddress => 'poker.example.com のようなアドレスを入力してください。';

  @override
  String get errInvalidCredentials => 'ユーザー名またはパスワードが違います。';

  @override
  String get errRateLimited => '試行回数が多すぎます。しばらくしてからもう一度お試しください。';

  @override
  String get errInvalidCode => 'このコードは無効です。';

  @override
  String get errChallengeExpired => 'サインインに時間がかかりすぎました。最初からやり直してください。';

  @override
  String get errInvitationInvalid => 'この招待リンクは無効です。';

  @override
  String get errInvitationExpired => 'この招待リンクは期限切れです。';

  @override
  String get errInvitationUsed => 'この招待リンクはすでに使用されています。';

  @override
  String get errBadUsername => 'ユーザー名は3〜32文字の英字、数字、ドット、ハイフン、アンダースコアで入力してください。';

  @override
  String get errBadDisplayName => '表示名は1〜64文字で入力してください。';

  @override
  String get errBadPassword => 'パスワードは10〜256文字で入力してください。';

  @override
  String get errUsernameTaken => 'このユーザー名はすでに使われています。';

  @override
  String get errWrongPassword => 'パスワードが違います。';

  @override
  String get errLastAdmin => 'サーバーには管理者が1人以上必要です。';

  @override
  String get errSelf => 'ここでは自分のアカウントにこの操作はできません。';

  @override
  String get errTooLarge => 'ファイルが大きすぎます。';

  @override
  String get errBadImage => 'PNG、JPEG、GIF、WebP のいずれかの画像を使用してください。';

  @override
  String get errPasskeyRejected => 'パスキーが受け付けられませんでした。';

  @override
  String get errLastSignInMethod => 'これが最後のサインイン方法です。先にパスワードか別のパスキーを追加してください。';

  @override
  String get errBadInvitation => '時間は1〜720、使用回数は1〜100、メモは200文字以内です。';

  @override
  String get errBadSettings => 'アップロードサイズは256 KiB〜20 MiBの範囲で指定してください。';

  @override
  String errGeneric(String code) {
    return '問題が発生しました（$code）。';
  }

  @override
  String get handHistory => 'ハンド履歴';

  @override
  String get createTable => 'テーブルを作成';

  @override
  String get create => '作成';

  @override
  String get noTables => '開いているテーブルはまだありません。テーブルを作成して友だちを招待しましょう。';

  @override
  String get closeTable => 'テーブルを閉じる';

  @override
  String closeTableConfirm(String name) {
    return 'テーブル「$name」を閉じますか？進行中のハンドはキャンセルされ、すべてのスタックは元に戻ります。';
  }

  @override
  String blinds(int sb, int bb) {
    return 'ブラインド $sb/$bb';
  }

  @override
  String stackLabel(int n) {
    return 'スタック $n';
  }

  @override
  String get connecting => '接続中…';

  @override
  String get reconnecting => '接続が切れました。再接続中…';

  @override
  String get serverRestarting =>
      'サーバーを再起動しています。進行中のハンドはキャンセルされ、チップは返却されます。テーブルはまもなく戻ります。';

  @override
  String get tableName => 'テーブル名';

  @override
  String get seats => '席数';

  @override
  String get smallBlind => 'スモールブラインド';

  @override
  String get bigBlind => 'ビッグブラインド';

  @override
  String get startingStack => '初期スタック';

  @override
  String get turnTime => '持ち時間（秒）';

  @override
  String get allowSpectators => '観戦を許可';

  @override
  String get errTableName => '名前は1〜40文字で入力してください。';

  @override
  String get errBlinds => 'ブラインドは1以上で、スモールブラインドはビッグブラインド以下にしてください。';

  @override
  String get errStack => '初期スタックはビッグブラインド2つ分以上にしてください。';

  @override
  String get errTurnTime => '持ち時間は5〜300秒にしてください。';

  @override
  String get wsNotYourTurn => 'あなたの番ではありません。';

  @override
  String get wsSeatTaken => 'その席はたった今埋まりました。';

  @override
  String get wsAlreadySeated => 'このテーブルにはすでに着席しています。';

  @override
  String get wsIllegal => '今はそのアクションはできません。';

  @override
  String get wsSpectatorsOff => 'このテーブルは観戦できません。参加するには着席してください。';

  @override
  String get table => 'テーブル';

  @override
  String get sitOut => 'シットアウト';

  @override
  String get comeBack => '復帰';

  @override
  String get leaveSeat => '席を離れる';

  @override
  String get chat => 'チャット';

  @override
  String get tableClosed => 'このテーブルは閉じられました。';

  @override
  String get backToLobby => 'ロビーに戻る';

  @override
  String get watchingHint => '観戦中です。プレイするには空席を選んでください。';

  @override
  String get bustedHint => 'チップがなくなりました。席メニューの「復帰」で再度バイインできます。';

  @override
  String get sittingOutHint => 'シットアウト中です。席メニューの「復帰」で次のハンドからプレイできます。';

  @override
  String get waitingForPlayers => 'プレイヤーを待っています';

  @override
  String get nextHandSoon => 'まもなく次のハンドが始まります';

  @override
  String waitingFor(String name) {
    return '$nameさんを待っています';
  }

  @override
  String potMain(String amount) {
    return 'ポット $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'サイドポット $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$nameさんが $amount を獲得';
  }

  @override
  String get sit => 'ここに座る';

  @override
  String get emptySeat => '空席';

  @override
  String get sittingOut => 'シットアウト中';

  @override
  String get folded => 'フォールド';

  @override
  String get allIn => 'オールイン';

  @override
  String allInTo(String amount) {
    return 'オールイン $amount';
  }

  @override
  String raiseTo(String amount) {
    return '$amount にレイズ';
  }

  @override
  String betAmount(String amount) {
    return 'ベット $amount';
  }

  @override
  String callAmount(String amount) {
    return 'コール $amount';
  }

  @override
  String get presetMin => '最小';

  @override
  String get presetHalfPot => '½ ポット';

  @override
  String get presetPot => 'ポット';

  @override
  String get presetAllIn => 'オールイン';

  @override
  String get fold => 'フォールド';

  @override
  String get check => 'チェック';

  @override
  String get bet => 'ベット';

  @override
  String get chatNotStored => 'プレイヤーと観戦者に表示され、保存されることはありません。';

  @override
  String get chatHint => 'メッセージ';

  @override
  String get noHands => 'まだプレイしたハンドはありません。';

  @override
  String potLabel(String amount) {
    return 'ポット $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who がスモールブラインド $amount をポスト';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who がビッグブラインド $amount をポスト';
  }

  @override
  String evHole(String who, String cards) {
    return '$who に $cards が配られました';
  }

  @override
  String evFold(String who) {
    return '$who がフォールド';
  }

  @override
  String evCheck(String who) {
    return '$who がチェック';
  }

  @override
  String evCall(String who, String amount) {
    return '$who が $amount をコール';
  }

  @override
  String evBet(String who, String amount) {
    return '$who が $amount をベット';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who が $amount にレイズ';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount が $who に返却されました';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who が $cards をショウ';
  }

  @override
  String evWin(String who, String amount) {
    return '$who が $amount を獲得';
  }

  @override
  String get replay => 'リプレイ';

  @override
  String get yourCards => 'あなたのカード';

  @override
  String stepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get stats => 'あなたの成績';

  @override
  String get handsPlayed => 'プレイしたハンド';

  @override
  String get handsWon => '勝ったハンド';

  @override
  String get biggestPot => '最大獲得ポット';

  @override
  String get sngGames => 'シットアンドゴーの参加数';

  @override
  String get sngWins => 'シットアンドゴーの優勝数';

  @override
  String get sngBest => '最高順位';

  @override
  String get tableKind => 'ゲーム';

  @override
  String get kindCash => 'キャッシュゲーム';

  @override
  String get kindSng => 'シットアンドゴー';

  @override
  String get structure => 'ブラインドレベル';

  @override
  String structureTurbo(int min) {
    return 'ターボ、$min分';
  }

  @override
  String structureRegular(int min) {
    return 'レギュラー、$min分';
  }

  @override
  String structureSlow(int min) {
    return 'スロー、$min分';
  }

  @override
  String get firstBlinds => '最初のレベルのブラインド';

  @override
  String sngRegistering(int n) {
    return '登録受付中: $n人着席。ホストが開始するか、全席が埋まると始まります。';
  }

  @override
  String get startGame => 'ゲームを開始';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'レベル $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return '$time後に $sb/$bb';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return '次のハンドから $sb/$bb';
  }

  @override
  String get sngLastLevel => '最終レベル';

  @override
  String get standings => '最終順位';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return 'あなたは$place位でした';
  }

  @override
  String get wsSngStarted => 'このシットアンドゴーはすでに始まっています。';

  @override
  String get wsTooFewPlayers => 'シットアンドゴーには2人以上のプレイヤーが必要です。';

  @override
  String get wsHostOnly => 'この操作はホストまたは管理者のみ行えます。';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get themeClassic => 'クラシック';

  @override
  String get themeCyberpunk => 'サイバーパンク';

  @override
  String get cardBack => 'カードの裏面';

  @override
  String get serverDefault => 'サーバーの既定';

  @override
  String get defaultCardBack => '既定のカード裏面';

  @override
  String get cardBacks => 'カードの裏面';

  @override
  String get errBadTheme => '不明なテーマです。';

  @override
  String get errBadCardBack => 'そのカード裏面は利用できません。';

  @override
  String get errCardBackDefault => '既定のカード裏面は削除できません。';

  @override
  String get uploadCardBack => 'カード裏面をアップロード';

  @override
  String get connectionCheck => '音声・ビデオ接続チェック';

  @override
  String get runConnectionCheck => 'チェックを実行';

  @override
  String get checkSignalling => 'LiveKit シグナリング';

  @override
  String get checkToken => '通話トークンの往復確認';

  @override
  String get checkTurn => 'TLS 経由の TURN';

  @override
  String get checkOk => 'OK';

  @override
  String get checkFailed => '失敗';

  @override
  String get checkSkipped => 'スキップ';

  @override
  String get cardBackName => 'カード裏面の名前';

  @override
  String get errTooManyCardBacks => 'アップロードされたカード裏面が多すぎます。先に1つ削除してください。';

  @override
  String get chatUserMenuHint => 'チャットの行をタップすると、投稿者をブロックまたは報告できます。';

  @override
  String get blockUser => 'ブロック';

  @override
  String get reportUser => '報告';

  @override
  String get muteInChat => 'このテーブルのチャットでミュート';

  @override
  String get unmuteInChat => 'このテーブルのチャットでミュート解除';

  @override
  String get removeSpectator => 'テーブルから退出させる';

  @override
  String userBlocked(String name) {
    return '$nameさんをブロックしました。今後この人のチャットは表示されません。';
  }

  @override
  String reportTitle(String name) {
    return '$nameさんを報告';
  }

  @override
  String get reasonChat => 'チャット';

  @override
  String get reasonBehaviour => '言動';

  @override
  String get reasonOther => 'その他';

  @override
  String get reportNote => '何がありましたか？（任意）';

  @override
  String get reportChatHint => '管理者が内容を確認できるよう、このテーブルの直近のチャットが報告に添付されます。';

  @override
  String get sendReport => '報告を送信';

  @override
  String get reportSent => 'サーバー管理者に報告を送信しました。';

  @override
  String get blockedUsers => 'ブロック中のユーザー';

  @override
  String get noBlockedUsers =>
      'ブロック中のユーザーはいません。テーブルでチャットの行をタップすると投稿者をブロックできます。';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get reports => '報告';

  @override
  String get showResolved => '解決済みの報告を表示';

  @override
  String get noReports => '報告はありません。';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter さんが $reported さんを報告';
  }

  @override
  String resolvedBy(String name) {
    return '$name さんが解決済みにしました';
  }

  @override
  String get reportNoChat => 'この報告にチャットは添付されていません。';

  @override
  String get resolve => '解決済みにする';

  @override
  String get wsMuted => 'ホストによってこのテーブルのチャットでミュートされました。';

  @override
  String get wsRemoved => 'ホストによってこのテーブルから退出させられました。';

  @override
  String get wsIsPlayer => 'プレイヤーは退出させられません。観戦者のみ可能です。';

  @override
  String get errBusy => 'サーバーが混み合っています。少し待ってからもう一度お試しください。';

  @override
  String get errBadName => '名前は1〜64文字で入力してください。';

  @override
  String get errBuiltIn => '組み込みのカード裏面は削除できません。';

  @override
  String get errTotpEnabled => '2段階認証はすでにオンです。';

  @override
  String get errTotpNotStarted => '2段階認証の設定を最初からやり直してください。';

  @override
  String get errTotpNotEnabled => '2段階認証はオンになっていません。';

  @override
  String get errPasswordChangeRequired => '先にパスワードを変更してください。';

  @override
  String get errTooManyTables => 'サーバーで開いているテーブルが多すぎます。後でもう一度お試しください。';

  @override
  String get errTooManyPasskeys => 'パスキーが多すぎます。先に1つ削除してください。';

  @override
  String get errTooManyBlocks => 'ブロックリストがいっぱいです。先に誰かのブロックを解除してください。';

  @override
  String get errTooManyReports => '報告の送信回数が多すぎます。後でもう一度お試しください。';

  @override
  String get errReportSelf => '自分を報告することはできません。';

  @override
  String get errBlockSelf => '自分をブロックすることはできません。';

  @override
  String get errBadReport => '理由を選んでください。メモは500文字以内です。';

  @override
  String get errAdminOnly => 'この操作は管理者のみ行えます。';

  @override
  String get errNotFound => 'それはもう存在しません。';

  @override
  String get errUnauthenticated => 'もう一度サインインしてください。';

  @override
  String get errBadRequest => 'サーバーがリクエストを理解できませんでした。アプリを更新してください。';

  @override
  String get errInternal => 'サーバーでエラーが発生しました。もう一度お試しください。';

  @override
  String get wsNotSeated => 'このテーブルに着席していません。';

  @override
  String get wsNotInHand => 'このハンドには参加していません。';

  @override
  String get wsNoTable => 'このテーブルは閉じられました。';

  @override
  String get wsNotSng => '開始できるのはシットアンドゴーのみです。';

  @override
  String get wsBadChat => 'チャットは1〜300文字で入力してください。';

  @override
  String get wsBadSeat => 'その席は存在しません。';

  @override
  String get imagesFileType => '画像';

  @override
  String get defaultTableName => '金曜ゲーム';

  @override
  String get language => '言語';

  @override
  String get languageDevice => 'デバイスの言語';

  @override
  String get errMediaOff => 'このサーバーでは音声とビデオが設定されていません。';

  @override
  String get errNotAtTable => '音声とビデオを使うには、先にテーブルに参加してください。';

  @override
  String get callJoin => '音声とビデオに参加';

  @override
  String get callMuteMic => 'マイクをオフにする';

  @override
  String get callStopCamera => 'カメラをオフにする';

  @override
  String get callRemoveUser => '通話から外す';

  @override
  String get callLeave => '通話を退出';

  @override
  String get callMicOn => 'マイクをオン';

  @override
  String get callMicOff => 'マイクをオフ';

  @override
  String get callCameraOn => 'カメラをオン';

  @override
  String get callCameraOff => 'カメラをオフ';

  @override
  String get callSpeaker => 'スピーカー';

  @override
  String get callSwitchCamera => 'カメラを切り替え';

  @override
  String get callConnecting => '通話に接続中…';

  @override
  String get callLost => '通話が切断されました。ゲームは続きます。いつでも再参加できます。';

  @override
  String get callRemoved => '通話から外されました。';

  @override
  String get callMicRefused =>
      'Oxi Poker はマイクを使えません。システムまたはブラウザの設定で許可してから、もう一度お試しください。';

  @override
  String get callCameraRefused =>
      'Oxi Poker はカメラを使えません。システムまたはブラウザの設定で許可してから、もう一度お試しください。';

  @override
  String get callHttpsHint => 'ブラウザは HTTPS で開いたページでのみカメラとマイクを許可します。';

  @override
  String get callBackgroundTitle => 'Oxi Poker 通話';

  @override
  String get callBackgroundText => 'アプリがバックグラウンドの間もマイクはオンのままです。';

  @override
  String callInCall(int count) {
    return '通話中: $count';
  }

  @override
  String get about => 'このアプリについて';

  @override
  String appVersion(String version) {
    return 'アプリ $version';
  }

  @override
  String get serverTooOld =>
      'このサーバーの Oxi Poker はこのアプリが必要とするバージョンより古いです。ホストがサーバーを更新するまで一部の機能が動かない場合があります。';
}
