import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart' show ApiException;

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import 'auth_errors.dart';
import 'login_screen.dart';
import 'session.dart';

/// Minimum password length, the same rule as the API (`Password` schema).
const minPasswordLength = 12;

/// The e-mail links the app opens through App Links / Universal Links. The
/// API builds them as `{WEB_BASE_URL}{path}?token=...`; the web serves the
/// same paths when the app is not installed.
const magicLinkPath = '/auth/magic';
const resetPasswordPath = '/auth/reset';

/// Opened from the e-mailed sign-in link: exchanges the token for a session
/// right away (unlike the web page, no mail scanner can prefetch an app
/// link) and continues to the app, or to the code step when the account has
/// two-factor authentication.
class MagicLinkScreen extends ConsumerStatefulWidget {
  const MagicLinkScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  Object? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  void _retry() {
    setState(() {
      _busy = true;
      _error = null;
    });
    _verify();
  }

  Future<void> _verify() async {
    try {
      if (widget.token.isEmpty) throw const _MissingToken();
      final outcome = await ref.read(authServiceProvider).verifyMagicLink(widget.token);
      if (!mounted) return;
      switch (outcome) {
        case SignedIn():
          context.go(safeNext(null));
        case MfaRequired():
          context.go('/login', extra: outcome);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final error = _error;
    // A 400 that is not a transport failure means the token itself was
    // rejected (expired, used, or malformed).
    final invalid = error is _MissingToken ||
        (error is ApiException && error.code == 400 && errorKind(error) != ErrorKind.offline);
    final retry = error != null && !invalid && errorKind(error) != ErrorKind.rateLimited;
    return Scaffold(
      appBar: AppBar(title: Text(t.magicLinkTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(t.magicLinkSigningIn),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(errorKind(error!) == ErrorKind.offline ? Icons.wifi_off : Icons.link_off, size: 40),
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        invalid ? t.linkInvalid : authErrorMessage(t, error),
                        key: const Key('link-error'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (retry)
                      FilledButton(key: const Key('error-retry'), onPressed: _retry, child: Text(t.retry)),
                    TextButton(
                      key: const Key('link-login'),
                      onPressed: () => context.go('/login'),
                      child: Text(t.linkBackToLogin),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MissingToken implements Exception {
  const _MissingToken();
}

/// Opened from the password reset e-mail: sets a new password with the
/// token. The API signs the account out everywhere, so the user signs in
/// again afterwards.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final password = _password.text;
    if (widget.token.isEmpty) {
      setState(() => _error = t.linkInvalid);
      return;
    }
    if (password.runes.length < minPasswordLength) {
      setState(() => _error = t.passwordTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(widget.token, password);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.resetTitle)),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_done) ...[
              Semantics(liveRegion: true, child: Text(t.resetDone, key: const Key('reset-done'))),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('link-login'),
                onPressed: () => context.go('/login'),
                child: Text(t.signInAction),
              ),
            ] else ...[
              Text(t.resetHint),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reset-password'),
                controller: _password,
                decoration: InputDecoration(labelText: t.resetPassword),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const Key('reset-error'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('reset-submit'),
                onPressed: _busy ? null : _submit,
                child: Text(t.resetSubmit),
              ),
              TextButton(
                key: const Key('link-login'),
                onPressed: _busy ? null : () => context.go('/login'),
                child: Text(t.linkBackToLogin),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
