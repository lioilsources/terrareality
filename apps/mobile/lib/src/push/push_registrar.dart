import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Obtains the device push token. The Firebase implementation needs the
/// project's google-services files (docs/open-questions.md, OQ-14); until
/// then the app runs without push and relies on realtime and e-mail.
abstract class PushRegistrar {
  /// Returns an FCM token, or null when push is unavailable.
  Future<String?> token();
}

class NoPush implements PushRegistrar {
  const NoPush();

  @override
  Future<String?> token() async => null;
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) => const NoPush());
