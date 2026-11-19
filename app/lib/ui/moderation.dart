import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../api/poker.dart';
import '../l10n/app_localizations.dart';
import '../state/realtime.dart';
import '../state/session.dart';
import 'common.dart';
import 'table_screen.dart' show intentError;

/// What a tap on someone's chat line offers: block and report for everyone,
/// mute and remove for the table host and admins.
Future<void> showChatUserMenu(BuildContext context, WidgetRef ref, ChatMessage m) async {
  final l = context.l;
  final me = ref.read(sessionProvider).user;
  final rt = ref.read(realtimeProvider);
  final view = rt.view;
  if (me == null || m.user == me.id || m.user.isEmpty) return;
  final moderator = view != null && (view.host == me.id || me.isAdmin);
  final muted = rt.muted.contains(m.user);
  final seated = view?.seats.any((s) => s?.user == m.user) ?? false;
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(m.name), subtitle: Text(l.chatUserMenuHint)),
        ListTile(
          key: const Key('chat-block'),
          leading: const Icon(Icons.block),
          title: Text(l.blockUser),
          onTap: () => Navigator.pop(ctx, 'block'),
        ),
        ListTile(
          key: const Key('chat-report'),
          leading: const Icon(Icons.flag),
          title: Text(l.reportUser),
          onTap: () => Navigator.pop(ctx, 'report'),
        ),
        if (moderator)
          ListTile(
            key: const Key('chat-mute'),
            leading: Icon(muted ? Icons.volume_up : Icons.volume_off),
            title: Text(muted ? l.unmuteInChat : l.muteInChat),
            onTap: () => Navigator.pop(ctx, muted ? 'unmute' : 'mute'),
          ),
        if (moderator && !seated)
          ListTile(
            key: const Key('chat-remove'),
            leading: const Icon(Icons.logout),
            title: Text(l.removeSpectator),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
      ]),
    ),
  );
  if (choice == null || !context.mounted) return;
  final rtc = ref.read(realtimeProvider.notifier);
  switch (choice) {
    case 'block':
      final ok = await guard(context, ref, () async {
        await ref.read(sessionProvider.notifier).api().block(m.user);
        return true;
      });
      if (ok == null || !context.mounted) return;
      rtc.hideChatOf(m.user);
      toast(context, l.userBlocked(m.name));
    case 'report':
      await showReportDialog(context, ref, userId: m.user, name: m.name, tableId: view?.id);
    case 'mute' || 'unmute' || 'remove':
      final err = choice == 'remove' ? await rtc.removeSpectator(m.user) : await rtc.mute(m.user, choice == 'mute');
      if (!context.mounted) return;
      if (err != null) toast(context, intentError(l, err));
  }
}

/// Report a user: reason, optional note. The server attaches the table's
/// last chat lines itself.
Future<void> showReportDialog(BuildContext context, WidgetRef ref, {required String userId, required String name, String? tableId}) async {
  final l = context.l;
  final note = TextEditingController();
  var reason = 'chat';
  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.reportTitle(name)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<String>(
            key: const Key('report-reason'),
            segments: [
              ButtonSegment(value: 'chat', label: Text(l.reasonChat)),
              ButtonSegment(value: 'behaviour', label: Text(l.reasonBehaviour)),
              ButtonSegment(value: 'other', label: Text(l.reasonOther)),
            ],
            selected: {reason},
            onSelectionChanged: (s) => setState(() => reason = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('report-note'),
            controller: note,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.reportNote),
          ),
          Text(l.reportChatHint, style: Theme.of(ctx).textTheme.bodySmall),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(key: const Key('report-send'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.sendReport)),
        ],
      ),
    ),
  );
  if (send != true || !context.mounted) return;
  final ok = await guard(context, ref,
      () async {
    await ref.read(sessionProvider.notifier).api().report(userId, reason: reason, note: note.text.trim(), table: tableId);
    return true;
  });
  if (ok != null && context.mounted) toast(context, l.reportSent);
}

/// The block list on the account screen.
class BlockList extends ConsumerStatefulWidget {
  const BlockList({super.key});

  @override
  ConsumerState<BlockList> createState() => _BlockListState();
}

class _BlockListState extends ConsumerState<BlockList> {
  late Future<List<BlockedUser>> _blocks = _load();

  Future<List<BlockedUser>> _load() => ref.read(sessionProvider.notifier).api().blocks();

  Future<void> _unblock(BlockedUser b) async {
    final ok = await guard(context, ref, () async {
      await ref.read(sessionProvider.notifier).api().unblock(b.id);
      return true;
    });
    if (ok == null || !mounted) return;
    setState(() => _blocks = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FutureBuilder<List<BlockedUser>>(
      future: _blocks,
      builder: (context, snap) {
        final bs = snap.data;
        if (bs == null) return const Center(child: CircularProgressIndicator());
        if (bs.isEmpty) return Text(l.noBlockedUsers, key: const Key('no-blocks'));
        return Column(children: [
          for (final b in bs)
            ListTile(
              key: Key('blocked-${b.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(b.displayName.isEmpty ? b.username : b.displayName),
              subtitle: Text('@${b.username}'),
              trailing: TextButton(key: Key('unblock-${b.id}'), onPressed: () => _unblock(b), child: Text(l.unblock)),
            ),
        ]);
      },
    );
  }
}

/// Admin console: reports from users with their chat context.
class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  bool _all = false;
  late Future<List<ReportInfo>> _reports = _load();

  Future<List<ReportInfo>> _load() => ref.read(sessionProvider.notifier).api().adminReports(all: _all);

  void _reload() => setState(() => _reports = _load());

  Future<void> _resolve(ReportInfo r) async {
    final ok = await guard(context, ref, () async {
      await ref.read(sessionProvider.notifier).api().resolveReport(r.id);
      return true;
    });
    if (ok != null && mounted) _reload();
  }

  String _reason(AppLocalizations l, String r) => switch (r) {
    'chat' => l.reasonChat,
    'behaviour' => l.reasonBehaviour,
    _ => l.reasonOther,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(children: [
      SwitchListTile(
        key: const Key('reports-all'),
        title: Text(l.showResolved),
        value: _all,
        onChanged: (v) {
          _all = v;
          _reload();
        },
      ),
      Expanded(
        child: FutureBuilder<List<ReportInfo>>(
          future: _reports,
          builder: (context, snap) {
            final rs = snap.data;
            if (rs == null) return const Center(child: CircularProgressIndicator());
            if (rs.isEmpty) return Center(child: Text(l.noReports));
            return ListView(children: [
              for (final r in rs)
                ExpansionTile(
                  key: Key('report-${r.id}'),
                  title: Text(l.reportLine(r.reporter, r.reported)),
                  subtitle: Text([
                    formatDate(context, r.createdAt),
                    _reason(l, r.reason),
                    if (r.tableName.isNotEmpty) r.tableName,
                    if (r.resolvedAt != null) l.resolvedBy(r.resolvedBy),
                  ].join(' · ')),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.note.isNotEmpty) Text(r.note),
                    const SizedBox(height: 8),
                    if (r.chat.isEmpty) Text(l.reportNoChat),
                    for (final c in r.chat)
                      Text('${c.name}: ${c.text}',
                          style: c.user == r.reportedId ? const TextStyle(fontWeight: FontWeight.bold) : null),
                    if (r.resolvedAt == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(key: Key('resolve-${r.id}'), onPressed: () => _resolve(r), child: Text(l.resolve)),
                      ),
                  ],
                ),
            ]);
          },
        ),
      ),
    ]);
  }
}
