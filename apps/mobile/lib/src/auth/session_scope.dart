import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../applications/applications_screen.dart';
import '../leases/leases_screen.dart';
import '../leases/payments_repository.dart';
import '../messaging/conversations_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../viewings/viewings_repository.dart';
import 'session.dart';

/// Providers holding the signed-in user's data. Sign-out drops them so the
/// next user of the phone never sees a cached screen.
List<ProviderOrFamily> sessionScopedProviders() => [
  meProvider,
  conversationsProvider,
  myApplicationsProvider,
  applicationDetailProvider,
  myLeasesProvider,
  leaseProvider,
  cardPaymentProvider,
  myViewingsProvider,
  portfolioOrgsProvider,
  portfolioProvider,
];
