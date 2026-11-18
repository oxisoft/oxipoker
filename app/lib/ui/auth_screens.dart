import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../passkey/passkey.dart';
import '../state/session.dart';
import 'common.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: felt, body: Center(child: CircularProgressIndicator()));
}

/// Native apps only: pick the server, by address or by pasting an invitation link.
class ServerScreen extends ConsumerStatefulWidget {
  const ServerScreen({super.key});

  @override
  ConsumerState<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends ConsumerState<ServerScreen> {
  final _address = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _connect() async {
    final l = context.l;
    final invite = parseInviteLink(_address.text);
    final server = invite?.$1 ?? parseServerAddress(_address.text);
    if (server == null) {
      setState(() => _error = l.errBadAddress);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).connect(server, inviteToken: invite?.$2);
    } on ApiException {
      setState(() => _error = l.errNotServer);
    } catch (_) {
      setState(() => _error = l.errNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FormPage(title: l.serverTitle, children: [
      Text(l.serverHelp),
      const SizedBox(height: 16),
      TextField(
        key: const Key('server-field'),
        controller: _address,
        keyboardType: TextInputType.url,
        autocorrect: false,
        decoration: InputDecoration(labelText: l.serverHint),
        onSubmitted: (_) => _connect(),
      ),
      const SizedBox(height: 16),
      ErrorLine(_error),
      BusyButton(key: const Key('connect'), label: l.connect, busy: _busy, onPressed: _connect),
    ]);
  }
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _code = TextEditingController();
  String? _challenge;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<SignInResult> Function(Api api) step) async {
    final s = ref.read(sessionProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await step(s.api());
      if (r.needsTotp) {
        setState(() => _challenge = r.totpChallenge);
      } else {
        await s.signedIn(r);
      }
    } on PasskeyCancelled {
      // The player closed the prompt: nothing to say.
    } catch (e) {
      if (e is ApiException && e.code == 'challenge_expired') _challenge = null;
      if (mounted) setState(() => _error = errorText(context.l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final native = ref.watch(nativeProvider);
    if (_challenge != null) {
      return FormPage(title: l.totpTitle, children: [
        Text(l.totpHelp),
        const SizedBox(height: 16),
        TextField(
          key: const Key('totp-field'),
          controller: _code,
          autofocus: true,
          autocorrect: false,
          decoration: InputDecoration(labelText: l.code),
          onSubmitted: (_) => _run((a) => a.totp(_challenge!, _code.text.trim())),
        ),
        const SizedBox(height: 16),
        ErrorLine(_error),
        BusyButton(
            key: const Key('verify'),
            label: l.verify,
            busy: _busy,
            onPressed: () => _run((a) => a.totp(_challenge!, _code.text.trim()))),
        TextButton(onPressed: () => setState(() => _challenge = null), child: Text(l.back)),
      ]);
    }
    void submit() => _run((a) => a.signIn(_user.text.trim(), _pass.text));
    return FormPage(title: l.signInTitle, children: [
      TextField(
        key: const Key('username-field'),
        controller: _user,
        autocorrect: false,
        autofillHints: const [AutofillHints.username],
        decoration: InputDecoration(labelText: l.username),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('password-field'),
        controller: _pass,
        obscureText: true,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(labelText: l.password),
        onSubmitted: (_) => submit(),
      ),
      const SizedBox(height: 16),
      ErrorLine(_error),
      BusyButton(key: const Key('sign-in'), label: l.signIn, busy: _busy, onPressed: submit),
      if (ref.watch(passkeyProvider).available) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('sign-in-passkey'),
          icon: const Icon(Icons.key),
          label: Text(l.signInPasskey),
          onPressed: _busy
              ? null
              : () => _run((a) async {
                    final b = await a.passkeySignInBegin();
                    final cred = await ref.read(passkeyProvider).get(b['options'] as Map<String, dynamic>);
                    return a.passkeySignInFinish(b['ceremony'] as String, cred);
                  }),
        ),
      ],
      if (native)
        TextButton(
          onPressed: () => ref.read(sessionProvider.notifier).forgetServer(),
          child: Text(l.changeServer),
        ),
    ]);
  }
}

/// Sign-up through an invitation link.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _user = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  late Future<InvitationInfo> _info;
  bool _busy = false;
  String? _error;

  String get _token => ref.read(sessionProvider).inviteToken ?? '';

  @override
  void initState() {
    super.initState();
    _info = ref.read(sessionProvider.notifier).api().checkInvitation(_token);
  }

  Future<void> _signUp() async {
    final l = context.l;
    if (_pass.text != _pass2.text) {
      setState(() => _error = l.passwordsDiffer);
      return;
    }
    final s = ref.read(sessionProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await s.signedIn(await s.api().signUp(_token, _user.text.trim(), _name.text.trim(), _pass.text));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUpPasskey() async {
    final l = context.l;
    final s = ref.read(sessionProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = s.api();
      final b = await api.signUpPasskeyBegin(_token, _user.text.trim(), _name.text.trim());
      final cred = await ref.read(passkeyProvider).create(b['options'] as Map<String, dynamic>);
      await s.signedIn(await api.signUpPasskeyFinish(b['ceremony'] as String, cred));
    } on PasskeyCancelled {
      // Prompt closed.
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final passkeys = ref.watch(passkeyProvider).available;
    return FutureBuilder<InvitationInfo>(
      future: _info,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const SplashScreen();
        if (snap.hasError) {
          return FormPage(title: l.inviteTitle, children: [
            ErrorLine(errorText(l, snap.error!)),
            FilledButton(onPressed: () => ref.read(sessionProvider.notifier).setInvite(null), child: Text(l.signIn)),
          ]);
        }
        final info = snap.data!;
        return FormPage(title: l.inviteTitle, children: [
          if (info.note.isNotEmpty) Text(l.inviteNote(info.note)),
          if (info.expiresAt != null) Text(l.inviteExpires(formatDate(context, info.expiresAt))),
          const SizedBox(height: 16),
          TextField(
            key: const Key('username-field'),
            controller: _user,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.username),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('display-name-field'),
            controller: _name,
            decoration: InputDecoration(labelText: l.displayNameOptional),
          ),
          if (passkeys && info.passkeys) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('sign-up-passkey'),
              icon: const Icon(Icons.key),
              label: Text(l.createWithPasskey),
              onPressed: _busy ? null : _signUpPasskey,
            ),
            const SizedBox(height: 12),
            Text(l.orPassword, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('password-field'),
            controller: _pass,
            obscureText: true,
            decoration: InputDecoration(labelText: l.password),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('password2-field'),
            controller: _pass2,
            obscureText: true,
            decoration: InputDecoration(labelText: l.repeatPassword),
            onSubmitted: (_) => _signUp(),
          ),
          const SizedBox(height: 16),
          ErrorLine(_error),
          BusyButton(key: const Key('sign-up'), label: l.createAccount, busy: _busy, onPressed: _signUp),
          TextButton(onPressed: () => ref.read(sessionProvider.notifier).setInvite(null), child: Text(l.signIn)),
        ]);
      },
    );
  }
}

/// Shown while the account holds a temporary password from an admin.
class MustChangePasswordScreen extends ConsumerStatefulWidget {
  const MustChangePasswordScreen({super.key});

