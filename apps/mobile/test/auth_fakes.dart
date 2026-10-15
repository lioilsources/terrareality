import 'dart:async';
import 'dart:io';

import 'package:terra_api/api.dart';
import 'package:terrareality/src/auth/session.dart';
import 'package:terrareality/src/push/push_registrar.dart';

/// An auth backend that records calls.
class FakeAuth implements AuthRepository {
  bool mfa = false;
  Object? loginError;
  Object? mfaError;
  Object? registerError;
  Object? logoutError;
  final calls = <String>[];
  final registered = <String>[];
  final deleted = <String>[];
  final codes = <String>[];

  static AuthResult _session(String token) => AuthResult(
    status: AuthResultStatusEnum.authenticated,
    session: SessionToken(token: token, expiresAt: DateTime(2027)),
  );

  @override
  Future<AuthResult> login(String email, String password) async {
    calls.add('login');
    if (loginError != null) throw loginError!;
    if (mfa) return AuthResult(status: AuthResultStatusEnum.mfaRequired, mfaToken: 'mfa-1');
    return _session('tok-1');
  }

  @override
  Future<AuthResult> completeMfa(String mfaToken, String code) async {
    calls.add('mfa:$mfaToken');
    codes.add(code);
    if (mfaError != null) throw mfaError!;
    return _session('tok-mfa');
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    if (logoutError != null) throw logoutError!;
  }

  @override
  Future<Me?> me() async => Me(
    id: 'u1',
    email: 'anna@example.cz',
    emailVerified: true,
    displayName: 'Anna Nováková',
    locale: UserLocale.cs,
    phoneVerified: false,
    verificationLevel: VerificationLevel.email,
    mfaEnabled: false,
    isStaff: false,
    createdAt: DateTime(2026),
  );

  @override
  Future<String?> registerPush(String token) async {
    calls.add('register:$token');
    if (registerError != null) throw registerError!;
    registered.add(token);
    return 'dev-${registered.length}';
  }

  @override
  Future<void> deletePush(String deviceId) async {
    calls.add('delete:$deviceId');
    deleted.add(deviceId);
  }
}

/// A push registrar with a controllable token and refresh stream.
class FakePush implements PushRegistrar {
  String? current = 'fcm-1';
  final refresh = StreamController<String>.broadcast();

  @override
  Future<String?> token() async => current;

  @override
  Future<Map<String, String>?> initialMessage() async => null;

  @override
  Stream<Map<String, String>> get opened => const Stream.empty();

  @override
  Stream<String> get tokenRefresh => refresh.stream;
}

ApiException offline() =>
    ApiException.withInner(400, 'Socket operation failed: GET /v1/x', const SocketException('down'), null);
