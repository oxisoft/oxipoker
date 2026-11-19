import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../state/session.dart';
import 'common.dart';
import 'moderation.dart';

/// Admin console: users, invitations, server settings, audit log.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
          title: Text(l.admin),
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l.users),
            Tab(key: const Key('tab-invitations'), text: l.invitations),
            Tab(key: const Key('tab-settings'), text: l.settings),
            Tab(key: const Key('tab-audit'), text: l.auditLog),
            Tab(key: const Key('tab-reports'), text: l.reports),
          ]),
        ),
        body: const TabBarView(children: [UsersTab(), InvitationsTab(), SettingsTab(), AuditTab(), ReportsTab()]),
      ),
    );
  }
}

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  final _q = TextEditingController();
  late Future<UserPage> _page;

  SessionController get _s => ref.read(sessionProvider.notifier);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _page = _s.api().adminUsers(q: _q.text.trim());

  void _refresh() {
    if (mounted) setState(_load);
  }

  Future<void> _create() async {
    final l = context.l;
    final user = TextEditingController();
    final name = TextEditingController();
    var admin = false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.newUser),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(key: const Key('new-username'), controller: user, decoration: InputDecoration(labelText: l.username)),
            TextField(controller: name, decoration: InputDecoration(labelText: l.displayNameOptional)),
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: admin,
                title: Text(l.makeAdmin),
                onChanged: (v) => set(() => admin = v ?? false)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(key: const Key('create-user'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    final r = await guard(context, ref, () => _s.api().adminCreateUser(user.text.trim(), name.text.trim(), admin));
    if (r == null || !mounted) return;
    await showSecret(context, title: l.temporaryPassword, help: l.temporaryPasswordHelp(r.$1.shownName), value: r.$2);
    _refresh();
  }

  Future<void> _act(User u, String action) async {
    final l = context.l;
    final api = _s.api();
    switch (action) {
      case 'admin':
        await guard(context, ref, () => api.adminUpdateUser(u.id, isAdmin: !u.isAdmin));
      case 'disable':
        await guard(context, ref, () => api.adminUpdateUser(u.id, disabled: !u.disabled));
      case 'password':
        final pw = await guard(context, ref, () => api.adminResetPassword(u.id));
        if (pw != null && mounted) {
          await showSecret(context, title: l.temporaryPassword, help: l.temporaryPasswordHelp(u.shownName), value: pw);
        }
      case '2fa':
        await guard(context, ref, () async {
          await api.adminReset2fa(u.id);
          return true;
        });
      case 'delete':
        if (await confirm(context, l.deleteUserConfirm(u.shownName)) && mounted) {
          await guard(context, ref, () async {
            await api.adminDeleteUser(u.id);
            return true;
          });
        }
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final me = ref.watch(sessionProvider).user;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: TextField(
              key: const Key('user-search'),
              controller: _q,
              decoration: InputDecoration(labelText: l.search, prefixIcon: const Icon(Icons.search)),
              onSubmitted: (_) => _refresh(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(key: const Key('new-user'), onPressed: _create, icon: const Icon(Icons.person_add), label: Text(l.newUser)),
        ]),
      ),
      Expanded(
        child: FutureBuilder<UserPage>(
          future: _page,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(errorText(l, snap.error!)));
            final page = snap.data;
            if (page == null) return const Center(child: CircularProgressIndicator());
            return ListView(children: [
              for (final u in page.users)
                ListTile(
                  key: Key('user-${u.username}'),
                  leading: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: u.disabled ? Theme.of(context).disabledColor : null),
                  title: Text(u.shownName),
                  subtitle: Text([
                    '@${u.username}',
                    if (u.isAdmin) l.makeAdmin,
                    if (u.disabled) l.disabled,
                  ].join(' · ')),
                  trailing: u.id == me?.id
                      ? null
                      : PopupMenuButton<String>(
                          key: Key('user-menu-${u.username}'),
                          onSelected: (a) => _act(u, a),
                          itemBuilder: (_) => [
                            CheckedPopupMenuItem(value: 'admin', checked: u.isAdmin, child: Text(l.makeAdmin)),
                            CheckedPopupMenuItem(value: 'disable', checked: u.disabled, child: Text(l.disabled)),
                            PopupMenuItem(value: 'password', child: Text(l.resetPassword)),
                            PopupMenuItem(value: '2fa', child: Text(l.reset2fa)),
                            PopupMenuItem(value: 'delete', child: Text(l.delete)),
                          ],
                        ),
                ),
            ]);
          },
        ),
      ),
    ]);
  }
}

