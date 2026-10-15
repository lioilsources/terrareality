import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL outside the app (payment pages run in the browser so the
/// landlord's provider handles the card, never the app; ADR 0002).
abstract class UrlOpener {
  Future<bool> open(Uri url);
}

class ExternalUrlOpener implements UrlOpener {
  const ExternalUrlOpener();

  @override
  Future<bool> open(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => const ExternalUrlOpener());
