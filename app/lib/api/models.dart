import 'dart:convert';
import 'dart:typed_data';

DateTime? _time(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// Server health as reported by GET /api/v1/health.
class ServerInfo {
  const ServerInfo({required this.version, required this.media});

  final String version;
  final bool media;

  factory ServerInfo.fromJson(Map<String, dynamic> j) =>
      ServerInfo(version: j['version'] as String? ?? '?', media: j['media'] as bool? ?? false);
}

class User {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.isAdmin = false,
    this.avatar,
    this.theme = 'classic',
    this.cardBack = '',
    this.mustChangePassword = false,
    this.disabledAt,
  });

  final String id;
  final String username;
  final String displayName;
  final bool isAdmin;
  final String? avatar;
  final String theme;
  final String cardBack; // '' = the server default
  final bool mustChangePassword;
  final DateTime? disabledAt;

  bool get disabled => disabledAt != null;
  String get shownName => displayName.isEmpty ? username : displayName;

  factory User.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return User(
      id: j['id'] as String,
      username: j['username'] as String,
      displayName: j['display_name'] as String? ?? '',
      isAdmin: j['is_admin'] as bool? ?? false,
      avatar: j['avatar'] as String?,
      theme: j['theme'] as String? ?? 'classic',
      cardBack: j['card_back'] as String? ?? '',
      mustChangePassword: j['must_change_password'] as bool? ?? false,
      disabledAt: _time(j['disabled_at']),
    );
  }
}

class UserPage {
  const UserPage(this.users, this.total);

  final List<User> users;
  final int total;

  factory UserPage.fromJson(dynamic j) =>
      UserPage((j['users'] as List).map(User.fromJson).toList(), j['total'] as int? ?? 0);
}

class InvitationInfo {
  const InvitationInfo({required this.expiresAt, required this.note, required this.passkeys});

  final DateTime? expiresAt;
  final String note;
  final bool passkeys;

  factory InvitationInfo.fromJson(dynamic j) => InvitationInfo(
        expiresAt: _time(j['expires_at']),
        note: j['note'] as String? ?? '',
        passkeys: j['passkeys'] as bool? ?? false,
      );
}

class Joined {
  const Joined(this.username, this.displayName, this.joinedAt);

  final String username;
  final String displayName;
  final DateTime? joinedAt;
}

class Invitation {
  const Invitation({
    required this.id,
    required this.note,
    required this.maxUses,
    required this.uses,
    this.createdAt,
    this.expiresAt,
    this.revokedAt,
    this.createdBy = '',
    this.joined = const [],
  });

  final String id;
  final String note;
  final int maxUses;
  final int uses;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String createdBy;
  final List<Joined> joined;

  bool get active =>
      revokedAt == null && uses < maxUses && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory Invitation.fromJson(Map<String, dynamic> j) => Invitation(
        id: j['id'] as String,
        note: j['note'] as String? ?? '',
        maxUses: j['max_uses'] as int? ?? 1,
        uses: j['uses'] as int? ?? 0,
        createdAt: _time(j['created_at']),
        expiresAt: _time(j['expires_at']),
        revokedAt: _time(j['revoked_at']),
        createdBy: j['created_by'] as String? ?? '',
        joined: ((j['joined'] as List?) ?? const [])
            .map((e) => Joined(e['username'] as String, e['display_name'] as String? ?? '', _time(e['joined_at'])))
            .toList(),
      );
}

class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.kind,
    this.lastSeenAt,
    this.ip = '',
    this.userAgent = '',
    this.current = false,
  });

  final String id;
  final String kind;
  final DateTime? lastSeenAt;
  final String ip;
  final String userAgent;
  final bool current;

  factory SessionInfo.fromJson(Map<String, dynamic> j) => SessionInfo(
        id: j['id'] as String,
        kind: j['kind'] as String? ?? '',
        lastSeenAt: _time(j['last_seen_at']),
        ip: j['ip'] as String? ?? '',
        userAgent: j['user_agent'] as String? ?? '',
        current: j['current'] as bool? ?? false,
      );
}