class InvitationsTab extends ConsumerStatefulWidget {
  const InvitationsTab({super.key});

  @override
  ConsumerState<InvitationsTab> createState() => _InvitationsTabState();
}

class _InvitationsTabState extends ConsumerState<InvitationsTab> {
  late Future<List<Invitation>> _list;

  SessionController get _s => ref.read(sessionProvider.notifier);

  @override
  void initState() {
    super.initState();
    _list = _s.api().invitations();
  }

  void _refresh() {
    if (mounted) setState(() => _list = _s.api().invitations());
  }

  Future<void> _create() async {
    final l = context.l;
    final hours = TextEditingController(text: '72');
    final uses = TextEditingController(text: '1');
    final note = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.newInvitation),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: hours, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.validHours)),
          TextField(controller: uses, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.uses)),
          TextField(controller: note, decoration: InputDecoration(labelText: l.note)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(key: const Key('create-invitation'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final url = await guard(
        context,
        ref,
        () => _s.api().createInvitation(
            hours: int.tryParse(hours.text) ?? 0, uses: int.tryParse(uses.text) ?? 0, note: note.text.trim()));
    if (url == null || !mounted) return;
    await showSecret(context, title: l.invitationLink, help: l.invitationLinkHelp, value: url);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
              key: const Key('new-invitation'), onPressed: _create, icon: const Icon(Icons.link), label: Text(l.newInvitation)),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Invitation>>(
          future: _list,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(errorText(l, snap.error!)));
            final list = snap.data;
            if (list == null) return const Center(child: CircularProgressIndicator());
            return ListView(children: [
              for (final i in list)
                ListTile(
                  title: Text(i.note.isEmpty ? formatDate(context, i.createdAt) : i.note),
                  subtitle: Text([
                    l.invitationUses(i.uses, i.maxUses),
                    if (i.revokedAt != null)
                      l.invitationRevoked
                    else if (i.expiresAt != null && i.expiresAt!.isBefore(DateTime.now()))
                      l.invitationExpired
                    else
                      l.inviteExpires(formatDate(context, i.expiresAt)),
                    if (i.joined.isNotEmpty) l.joinedBy(i.joined.map((j) => j.username).join(', ')),
                  ].join(' · ')),
                  trailing: i.revokedAt == null
                      ? IconButton(
                          tooltip: l.revoke,
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            await guard(context, ref, () async {
                              await _s.api().revokeInvitation(i.id);
                              return true;
                            });
                            _refresh();
                          })
                      : null,
                ),
            ]);
          },
        ),
      ),
    ]);
  }
}

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  String? _tables;
  String? _back;
  final _upload = TextEditingController();
  bool _loaded = false;

  SessionController get _s => ref.read(sessionProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final st = await guard(context, ref, () => _s.api().settings());
      if (st != null && mounted) {
        setState(() {
          _tables = st.tableCreation;
          _back = st.cardBackDefault;
          _upload.text = '${st.maxUploadBytes ~/ 1024}';
          _loaded = true;
        });
      }
    });
  }

  Future<void> _save() async {
    final kib = int.tryParse(_upload.text.trim());
    final st = await guard(
        context, ref, () => _s.api().updateSettings(tableCreation: _tables, maxUploadBytes: kib == null ? null : kib * 1024, cardBackDefault: _back));
    if (st != null && mounted) {
      ref.invalidate(cardBacksProvider);
      toast(context, context.l.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<String>(
        initialValue: _tables,
        decoration: InputDecoration(labelText: l.tableCreation),
        items: [
          DropdownMenuItem(value: 'everyone', child: Text(l.everyone)),
          DropdownMenuItem(value: 'admins', child: Text(l.adminsOnly)),
        ],
        onChanged: (v) => setState(() => _tables = v),
      ),
      const SizedBox(height: 12),
      TextField(controller: _upload, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.maxUpload)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const Key('default-back'),
        initialValue: _back,
        decoration: InputDecoration(labelText: l.defaultCardBack),
        items: [
          for (final b in ref.watch(cardBacksProvider).value?.backs ?? const <CardBackInfo>[])
            DropdownMenuItem(
              value: b.id,
              child: Row(children: [CardBackFace(b.id, width: 18), const SizedBox(width: 8), Text(b.name)]),
            ),
        ],
        onChanged: (v) => setState(() => _back = v),
      ),
      const SizedBox(height: 16),
      Align(alignment: Alignment.centerRight, child: FilledButton(key: const Key('save-settings'), onPressed: _save, child: Text(l.save))),
      const SizedBox(height: 24),
      Text(l.cardBacks, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (final b in ref.watch(cardBacksProvider).value?.backs ?? const <CardBackInfo>[])
          Column(mainAxisSize: MainAxisSize.min, children: [
            CardBackFace(b.id, width: 50),
            SizedBox(width: 80, child: Text(b.name, textAlign: TextAlign.center, maxLines: 2, style: Theme.of(context).textTheme.bodySmall)),
            if (!b.builtIn)
              IconButton(
                key: Key('delete-back-${b.id}'),
                tooltip: l.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await guard(context, ref, () async {
                    await _s.api().adminDeleteCardBack(b.id);
                    return true;
                  });
                  if (ok == true) ref.invalidate(cardBacksProvider);
                },
              ),
          ]),
      ]),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(key: const Key('upload-back'), onPressed: _uploadBack, icon: const Icon(Icons.upload), label: Text(l.uploadCardBack)),
      ),
      const SizedBox(height: 24),
      Text(l.connectionCheck, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final c in _check?.checks ?? const <MediaCheck>[]) _checkTile(context, c),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          key: const Key('run-media-check'),
          onPressed: _checking ? null : _runCheck,
          icon: _checking
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.network_check),
          label: Text(l.runConnectionCheck),
        ),
      ),
    ]);
  }

  MediaCheckReport? _check;
  bool _checking = false;

  Future<void> _runCheck() async {
    setState(() => _checking = true);
    final rep = await guard(context, ref, () => _s.api().mediaCheck());
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (rep != null) _check = rep;
    });
  }

  Widget _checkTile(BuildContext context, MediaCheck c) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, status) = switch (c.status) {
      'ok' => (Icons.check_circle, Colors.green, l.checkOk),
      'failed' => (Icons.error, scheme.error, l.checkFailed),
      _ => (Icons.remove_circle_outline, scheme.outline, l.checkSkipped),
    };
    final title = switch (c.name) {
      'signalling' => l.checkSignalling,
      'token' => l.checkToken,
      'turn_tls' => l.checkTurn,
      _ => c.name,
    };
    return ListTile(
      key: Key('media-check-${c.name}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text('$title: $status'),
      subtitle: Text(c.target.isEmpty ? c.detail : '${c.target}\n${c.detail}'),
      isThreeLine: c.target.isNotEmpty,
    );
  }

  Future<void> _uploadBack() async {
    final l = context.l;
    final file = await openFile(acceptedTypeGroups: [
      XTypeGroup(label: l.imagesFileType, extensions: ['png', 'jpg', 'jpeg', 'webp'], mimeTypes: ['image/png', 'image/jpeg', 'image/webp']),
    ]);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    var base = file.name.contains('.') ? file.name.substring(0, file.name.lastIndexOf('.')) : file.name;
    if (base.length > 40) base = base.substring(0, 40);
    final name = await prompt(context, l.cardBackName, initial: base);
    if (name == null || !mounted) return;
    final b = await guard(context, ref, () => _s.api().adminAddCardBack(name.trim(), bytes));
    if (b != null) ref.invalidate(cardBacksProvider);
  }
}

