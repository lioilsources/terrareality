import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// The seeker's booked viewings. Booking a slot happens on the application
/// (ApplicationsRepository.book), where the offered slots are listed.
abstract class ViewingsRepository {
  Future<List<Viewing>> mine();
  Future<void> cancel(String bookingId);
}

class ApiViewingsRepository implements ViewingsRepository {
  ApiViewingsRepository(this.api);

  final ApplicationsApi api;

  @override
  Future<List<Viewing>> mine() async => await api.listMyViewings() ?? [];

  @override
  Future<void> cancel(String bookingId) => api.cancelViewing(bookingId);
}

final viewingsRepositoryProvider = Provider<ViewingsRepository>(
  (ref) => ApiViewingsRepository(ApplicationsApi(ref.watch(apiClientProvider))),
);

final myViewingsProvider = FutureProvider.autoDispose<List<Viewing>>(
  (ref) => ref.watch(viewingsRepositoryProvider).mine(),
);
