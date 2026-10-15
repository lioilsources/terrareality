import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' show ClientException;
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';

/// What went wrong with an API call, from the user's point of view.
enum ErrorKind { signIn, forbidden, notFound, rateLimited, offline, server }

/// Classifies an error from the generated client. Transport failures arrive
/// as ApiException(400) with the socket/http exception as `innerException`.
ErrorKind errorKind(Object error) {
  if (error is ApiException) {
    final inner = error.innerException;
    if (inner is SocketException ||
        inner is IOException ||
        inner is ClientException ||
        inner is TimeoutException ||
        inner is HandshakeException) {
      return ErrorKind.offline;
    }
    return switch (error.code) {
      401 => ErrorKind.signIn,
      403 => ErrorKind.forbidden,
      404 || 410 => ErrorKind.notFound,
      429 => ErrorKind.rateLimited,
      _ => ErrorKind.server,
    };
  }
  if (error is SocketException || error is ClientException || error is TimeoutException) return ErrorKind.offline;
  return ErrorKind.server;
}

/// The API error code from a problem body (`{"code": "..."}`), if any.
String? errorCode(Object error) {
  if (error is! ApiException) return null;
  try {
    final body = jsonDecode(error.message ?? '');
    return body is Map && body['code'] is String ? body['code'] as String : null;
  } catch (_) {
    return null;
  }
}

/// A user-facing message for any error a screen shows.
String errorMessage(AppLocalizations t, Object error) => switch (errorKind(error)) {
  ErrorKind.signIn => t.loginRequired,
  ErrorKind.forbidden => t.errorForbidden,
  ErrorKind.notFound => t.errorNotFound,
  ErrorKind.rateLimited => t.errorRateLimited,
  ErrorKind.offline => t.errorOffline,
  ErrorKind.server => t.errorServer,
};

/// The current location, to come back to after signing in.
String? currentLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.toString();
  } catch (_) {
    return null;
  }
}

/// Opens the sign-in screen and comes back to [next] afterwards.
void openLogin(BuildContext context, {String? next}) {
  final to = next ?? currentLocation(context);
  context.push(to == null ? '/login' : Uri(path: '/login', queryParameters: {'next': to}).toString());
}

/// The error state of a screen: a message plus "Sign in" for 401 and
/// "Retry" for everything else. [scrollable] keeps pull-to-refresh working.
class ApiErrorView extends StatelessWidget {
  const ApiErrorView({super.key, required this.error, this.onRetry, this.scrollable = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final kind = errorKind(error);
    final body = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        key: const Key('api-error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(switch (kind) {
            ErrorKind.offline => Icons.wifi_off,
            ErrorKind.signIn => Icons.lock_outline,
            _ => Icons.error_outline,
          }, size: 40),
          const SizedBox(height: 12),
          Text(errorMessage(t, error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (kind == ErrorKind.signIn)
            FilledButton(
              key: const Key('error-sign-in'),
              onPressed: () => openLogin(context),
              child: Text(t.signInAction),
            )
          else if (onRetry != null && kind != ErrorKind.notFound && kind != ErrorKind.forbidden)
            FilledButton(key: const Key('error-retry'), onPressed: onRetry, child: Text(t.retry)),
        ],
      ),
    );
    if (scrollable) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [body]);
    }
    return Center(child: SingleChildScrollView(child: body));
  }
}
