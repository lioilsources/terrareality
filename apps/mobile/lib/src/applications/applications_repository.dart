import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../api/api_provider.dart';

/// Applications and viewings the seeker screens need.
abstract class ApplicationsRepository {
  Future<List<Application>> mine();
  Future<ApplicationDetail> detail(String id);
  Future<String> book(String applicationId, String slotId);
  Future<void> cancel(String bookingId);
  Future<void> consent(String applicationId);
}

class ApiApplicationsRepository implements ApplicationsRepository {
  ApiApplicationsRepository(this.api);

  final ApplicationsApi api;

  @override
  Future<List<Application>> mine() async => await api.listMyApplications() ?? [];

  @override
  Future<ApplicationDetail> detail(String id) async => (await api.getApplication(id))!;

  @override
  Future<String> book(String applicationId, String slotId) async =>
      (await api.bookViewing(applicationId, BookViewingRequest(slotId: slotId)))!.id;

  @override
  Future<void> cancel(String bookingId) => api.cancelViewing(bookingId);

  @override
  Future<void> consent(String applicationId) => api.consentApplication(applicationId);
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => ApiApplicationsRepository(ApplicationsApi(ref.watch(apiClientProvider))),
);
