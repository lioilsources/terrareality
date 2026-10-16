import 'package:flutter/widgets.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/api_error.dart';

/// Messages for the codes the e-mail link and password endpoints answer
/// with; anything else goes through the shared [errorMessage].
String authErrorMessage(AppLocalizations t, Object error) => switch (errorCode(error)) {
  'invalid_token' => t.linkInvalid,
  'password_too_short' => t.passwordTooShort,
  'password_too_weak' => t.passwordTooWeak,
  'password_breached' => t.passwordBreached,
  _ => errorMessage(t, error),
};

/// The language of e-mails the API sends, following the app's locale.
UserLocale mailLocale(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en' ? UserLocale.en : UserLocale.cs;