class AuditTab extends ConsumerStatefulWidget {
  const AuditTab({super.key});

  @override
  ConsumerState<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<AuditTab> {
  final _action = TextEditingController();
  final List<AuditEvent> _events = [];
  bool _busy = false;
  bool _more = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final page = await guard(
        context,
        ref,
        () => ref
            .read(sessionProvider.notifier)
            .api()
            .audit(action: _action.text.trim(), before: reset || _events.isEmpty ? null : _events.last.id));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (page == null) return;
      if (reset) _events.clear();
      _events.addAll(page);
      _more = page.length >= 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _action,
          decoration: InputDecoration(labelText: l.filterAction, prefixIcon: const Icon(Icons.filter_list)),
          onSubmitted: (_) => _load(reset: true),
        ),
      ),
      Expanded(
        child: ListView(children: [
          for (final e in _events)
            ListTile(
              dense: true,
              title: Text('${e.action}${e.target.isEmpty ? '' : ' · ${e.target}'}'),
              subtitle: Text([formatDate(context, e.at), e.actorName, e.ip, e.detail].where((s) => s.isNotEmpty).join(' · ')),
            ),
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          if (!_busy && _more && _events.isNotEmpty)
            Center(child: TextButton(onPressed: _load, child: Text(l.loadMore))),
        ]),
      ),
    ]);
  }
}
