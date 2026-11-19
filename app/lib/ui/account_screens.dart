import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../passkey/passkey.dart';
import '../state/locale.dart';
import '../state/session.dart';
import 'common.dart';
import 'history_screens.dart';
import 'moderation.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late final _name = TextEditingController(text: ref.read(sessionProvider).user?.displayName ?? '');
  final _current = TextEditingController();
  final _next = TextEditingController();
  late Future<List<SessionInfo>> _sessions;
  late Future<TotpStatus> _totp;
  late Future<List<PasskeyInfo>> _passkeys;

  SessionController get _s => ref.read(sessionProvider.notifier);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _sessions = _s.api().sessions();
    _totp = _s.api().totpStatus();
    _passkeys = _s.api().passkeys();
  }

  Future<void> _addPasskey() async {
    final l = context.l;
    final name = await prompt(context, l.passkeyName, initial: 'Passkey');
    if (name == null || !mounted) return;
    try {
      final api = _s.api();
      final b = await api.passkeyAddBegin();
      final cred = await ref.read(passkeyProvider).create(b['options'] as Map<String, dynamic>);
      await api.passkeyAddFinish(b['ceremony'] as String, cred, name.trim());
    } on PasskeyCancelled {
      return;
    } catch (e) {
      if (mounted) toast(context, errorText(l, e));
    }
    if (mounted) setState(_reload);
  }

  Future<void> _saveName() async {
    final u = await guard(context, ref, () => _s.api().setDisplayName(_name.text.trim()));
    if (u != null && mounted) {
      _s.updateUser(u);
      toast(context, context.l.saved);
    }
  }

  Future<void> _changePassword() async {
    final ok = await guard(context, ref, () async {
      await _s.api().changePassword(_current.text, _next.text);
      return true;
    });
    if (ok == true && mounted) {
      _current.clear();
      _next.clear();
      toast(context, context.l.passwordChanged);
      setState(_reload);
    }
  }

  Future<void> _enableTotp() async {
    final l = context.l;
    final e = await guard(context, ref, () => _s.api().totpBegin());
    if (e == null || !mounted) return;
    final code = TextEditingController();
    final codes = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.twoFactor),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.totpScan),
            const SizedBox(height: 12),
            if (e.qrPng.isNotEmpty) Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.memory(e.qrPng, width: 200)),
            SelectableText(l.totpSecret(e.secret)),
            TextField(key: const Key('totp-confirm-field'), controller: code, decoration: InputDecoration(labelText: l.code)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () async {
              final r = await guard(ctx, ref, () => _s.api().totpConfirm(code.text.trim()));
              if (r != null && ctx.mounted) Navigator.pop(ctx, r);
            },
            child: Text(l.verify),
          ),
        ],
      ),
    );
    if (codes != null && mounted) {
      await showSecret(context, title: l.recoveryTitle, help: l.recoveryHelp, value: codes.join('\n'));
    }
    if (mounted) setState(_reload);
  }

  Future<void> _disableTotp() async {
    final code = await prompt(context, context.l.code);
    if (code == null || !mounted) return;
    await guard(context, ref, () => _s.api().totpDisable(code.trim()));
    if (mounted) setState(_reload);
  }

  Future<void> _deleteAccount() async {
    final l = context.l;
    final pw = await prompt(context, l.deleteAccountConfirm, obscure: true);
    if (pw == null || !mounted) return;
    final ok = await guard(context, ref, () async {
      await _s.api().deleteAccount(pw);
      return true;
    });
    if (ok == true) await _s.expired();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final user = ref.watch(sessionProvider).user;
    if (user == null) return const SizedBox.shrink();
    Widget section(String title, List<Widget> children) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...children,
            ]),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: Text(l.account),
        actions: [
          TextButton(key: const Key('sign-out'), onPressed: () => _s.signOut(), child: Text(l.signOut)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const StatsCard(),
            section(l.profile, [
              Text('@${user.username}'),
              const SizedBox(height: 8),
              TextField(key: const Key('display-name-field'), controller: _name, decoration: InputDecoration(labelText: l.displayName)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _saveName, child: Text(l.save))),
            ]),
            section(l.appearance, [const AppearancePicker()]),
            section(l.language, [const LanguagePicker()]),
            section(l.blockedUsers, [const BlockList()]),
            section(l.changePassword, [
              TextField(controller: _current, obscureText: true, decoration: InputDecoration(labelText: l.currentPassword)),
              TextField(controller: _next, obscureText: true, decoration: InputDecoration(labelText: l.newPassword)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _changePassword, child: Text(l.save))),
            ]),
            section(l.twoFactor, [
              FutureBuilder<TotpStatus>(
                future: _totp,
                builder: (context, snap) {
                  final t = snap.data;
                  if (t == null) return const LinearProgressIndicator();
                  return Row(children: [
                    Expanded(child: Text(t.enabled ? l.twoFactorOn(t.recoveryCodesLeft) : l.twoFactorOff)),
                    t.enabled
                        ? OutlinedButton(onPressed: _disableTotp, child: Text(l.disable))
                        : FilledButton(key: const Key('totp-enable'), onPressed: _enableTotp, child: Text(l.enable)),
                  ]);
                },
              ),
            ]),
            section(l.passkeys, [
              FutureBuilder<List<PasskeyInfo>>(
                future: _passkeys,
                builder: (context, snap) {
                  final list = snap.data;
                  if (list == null) return const LinearProgressIndicator();
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (list.isEmpty) Text(l.noPasskeys),
                    for (final p in list)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.key),
                        title: Text(p.name),
                        subtitle: Text([
                          formatDate(context, p.createdAt),
                          if (p.lastUsedAt != null) l.lastSeen(formatDate(context, p.lastUsedAt)),
                          if (p.synced) l.synced,
                        ].join(' · ')),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: l.rename,
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final n = await prompt(context, l.passkeyName, initial: p.name);
                              if (n == null || !context.mounted) return;
                              await guard(context, ref, () async {
                                await _s.api().renamePasskey(p.id, n.trim());
                                return true;
                              });
                              if (mounted) setState(_reload);
                            },
                          ),
                          IconButton(
                            tooltip: l.remove,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await guard(context, ref, () async {
                                await _s.api().removePasskey(p.id);
                                return true;
                              });
                              if (mounted) setState(_reload);
                            },
                          ),
                        ]),
                      ),
                    const SizedBox(height: 8),
                    ref.watch(passkeyProvider).available
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                                key: const Key('add-passkey'),
                                onPressed: _addPasskey,
                                icon: const Icon(Icons.add),
                                label: Text(l.addPasskey)),
                          )
                        : Text(l.passkeyUnsupported),
                  ]);
                },
              ),
            ]),
            section(l.sessions, [
              FutureBuilder<List<SessionInfo>>(
                future: _sessions,
                builder: (context, snap) {
                  final list = snap.data;
                  if (list == null) return const LinearProgressIndicator();
                  return Column(children: [
                    for (final s in list)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.userAgent.isEmpty ? s.kind : s.userAgent, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text([s.ip, l.lastSeen(formatDate(context, s.lastSeenAt)), if (s.current) l.thisDevice].join(' · ')),
                        trailing: s.current
                            ? null
                            : TextButton(
                                onPressed: () async {
                                  await guard(context, ref, () => _s.api().revokeSession(s.id));
                                  if (mounted) setState(_reload);
                                },
                                child: Text(l.revoke)),
                      ),
                    if (list.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () async {
                            await guard(context, ref, () => _s.api().revokeOtherSessions());
                            if (mounted) setState(_reload);
                          },
                          child: Text(l.revokeOthers),
                        ),
                      ),
                  ]);
                },
              ),
            ]),
            section(l.dangerZone, [
              Text(l.deleteAccountHelp),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: _deleteAccount,
                  child: Text(l.delete),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Theme switch and card back choice, both stored on the account.
class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final user = ref.watch(sessionProvider).user;
    if (user == null) return const SizedBox.shrink();
    final s = ref.read(sessionProvider.notifier);
    Future<void> save({String? theme, String? cardBack}) async {
      final u = await guard(context, ref, () => s.api().setAppearance(theme: theme, cardBack: cardBack));
      if (u != null) s.updateUser(u);
    }

    final backs = ref.watch(cardBacksProvider).value;
    Widget choice(String id, String label, {required bool selected, required String value}) => InkWell(
          key: Key('pick-back-${value.isEmpty ? 'default' : value}'),
          onTap: () => save(cardBack: value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CardBackFace(id, width: 44),
              const SizedBox(height: 4),
              SizedBox(width: 72, child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.theme),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        key: const Key('theme-picker'),
        segments: [
          ButtonSegment(value: themeClassic, label: Text(l.themeClassic)),
          ButtonSegment(value: themeCyberpunk, label: Text(l.themeCyberpunk)),
        ],
        selected: {user.theme == themeCyberpunk ? themeCyberpunk : themeClassic},
        onSelectionChanged: (v) => save(theme: v.first),
      ),
      const SizedBox(height: 16),
      Text(l.cardBack),
      const SizedBox(height: 8),
      if (backs == null)
        const LinearProgressIndicator()
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          choice(backs.defaultId, l.serverDefault, selected: user.cardBack.isEmpty, value: ''),
          for (final b in backs.backs) choice(b.id, b.name, selected: user.cardBack == b.id, value: b.id),
        ]),
    ]);
  }
}

/// Language of the app on this device; "device language" follows the system.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final current = ref.watch(localeProvider)?.languageCode;
    return DropdownButton<String>(
      key: const Key('language-picker'),
      isExpanded: true,
      value: current ?? '',
      items: [
        DropdownMenuItem(key: const Key('language-device'), value: '', child: Text(l.languageDevice)),
        for (final e in appLanguages.entries)
          DropdownMenuItem(key: Key('language-${e.key}'), value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => ref.read(localeProvider.notifier).set(v == null || v.isEmpty ? null : v),
    );
  }
}
