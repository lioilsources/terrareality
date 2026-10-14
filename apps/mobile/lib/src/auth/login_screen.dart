import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../messaging/messaging_repository.dart';

/// E-mail and password sign-in; leads to the messages.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signIn(ref, _email.text.trim(), _password.text);
      if (mounted) context.go('/zpravy');
    } catch (_) {
      setState(() => _error = t.loginFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.loginTitle)),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _email,
              decoration: InputDecoration(labelText: t.loginEmail),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: t.loginPassword),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _submit, child: Text(t.loginContinue)),
          ],
        ),
      ),
    );
  }
}
