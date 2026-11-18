import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../api/poker.dart';
import '../state/realtime.dart';
import '../state/session.dart';
import 'common.dart';

/// Open tables, live from the realtime connection, plus "create table".
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  late final RealtimeController _rt = ref.read(realtimeProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _rt.lobby(true));
  }

  @override
  void dispose() {
    _rt.lobby(false);
    super.dispose();
  }

  Future<void> _create() async {
    final s = await showDialog<TableSettings>(context: context, builder: (_) => const CreateTableDialog());
    if (s == null || !mounted) return;
    final t = await guard(context, ref, () => ref.read(sessionProvider.notifier).api().createTable(s));
    if (t != null && mounted) context.go('/table/${t.id}');
  }

  Future<void> _close(TableEntry t) async {
    final l = context.l;
    if (!await confirm(context, l.closeTableConfirm(t.settings.name), action: l.closeTable) || !mounted) return;
    await guard(context, ref, () => ref.read(sessionProvider.notifier).api().closeTable(t.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final user = ref.watch(sessionProvider).user!;
    final rt = ref.watch(realtimeProvider);
    final tables = rt.tables;
    return Scaffold(
      backgroundColor: felt,
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
              key: const Key('open-hands'),
              tooltip: l.handHistory,
              icon: const Icon(Icons.history),
              onPressed: () => context.go('/hands')),
          if (user.isAdmin)
            IconButton(
                key: const Key('open-admin'),
                tooltip: l.admin,
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () => context.go('/admin')),
          IconButton(
              key: const Key('open-account'),
              tooltip: l.account,
              icon: const Icon(Icons.account_circle),
              onPressed: () => context.go('/account')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-table'),
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l.createTable),
      ),
      body: Column(children: [
        LinkBanner(rt.link),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l.lobbyWelcome(user.shownName),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
        ),
        Expanded(
          child: tables == null
              ? const SizedBox.shrink()
              : tables.isEmpty
                  ? Center(child: Text(l.noTables, key: const Key('no-tables'), style: const TextStyle(color: Colors.white70)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      children: [
                        for (final t in tables)
                          Card(
                            key: Key('table-${t.id}'),
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${t.taken}/${t.settings.seats}')),
                              title: Text(t.settings.name),
                              subtitle: Text([
                                l.blinds(t.settings.smallBlind, t.settings.bigBlind),
                                l.stackLabel(t.settings.startingStack),
                                if (t.players.isNotEmpty) t.players.join(', '),
                              ].join(' \u00b7 ')),
                              onTap: () => context.go('/table/${t.id}'),
                              trailing: t.host == user.id || user.isAdmin
                                  ? IconButton(
                                      key: Key('close-${t.id}'),
                                      tooltip: l.closeTable,
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _close(t))
                                  : null,
                            ),
                          ),
                      ],
                    ),
        ),
      ]),
    );
  }
}

/// Shows that the realtime connection is down and being retried.
class LinkBanner extends StatelessWidget {
  const LinkBanner(this.link, {super.key});

  final Link link;

  @override
  Widget build(BuildContext context) => link == Link.online
      ? const SizedBox.shrink()
      : Container(
          key: const Key('link-banner'),
          width: double.infinity,
          color: const Color(0xFF5D4037),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Text(link == Link.connecting ? context.l.connecting : context.l.reconnecting,
              style: const TextStyle(color: Colors.white)),
        );
}

class CreateTableDialog extends StatefulWidget {
  const CreateTableDialog({super.key});

  @override
  State<CreateTableDialog> createState() => _CreateTableDialogState();
}

class _CreateTableDialogState extends State<CreateTableDialog> {
  final _name = TextEditingController(text: 'Friday game');
  final _sb = TextEditingController(text: '5');
  final _bb = TextEditingController(text: '10');
  final _stack = TextEditingController(text: '1000');
  final _turn = TextEditingController(text: '30');
  int _seats = 6;
  bool _spectators = true;
  String? _error;

  static final _digits = [FilteringTextInputFormatter.digitsOnly];

  void _submit() {
    final l = context.l;
    final sb = int.tryParse(_sb.text) ?? 0, bb = int.tryParse(_bb.text) ?? 0;
    final stack = int.tryParse(_stack.text) ?? 0, turn = int.tryParse(_turn.text) ?? 0;
    final name = _name.text.trim();
    String? err;
    if (name.isEmpty || name.length > 40) {
      err = l.errTableName;
    } else if (bb < 1 || sb < 1 || sb > bb) {
      err = l.errBlinds;
    } else if (stack < 2 * bb) {
      err = l.errStack;
    } else if (turn < 5 || turn > 300) {
      err = l.errTurnTime;
    }
    if (err != null) return setState(() => _error = err);
    Navigator.pop(
        context,
        TableSettings(
            name: name, seats: _seats, smallBlind: sb, bigBlind: bb, startingStack: stack, turnTime: turn, spectators: _spectators));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.createTable),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ErrorLine(_error),
          TextField(key: const Key('table-name'), controller: _name, decoration: InputDecoration(labelText: l.tableName)),
          DropdownButtonFormField<int>(
            key: const Key('table-seats'),
            initialValue: _seats,
            decoration: InputDecoration(labelText: l.seats),
            items: [for (var i = 2; i <= 9; i++) DropdownMenuItem(value: i, child: Text('$i'))],
            onChanged: (v) => setState(() => _seats = v ?? 6),
          ),
          Row(children: [
            Expanded(
                child: TextField(
                    key: const Key('table-sb'),
                    controller: _sb,
                    keyboardType: TextInputType.number,
                    inputFormatters: _digits,
                    decoration: InputDecoration(labelText: l.smallBlind))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    key: const Key('table-bb'),
                    controller: _bb,
                    keyboardType: TextInputType.number,
                    inputFormatters: _digits,
                    decoration: InputDecoration(labelText: l.bigBlind))),
          ]),
          TextField(
              key: const Key('table-stack'),
              controller: _stack,
              keyboardType: TextInputType.number,
              inputFormatters: _digits,
              decoration: InputDecoration(labelText: l.startingStack)),
          TextField(
              key: const Key('table-turn'),
              controller: _turn,
              keyboardType: TextInputType.number,
              inputFormatters: _digits,
              decoration: InputDecoration(labelText: l.turnTime)),
          SwitchListTile(
            key: const Key('table-spectators'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.allowSpectators),
            value: _spectators,
            onChanged: (v) => setState(() => _spectators = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(key: const Key('table-create'), onPressed: _submit, child: Text(l.create)),
      ],
    );
  }
}
