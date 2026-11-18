import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api.dart';
import '../l10n/app_localizations.dart';
import '../state/session.dart';

/// Felt green of the classic table theme.
const felt = Color(0xFF0B5D3B);

extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}

String formatDate(BuildContext context, DateTime? t) =>
    t == null ? '' : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(t);

/// Turns an error into a sentence for the player.
String errorText(AppLocalizations l, Object e) {
  if (e is! ApiException) return l.errNetwork;
  return switch (e.code) {
    'invalid_credentials' => l.errInvalidCredentials,
    'rate_limited' => l.errRateLimited,
    'invalid_code' => l.errInvalidCode,
    'challenge_expired' => l.errChallengeExpired,
    'invitation_invalid' => l.errInvitationInvalid,
    'invitation_expired' => l.errInvitationExpired,
    'invitation_used' => l.errInvitationUsed,
    'bad_username' => l.errBadUsername,
    'bad_display_name' => l.errBadDisplayName,
    'bad_password' => l.errBadPassword,
    'username_taken' => l.errUsernameTaken,
    'wrong_password' => l.errWrongPassword,
    'last_admin' => l.errLastAdmin,
    'self' => l.errSelf,
    'too_large' || 'image_too_large' => l.errTooLarge,
    'bad_image' => l.errBadImage,
    'passkey_rejected' => l.errPasskeyRejected,
    'last_sign_in_method' => l.errLastSignInMethod,
    'bad_invitation' => l.errBadInvitation,
    'bad_settings' => l.errBadSettings,
    _ => l.errGeneric(e.code),
  };
}

/// Runs [action], shows its error in a snack bar, and signs out locally when
/// the server says the session is gone. Returns null on failure.
Future<T?> guard<T>(BuildContext context, WidgetRef ref, Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    if (e is ApiException && e.status == 401) {
      await ref.read(sessionProvider.notifier).expired();
      return null;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(context.l, e))));
    }
    return null;
  }
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// A centred, width-limited card for the sign-in style screens.
class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.title, required this.children, this.actions});

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: felt,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('♠ ♥ ♦ ♣', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      ...children,
                      if (actions != null) ...[const SizedBox(height: 8), ...actions!],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorLine extends StatelessWidget {
  const ErrorLine(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text!, key: const Key('form-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
        );
}

class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      );
}

/// Shows a secret once (temporary password, invitation link) with a copy button.
Future<void> showSecret(BuildContext context, {required String title, required String help, required String value}) {
  final l = context.l;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(help),
        const SizedBox(height: 12),
        SelectableText(value, key: const Key('secret-value'), style: const TextStyle(fontFamily: 'monospace')),
      ]),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (ctx.mounted) toast(ctx, l.copied);
          },
          child: Text(l.copy),
        ),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String text, {String? action}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action ?? ctx.l.delete)),
        ],
      ),
    ) ??
    false;

/// Asks for one line of text; null when cancelled.
Future<String?> prompt(BuildContext context, String label, {String initial = '', bool obscure = false}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: TextField(
        key: const Key('prompt-field'),
        controller: c,
        autofocus: true,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(ctx.l.save)),
      ],
    ),
  );
}