class TotpStatus {
  const TotpStatus(this.enabled, this.recoveryCodesLeft);

  final bool enabled;
  final int recoveryCodesLeft;

  factory TotpStatus.fromJson(dynamic j) =>
      TotpStatus(j['enabled'] as bool? ?? false, j['recovery_codes_left'] as int? ?? 0);
}

class TotpEnrollment {
  const TotpEnrollment(this.secret, this.url, this.qrPng);

  final String secret;
  final String url;
  final Uint8List qrPng;

  factory TotpEnrollment.fromJson(dynamic j) => TotpEnrollment(
        j['secret'] as String,
        j['otpauth_url'] as String? ?? '',
        base64Decode(j['qr_png'] as String? ?? ''),
      );
}

class PasskeyInfo {
  const PasskeyInfo({required this.id, required this.name, this.createdAt, this.lastUsedAt, this.synced = false});

  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final bool synced;

  factory PasskeyInfo.fromJson(Map<String, dynamic> j) => PasskeyInfo(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        createdAt: _time(j['created_at']),
        lastUsedAt: _time(j['last_used_at']),
        synced: j['synced'] as bool? ?? false,
      );
}

class ServerSettings {
  const ServerSettings(this.tableCreation, this.maxUploadBytes, [this.cardBackDefault = 'classic-red']);

  final String tableCreation;
  final int maxUploadBytes;
  final String cardBackDefault;

  factory ServerSettings.fromJson(dynamic j) => ServerSettings(j['table_creation'] as String? ?? 'everyone',
      j['max_upload_bytes'] as int? ?? 0, j['card_back_default'] as String? ?? 'classic-red');
}

class CardBackInfo {
  const CardBackInfo(this.id, this.name, {this.theme = '', this.builtIn = false});

  final String id;
  final String name;
  final String theme;
  final bool builtIn;

  factory CardBackInfo.fromJson(dynamic j) => CardBackInfo(j['id'] as String, j['name'] as String? ?? '',
      theme: j['theme'] as String? ?? '', builtIn: j['built_in'] as bool? ?? false);
}

class CardBackList {
  const CardBackList(this.defaultId, this.backs);

  final String defaultId;
  final List<CardBackInfo> backs;

  factory CardBackList.fromJson(dynamic j) => CardBackList(j['default'] as String? ?? 'classic-red',
      [for (final b in (j['card_backs'] as List? ?? const [])) CardBackInfo.fromJson(b)]);
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    this.at,
    this.actorName = '',
    required this.action,
    this.target = '',
    this.ip = '',
    this.detail = '',
  });

  final int id;
  final DateTime? at;
  final String actorName;
  final String action;
  final String target;
  final String ip;
  final String detail;

  factory AuditEvent.fromJson(Map<String, dynamic> j) => AuditEvent(
        id: (j['id'] as num).toInt(),
        at: _time(j['at']),
        actorName: j['actor_name'] as String? ?? '',
        action: j['action'] as String? ?? '',
        target: j['target'] as String? ?? '',
        ip: j['ip'] as String? ?? '',
        detail: j['detail'] is String ? j['detail'] as String : (j['detail'] == null ? '' : jsonEncode(j['detail'])),
      );
}

/// Splits an invitation link `<server>/invite#<token>` into server and token.
/// Returns null when [text] is not such a link.
(Uri, String)? parseInviteLink(String text) {
  final u = Uri.tryParse(text.trim());
  if (u == null || !u.hasScheme || u.host.isEmpty) return null;
  if (!u.path.endsWith('/invite') || u.fragment.isEmpty) return null;
  final base = u.path.substring(0, u.path.length - '/invite'.length);
  return (Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : null, path: base), u.fragment);
}

/// Normalises what a player typed as a server address: adds https:// when no
/// scheme is given and drops any path, query or fragment.
Uri? parseServerAddress(String text) {
  var t = text.trim();
  if (t.isEmpty) return null;
  if (!t.contains('://')) t = 'https://$t';
  final u = Uri.tryParse(t);
  if (u == null || u.host.isEmpty || (u.scheme != 'https' && u.scheme != 'http')) return null;
  return Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : null);
}