  @override
  ConsumerState<MustChangePasswordScreen> createState() => _MustChangePasswordScreenState();
}

class _MustChangePasswordScreenState extends ConsumerState<MustChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _next2 = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final l = context.l;
    if (_next.text != _next2.text) {
      setState(() => _error = l.passwordsDiffer);
      return;
    }
    final s = ref.read(sessionProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await s.api().changePassword(_current.text, _next.text);
      await s.refreshUser();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FormPage(title: l.mustChangeTitle, children: [
      Text(l.mustChangeHelp),
      const SizedBox(height: 16),
      TextField(controller: _current, obscureText: true, decoration: InputDecoration(labelText: l.currentPassword)),
      const SizedBox(height: 12),
      TextField(controller: _next, obscureText: true, decoration: InputDecoration(labelText: l.newPassword)),
      const SizedBox(height: 12),
      TextField(
          controller: _next2,
          obscureText: true,
          decoration: InputDecoration(labelText: l.repeatPassword),
          onSubmitted: (_) => _save()),
      const SizedBox(height: 16),
      ErrorLine(_error),
      BusyButton(label: l.save, busy: _busy, onPressed: _save),
      TextButton(onPressed: () => ref.read(sessionProvider.notifier).signOut(), child: Text(l.signOut)),
    ]);
  }
}
