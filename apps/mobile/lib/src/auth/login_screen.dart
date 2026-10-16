import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terra_api/api.dart' show UserLocale;

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';
import 'auth_errors.dart';
import 'session.dart';

/// Only in-app paths are accepted as a return target (no open redirect).
String safeNext(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//') || next.startsWith('/login')) {
    return '/zpravy';
  }
  return next;
}

/// E-mail and password sign-in, then the TOTP/recovery code when the
/// account has two-factor authentication. Returns to [next] afterwards.
/// Also requests a sign-in link or a password reset e-mail for the entered
/// address. [mfaToken] opens the code step directly (a sign-in link that
/// answered mfa_required).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.next, this.mfaToken});

  final String? next;
  final String? mfaToken;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;
  late String? _mfaToken = widget.mfaToken;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _done() {
    final to = safeNext(widget.next);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(to);
    }
  }

  Future<void> _run(Future<LoginOutcome> Function() call, String Function(Object) message) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final outcome = await call();
      if (!mounted) return;
      switch (outcome) {
        case SignedIn():
          _done();
        case MfaRequired(:final mfaToken):
          setState(() => _mfaToken = mfaToken);
      }
    } catch (e) {
      if (mounted) setState(() => _error = message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submitPassword() {
    final t = AppLocalizations.of(context);
    _run(
      () => ref.read(authServiceProvider).login(_email.text.trim(), _password.text),
      (e) => errorKind(e) == ErrorKind.signIn || errorCode(e) == 'invalid_credentials'
          ? t.loginFailed
          : errorMessage(t, e),
    );
  }

  void _submitCode() {
    final t = AppLocalizations.of(context);
    final token = _mfaToken!;
    _run(
      () => ref.read(authServiceProvider).completeMfa(token, _code.text.replaceAll(' ', '')),
      (e) => errorKind(e) == ErrorKind.signIn || errorCode(e) == 'invalid_code' ? t.mfaFailed : errorMessage(t, e),
    );
  }

  /// Requests a sign-in link or a reset e-mail. The API answers 202 whether
  /// or not the account exists, so the confirmation never reveals that.
  Future<void> _sendLink(
    Future<void> Function(AuthService, String, UserLocale) send,
    String Function(AppLocalizations, String) sent,
  ) async {
    final t = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = t.loginEmailNeeded;
        _info = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await send(ref.read(authServiceProvider), email, mailLocale(context));
      if (mounted) setState(() => _info = sent(t, email));
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _requestMagicLink() => _sendLink((a, e, l) => a.requestMagicLink(e, l), (t, e) => t.magicLinkSent(e));

  void _forgotPassword() => _sendLink((a, e, l) => a.forgotPassword(e, l), (t, e) => t.resetLinkSent(e));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final mfa = _mfaToken != null;
    return Scaffold(
      appBar: AppBar(title: Text(mfa ? t.mfaTitle : t.loginTitle)),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!mfa) ...[
              TextField(
                key: const Key('login-email'),
                controller: _email,
                decoration: InputDecoration(labelText: t.loginEmail),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('login-password'),
                controller: _password,
                decoration: InputDecoration(labelText: t.loginPassword),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submitPassword(),
              ),
            ] else ...[
              Text(t.mfaHint),
              const SizedBox(height: 12),
              TextField(
                key: const Key('mfa-code'),
                controller: _code,
                autofocus: true,
                decoration: InputDecoration(labelText: t.mfaCode),
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                onSubmitted: (_) => _submitCode(),
              ),
            ],
            if (_info != null) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: Text(_info!, key: const Key('login-info'))),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  key: const Key('login-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('login-submit'),
              onPressed: _busy ? null : (mfa ? _submitCode : _submitPassword),
              child: Text(t.loginContinue),
            ),
            if (!mfa) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('login-magic-link'),
                onPressed: _busy ? null : _requestMagicLink,
                child: Text(t.loginMagicLink),
              ),
              TextButton(
                key: const Key('login-forgot'),
                onPressed: _busy ? null : _forgotPassword,
                child: Text(t.loginForgotPassword),
              ),
            ],
            if (mfa)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _mfaToken = null;
                        _code.clear();
                        _error = null;
                      }),
                child: Text(t.mfaRestart),
              ),
          ],
        ),
      ),
    );
  }
}
