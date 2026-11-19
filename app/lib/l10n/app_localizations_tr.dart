// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Oxi Poker';

  @override
  String get serverTitle => 'Bir sunucuya bağlan';

  @override
  String get serverHint => 'Sunucu adresi veya davet bağlantısı';

  @override
  String get serverHelp =>
      'Ev sahibinden aldığın davet bağlantısını ya da poker sunucunun adresini yapıştır.';

  @override
  String get connect => 'Bağlan';

  @override
  String get changeServer => 'Sunucuyu değiştir';

  @override
  String serverVersion(String version) {
    return 'Sunucu $version';
  }

  @override
  String get signInTitle => 'Giriş yap';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get displayName => 'Görünen ad';

  @override
  String get displayNameOptional => 'Görünen ad (isteğe bağlı)';

  @override
  String get password => 'Şifre';

  @override
  String get repeatPassword => 'Şifreyi tekrarla';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signInPasskey => 'Geçiş anahtarıyla giriş yap';

  @override
  String get totpTitle => 'İki adımlı doğrulama kodu';

  @override
  String get totpHelp =>
      'Doğrulama uygulamandaki 6 haneli kodu ya da kurtarma kodlarından birini gir.';

  @override
  String get code => 'Kod';

  @override
  String get verify => 'Doğrula';

  @override
  String get back => 'Geri';

  @override
  String get inviteTitle => 'Davetle katıl';

  @override
  String inviteNote(String note) {
    return 'Ev sahibinden not: $note';
  }

  @override
  String inviteExpires(String date) {
    return 'Bağlantı geçerlilik sonu: $date';
  }

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get createWithPasskey => 'Geçiş anahtarıyla hesap oluştur';

  @override
  String get orPassword => 'ya da bir şifre seç';

  @override
  String get passwordsDiffer => 'Şifreler eşleşmiyor.';

  @override
  String lobbyWelcome(String name) {
    return 'Hoş geldin, $name';
  }

  @override
  String get lobbySoon => 'Masalar bir sonraki sürümde açılıyor.';

  @override
  String get account => 'Hesap';

  @override
  String get admin => 'Yönetici';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get save => 'Kaydet';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get cancel => 'İptal';

  @override
  String get close => 'Kapat';

  @override
  String get delete => 'Sil';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get remove => 'Kaldır';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get profile => 'Profil';

  @override
  String get changePassword => 'Şifreyi değiştir';

  @override
  String get currentPassword => 'Mevcut şifre';

  @override
  String get newPassword => 'Yeni şifre';

  @override
  String get passwordChanged =>
      'Şifre değiştirildi. Diğer oturumlarından çıkış yapıldı.';

  @override
  String get mustChangeTitle => 'Yeni bir şifre seç';

  @override
  String get mustChangeHelp =>
      'Yöneticin sana geçici bir şifre verdi. Devam etmek için kendi şifreni seç.';

  @override
  String get sessions => 'Oturumlar';

  @override
  String get thisDevice => 'bu cihaz';

  @override
  String get revoke => 'Çıkış yap';

  @override
  String get revokeOthers => 'Diğer tüm cihazlarda çıkış yap';

  @override
  String lastSeen(String date) {
    return 'son görülme $date';
  }

  @override
  String get twoFactor => 'İki adımlı giriş';

  @override
  String twoFactorOn(int count) {
    return 'Açık, $count kurtarma kodu kaldı';
  }

  @override
  String get twoFactorOff => 'Kapalı';

  @override
  String get enable => 'Aç';

  @override
  String get disable => 'Kapat';

  @override
  String get totpScan =>
      'Bu kodu doğrulama uygulamanla tara, sonra gösterdiği 6 haneli kodu gir.';

  @override
  String totpSecret(String secret) {
    return 'Gizli anahtar: $secret';
  }

  @override
  String get recoveryTitle => 'Kurtarma kodları';

  @override
  String get recoveryHelp =>
      'Telefonun yanında değilken her kod seni bir kez giriş yaptırır. Yalnızca şimdi gösteriliyorlar: güvenli bir yerde sakla.';

  @override
  String get passkeys => 'Geçiş anahtarları';

  @override
  String get addPasskey => 'Geçiş anahtarı ekle';

  @override
  String get noPasskeys => 'Henüz geçiş anahtarı yok.';

  @override
  String get synced => 'senkronize';

  @override
  String get passkeyName => 'Geçiş anahtarı adı';

  @override
  String get passkeyUnsupported =>
      'Bu cihazda geçiş anahtarları kullanılamıyor.';

  @override
  String get avatar => 'Avatar';

  @override
  String get uploadAvatar => 'Resim yükle';

  @override
  String get dangerZone => 'Hesabı sil';

  @override
  String get deleteAccountHelp =>
      'Hesabın ve içindeki her şey kalıcı olarak silinir.';

  @override
  String get deleteAccountConfirm => 'Hesabını silmek için şifreni gir.';

  @override
  String get users => 'Kullanıcılar';

  @override
  String get invitations => 'Davetler';

  @override
  String get settings => 'Ayarlar';

  @override
  String get auditLog => 'Denetim kaydı';

  @override
  String get search => 'Ara';

  @override
  String get newUser => 'Yeni kullanıcı';

  @override
  String get makeAdmin => 'Yönetici';

  @override
  String get disabled => 'Devre dışı';

  @override
  String get resetPassword => 'Şifreyi sıfırla';

  @override
  String get reset2fa => 'İki adımlı doğrulamayı sıfırla';

  @override
  String get temporaryPassword => 'Geçici şifre';

  @override
  String temporaryPasswordHelp(String name) {
    return 'Bunu özel olarak şu kişiye ver: $name. Yalnızca şimdi gösteriliyor ve ilk girişte değiştirilmesi gerekiyor.';
  }

  @override
  String deleteUserConfirm(String name) {
    return '$name ve hesaptaki her şey silinsin mi?';
  }

  @override
  String get newInvitation => 'Yeni davet';

  @override
  String get validHours => 'Geçerlilik (saat)';

  @override
  String get uses => 'Kullanım';

  @override
  String get note => 'Not (isteğe bağlı)';

  @override
  String get invitationLink => 'Davet bağlantısı';

  @override
  String get invitationLinkHelp =>
      'Bu bağlantıyı oyuncuya gönder. Yalnızca şimdi gösteriliyor.';

  @override
  String invitationUses(int uses, int max) {
    return '$uses/$max kullanıldı';
  }

  @override
  String get invitationRevoked => 'iptal edildi';

  @override
  String get invitationExpired => 'süresi doldu';

  @override
  String joinedBy(String names) {
    return 'Katılanlar: $names';
  }

  @override
  String get tableCreation => 'Kimler masa açabilir';

  @override
  String get everyone => 'Tüm oyuncular';

  @override
  String get adminsOnly => 'Yalnızca yöneticiler';

  @override
  String get maxUpload => 'En büyük yükleme boyutu (KiB)';

  @override
  String get loadMore => 'Daha fazla yükle';

  @override
  String get filterAction => 'İşlem (tam ad ya da noktayla biten önek)';

  @override
  String get errNetwork => 'Sunucuya ulaşılamıyor.';

  @override
  String get errNotServer =>
      'Bu adreste yanıt veren bir Oxi Poker sunucusu yok.';

  @override
  String get errBadAddress => 'poker.example.com gibi bir adres gir.';

  @override
  String get errInvalidCredentials => 'Kullanıcı adı ya da şifre yanlış.';

  @override
  String get errRateLimited => 'Çok fazla deneme. Biraz sonra tekrar dene.';

  @override
  String get errInvalidCode => 'Bu kod geçerli değil.';

  @override
  String get errChallengeExpired => 'Giriş çok uzun sürdü. Baştan başla.';

  @override
  String get errInvitationInvalid => 'Bu davet bağlantısı geçerli değil.';

  @override
  String get errInvitationExpired => 'Bu davet bağlantısının süresi doldu.';

  @override
  String get errInvitationUsed => 'Bu davet bağlantısı zaten kullanıldı.';

  @override
  String get errBadUsername =>
      'Kullanıcı adı 3 ile 32 arası harf, rakam, nokta, tire ya da alt çizgiden oluşur.';

  @override
  String get errBadDisplayName =>
      'Görünen ad 1 ile 64 karakter arasında olmalı.';

  @override
  String get errBadPassword => 'Şifre 10 ile 256 karakter arasında olmalı.';

  @override
  String get errUsernameTaken => 'Bu kullanıcı adı alınmış.';

  @override
  String get errWrongPassword => 'Şifre yanlış.';

  @override
  String get errLastAdmin => 'Sunucuda en az bir yönetici olmalı.';

  @override
  String get errSelf => 'Bunu burada kendi hesabına yapamazsın.';

  @override
  String get errTooLarge => 'Dosya çok büyük.';

  @override
  String get errBadImage => 'PNG, JPEG, GIF ya da WebP resim kullan.';

  @override
  String get errPasskeyRejected => 'Geçiş anahtarı kabul edilmedi.';

  @override
  String get errLastSignInMethod =>
      'Bu, giriş yapmanın son yolu. Önce bir şifre ya da başka bir geçiş anahtarı ekle.';

  @override
  String get errBadInvitation =>
      'Saat 1 ile 720, kullanım 1 ile 100 arası, not en fazla 200 karakter.';

  @override
  String get errBadSettings =>
      'Yükleme boyutu 256 KiB ile 20 MiB arasında olmalı.';

  @override
  String errGeneric(String code) {
    return 'Bir şeyler ters gitti ($code).';
  }

  @override
  String get handHistory => 'El geçmişi';

  @override
  String get createTable => 'Masa aç';

  @override
  String get create => 'Oluştur';

  @override
  String get noTables =>
      'Henüz açık masa yok. Bir masa aç ve arkadaşlarını davet et.';

  @override
  String get closeTable => 'Masayı kapat';

  @override
  String closeTableConfirm(String name) {
    return '$name masası kapatılsın mı? Oynanan el iptal edilir ve tüm stack\'ler önceki hâline döner.';
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
  String get connecting => 'Bağlanıyor…';

  @override
  String get reconnecting => 'Bağlantı koptu, yeniden bağlanıyor…';

  @override
  String get serverRestarting =>
      'Sunucu yeniden başlıyor. Oynanan el iptal edilir ve fişler geri verilir; masa birazdan geri gelir.';

  @override
  String get tableName => 'Masa adı';

  @override
  String get seats => 'Koltuk';

  @override
  String get smallBlind => 'Küçük blind';

  @override
  String get bigBlind => 'Büyük blind';

  @override
  String get startingStack => 'Başlangıç stack\'i';

  @override
  String get turnTime => 'Hamle süresi (saniye)';

  @override
  String get allowSpectators => 'İzleyicilere izin ver';

  @override
  String get errTableName => 'Ad 1 ile 40 karakter arasında olmalı.';

  @override
  String get errBlinds =>
      'Blind\'lar en az 1 olmalı ve küçük blind büyük blind\'dan fazla olmamalı.';

  @override
  String get errStack => 'Başlangıç stack\'i en az iki büyük blind olmalı.';

  @override
  String get errTurnTime => 'Hamle süresi 5 ile 300 saniye arasında olmalı.';

  @override
  String get wsNotYourTurn => 'Sıra sende değil.';

  @override
  String get wsSeatTaken => 'Bu koltuk az önce alındı.';

  @override
  String get wsAlreadySeated => 'Bu masada zaten bir koltuğun var.';

  @override
  String get wsIllegal => 'Bu hamle şu an yapılamaz.';

  @override
  String get wsSpectatorsOff =>
      'Bu masada izleyici yok. Katılmak için bir koltuğa otur.';

  @override
  String get table => 'Masa';

  @override
  String get sitOut => 'Mola ver';

  @override
  String get comeBack => 'Geri dön';

  @override
  String get leaveSeat => 'Koltuktan kalk';

  @override
  String get chat => 'Sohbet';

  @override
  String get tableClosed => 'Bu masa kapandı.';

  @override
  String get backToLobby => 'Lobiye dön';

  @override
  String get watchingHint => 'İzliyorsun. Oynamak için boş bir koltuk seç.';

  @override
  String get bustedHint =>
      'Fişin bitti. Yeniden buy-in yapmak için koltuk menüsünde Geri dön\'ü kullan.';

  @override
  String get sittingOutHint =>
      'Moladasın. Sonraki eli oynamak için koltuk menüsünde Geri dön\'ü kullan.';

  @override
  String get waitingForPlayers => 'Oyuncular bekleniyor';

  @override
  String get nextHandSoon => 'Sonraki el birazdan başlıyor';

  @override
  String waitingFor(String name) {
    return 'Bekleniyor: $name';
  }

  @override
  String potMain(String amount) {
    return 'Pot $amount';
  }

  @override
  String potSide(int n, String amount) {
    return 'Yan pot $n: $amount';
  }

  @override
  String wins(String name, String amount) {
    return '$name kazandı: $amount';
  }

  @override
  String get sit => 'Buraya otur';

  @override
  String get emptySeat => 'Boş';

  @override
  String get sittingOut => 'Molada';

  @override
  String get folded => 'Çekildi';

  @override
  String get allIn => 'All-in';

  @override
  String allInTo(String amount) {
    return 'All-in $amount';
  }

  @override
  String raiseTo(String amount) {
    return 'Artır: $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Bahis $amount';
  }

  @override
  String callAmount(String amount) {
    return 'Gör $amount';
  }

  @override
  String get presetMin => 'Min';

  @override
  String get presetHalfPot => '½ pot';

  @override
  String get presetPot => 'Pot';

  @override
  String get presetAllIn => 'All-in';

  @override
  String get fold => 'Çekil';

  @override
  String get check => 'Pas';

  @override
  String get bet => 'Bahis';

  @override
  String get chatNotStored => 'Oyuncular ve izleyiciler görür, asla saklanmaz.';

  @override
  String get chatHint => 'Mesaj';

  @override
  String get noHands => 'Henüz el oynanmadı.';

  @override
  String potLabel(String amount) {
    return 'pot $amount';
  }

  @override
  String evPostSb(String who, String amount) {
    return '$who küçük blind koydu: $amount';
  }

  @override
  String evPostBb(String who, String amount) {
    return '$who büyük blind koydu: $amount';
  }

  @override
  String evHole(String who, String cards) {
    return '$who kartları aldı: $cards';
  }

  @override
  String evFold(String who) {
    return '$who çekildi';
  }

  @override
  String evCheck(String who) {
    return '$who pas dedi';
  }

  @override
  String evCall(String who, String amount) {
    return '$who gördü: $amount';
  }

  @override
  String evBet(String who, String amount) {
    return '$who bahis yaptı: $amount';
  }

  @override
  String evRaise(String who, String amount) {
    return '$who artırdı: $amount';
  }

  @override
  String evReturn(String who, String amount) {
    return '$amount iade edildi: $who';
  }

  @override
  String evBoard(String street, String cards) {
    return '$street: $cards';
  }

  @override
  String evShow(String who, String cards) {
    return '$who açtı: $cards';
  }

  @override
  String evWin(String who, String amount) {
    return '$who kazandı: $amount';
  }

  @override
  String get replay => 'Tekrar izle';

  @override
  String get yourCards => 'Kartların';

  @override
  String stepOf(int step, int total) {
    return '$step/$total';
  }

  @override
  String get stats => 'İstatistiklerin';

  @override
  String get handsPlayed => 'Oynanan eller';

  @override
  String get handsWon => 'Kazanılan eller';

  @override
  String get biggestPot => 'Kazanılan en büyük pot';

  @override
  String get sngGames => 'Sit and go oyunları';

  @override
  String get sngWins => 'Sit and go galibiyetleri';

  @override
  String get sngBest => 'En iyi derece';

  @override
  String get tableKind => 'Oyun';

  @override
  String get kindCash => 'Nakit oyun';

  @override
  String get kindSng => 'Sit and go';

  @override
  String get structure => 'Blind seviyeleri';

  @override
  String structureTurbo(int min) {
    return 'Turbo, $min dk';
  }

  @override
  String structureRegular(int min) {
    return 'Normal, $min dk';
  }

  @override
  String structureSlow(int min) {
    return 'Yavaş, $min dk';
  }

  @override
  String get firstBlinds => 'İlk seviye blind\'ları';

  @override
  String sngRegistering(int n) {
    return 'Kayıt: $n kişi oturdu. Oyunu ev sahibi başlatır ya da tüm koltuklar dolunca başlar.';
  }

  @override
  String get startGame => 'Oyunu başlat';

  @override
  String sngLevel(int n, int sb, int bb) {
    return 'Seviye $n: $sb/$bb';
  }

  @override
  String sngNext(int sb, int bb, String time) {
    return 'sonraki $sb/$bb, kalan $time';
  }

  @override
  String sngNextHand(int sb, int bb) {
    return 'sonraki elden itibaren $sb/$bb';
  }

  @override
  String get sngLastLevel => 'son seviye';

  @override
  String get standings => 'Final sıralaması';

  @override
  String placeLine(int place, String name) {
    return '$place. $name';
  }

  @override
  String youFinished(int place) {
    return '$place. oldun';
  }

  @override
  String get wsSngStarted => 'Sit and go zaten başladı.';

  @override
  String get wsTooFewPlayers => 'Sit and go için en az iki oyuncu gerekir.';

  @override
  String get wsHostOnly =>
      'Bunu yalnızca ev sahibi ya da bir yönetici yapabilir.';

  @override
  String get appearance => 'Görünüm';

  @override
  String get theme => 'Tema';

  @override
  String get themeClassic => 'Klasik';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get cardBack => 'Kart arkası';

  @override
  String get serverDefault => 'Sunucu varsayılanı';

  @override
  String get defaultCardBack => 'Varsayılan kart arkası';

  @override
  String get cardBacks => 'Kart arkaları';

  @override
  String get errBadTheme => 'Bilinmeyen tema.';

  @override
  String get errBadCardBack => 'Bu kart arkası kullanılamıyor.';

  @override
  String get errCardBackDefault => 'Varsayılan kart arkası silinemez.';

  @override
  String get uploadCardBack => 'Kart arkası yükle';

  @override
  String get cardBackName => 'Kart arkası adı';

  @override
  String get errTooManyCardBacks =>
      'Çok fazla yüklenmiş kart arkası var. Önce birini sil.';

  @override
  String get chatUserMenuHint =>
      'Yazanı engellemek ya da şikâyet etmek için bir sohbet satırına dokun.';

  @override
  String get blockUser => 'Engelle';

  @override
  String get reportUser => 'Şikâyet et';

  @override
  String get muteInChat => 'Bu masanın sohbetinde sustur';

  @override
  String get unmuteInChat => 'Bu masanın sohbetinde sesini aç';

  @override
  String get removeSpectator => 'Masadan çıkar';

  @override
  String userBlocked(String name) {
    return '$name engellendi. Artık sohbet mesajlarını görmeyeceksin.';
  }

  @override
  String reportTitle(String name) {
    return 'Şikâyet et: $name';
  }

  @override
  String get reasonChat => 'Sohbet';

  @override
  String get reasonBehaviour => 'Davranış';

  @override
  String get reasonOther => 'Diğer';

  @override
  String get reportNote => 'Ne oldu? (isteğe bağlı)';

  @override
  String get reportChatHint =>
      'Bu masanın son sohbet satırları şikâyetle birlikte gider, böylece yönetici ne yazıldığını görür.';

  @override
  String get sendReport => 'Şikâyeti gönder';

  @override
  String get reportSent => 'Şikâyet sunucu yöneticisine gönderildi.';

  @override
  String get blockedUsers => 'Engellenen kullanıcılar';

  @override
  String get noBlockedUsers =>
      'Kimseyi engellemedin. Yazanı engellemek için masada bir sohbet satırına dokun.';

  @override
  String get unblock => 'Engeli kaldır';

  @override
  String get reports => 'Şikâyetler';

  @override
  String get showResolved => 'Çözülen şikâyetleri göster';

  @override
  String get noReports => 'Şikâyet yok.';

  @override
  String reportLine(String reporter, String reported) {
    return '$reporter, $reported kişisini şikâyet etti';
  }

  @override
  String resolvedBy(String name) {
    return 'çözen: $name';
  }

  @override
  String get reportNoChat => 'Bu şikâyette sohbet satırı yok.';

  @override
  String get resolve => 'Çözüldü olarak işaretle';

  @override
  String get wsMuted => 'Ev sahibi seni bu masanın sohbetinde susturdu.';

  @override
  String get wsRemoved => 'Ev sahibi seni bu masadan çıkardı.';

  @override
  String get wsIsPlayer => 'Oyuncular çıkarılamaz, yalnızca izleyiciler.';

  @override
  String get errBusy => 'Sunucu meşgul. Birazdan tekrar dene.';

  @override
  String get errBadName => 'Ad 1 ile 64 karakter arasında olmalı.';

  @override
  String get errBuiltIn => 'Yerleşik kart arkaları silinemez.';

  @override
  String get errTotpEnabled => 'İki adımlı giriş zaten açık.';

  @override
  String get errTotpNotStarted =>
      'İki adımlı doğrulama kurulumunu yeniden başlat.';

  @override
  String get errTotpNotEnabled => 'İki adımlı giriş açık değil.';

  @override
  String get errPasswordChangeRequired => 'Önce şifreni değiştir.';

  @override
  String get errTooManyTables =>
      'Sunucuda çok fazla açık masa var. Daha sonra tekrar dene.';

  @override
  String get errTooManyPasskeys =>
      'Çok fazla geçiş anahtarın var. Önce birini sil.';

  @override
  String get errTooManyBlocks =>
      'Engel listen dolu. Önce birinin engelini kaldır.';

  @override
  String get errTooManyReports =>
      'Çok fazla şikâyet gönderdin. Daha sonra tekrar dene.';

  @override
  String get errReportSelf => 'Kendini şikâyet edemezsin.';

  @override
  String get errBlockSelf => 'Kendini engelleyemezsin.';

  @override
  String get errBadReport =>
      'Bir neden seç; not en fazla 500 karakter olabilir.';

  @override
  String get errAdminOnly => 'Bunu yalnızca bir yönetici yapabilir.';

  @override
  String get errNotFound => 'Bu artık mevcut değil.';

  @override
  String get errUnauthenticated => 'Yeniden giriş yap.';

  @override
  String get errBadRequest => 'Sunucu isteği anlamadı. Uygulamayı güncelle.';

  @override
  String get errInternal => 'Sunucuda bir hata oluştu. Tekrar dene.';

  @override
  String get wsNotSeated => 'Bu masada koltuğun yok.';

  @override
  String get wsNotInHand => 'Bu elde değilsin.';

  @override
  String get wsNoTable => 'Bu masa kapandı.';

  @override
  String get wsNotSng => 'Yalnızca sit and go başlatılabilir.';

  @override
  String get wsBadChat =>
      'Sohbet satırları 1 ile 300 karakter arasında olmalı.';

  @override
  String get wsBadSeat => 'Böyle bir koltuk yok.';

  @override
  String get imagesFileType => 'Resimler';

  @override
  String get defaultTableName => 'Cuma oyunu';

  @override
  String get language => 'Dil';

  @override
  String get languageDevice => 'Cihaz dili';

  @override
  String get errMediaOff => 'Bu sunucuda ses ve görüntü ayarlanmamış.';

  @override
  String get errNotAtTable => 'Ses ve görüntü için önce masaya katılın.';
}
