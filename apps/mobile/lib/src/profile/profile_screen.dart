import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../api/api_provider.dart';
import '../auth/session.dart';
import '../common/api_error.dart';

/// The fifth tab: who is signed in, the landlord's portfolio, "About" (the
/// platform status) and sign-out.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _signOut() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(t.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          FilledButton(
            key: const Key('confirm-sign-out'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(t.signOut),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.signedOut)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final signedIn = ref.watch(authSessionProvider) != null;
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (!signedIn) ...[
            ListTile(leading: const Icon(Icons.person_outline), title: Text(t.signedOutNote)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                key: const Key('profile-sign-in'),
                onPressed: () => openLogin(context, next: '/profil'),
                child: Text(t.signInAction),
              ),
            ),
          ] else
            me.when(
              loading: () => const ListTile(leading: Icon(Icons.person), title: LinearProgressIndicator()),
              error: (e, _) => ApiErrorView(error: e, onRetry: () => ref.invalidate(meProvider)),
              data: (m) => ListTile(
                key: const Key('profile-me'),
                leading: const Icon(Icons.person),
                title: Text(m?.displayName ?? ''),
                subtitle: Text(t.signedInAs(m?.email ?? '')),
              ),
            ),
          const Divider(),
          if (signedIn)
            ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: Text(t.portfolioTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/portfolio'),
            ),
          ListTile(
            key: const Key('profile-about'),
            leading: const Icon(Icons.info_outline),
            title: Text(t.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/stav'),
          ),
          if (signedIn) ...[
            const Divider(),
            ListTile(
              key: const Key('profile-sign-out'),
              enabled: !_busy,
              leading: const Icon(Icons.logout),
              title: Text(t.signOut),
              onTap: _signOut,
            ),
          ],
        ],
      ),
    );
  }
}
