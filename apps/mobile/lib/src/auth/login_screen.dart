import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Placeholder sign-in screen; real auth lands in milestone M1.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(labelText: t.loginEmail),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(t.loginComingSoon))),
              child: Text(t.loginContinue),
            ),
          ],
        ),
      ),
    );
  }
}
