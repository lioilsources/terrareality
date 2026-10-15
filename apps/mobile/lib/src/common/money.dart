import 'package:intl/intl.dart';

/// Formats an amount in minor units (haléře, cents) with its currency.
///
/// Whole amounts drop the decimals ("18 500 Kč"); anything with minor units
/// keeps them ("18 500,50 Kč"), so nothing is ever truncated. The currency
/// comes from the API (ISO 4217); CZK is the default because every amount
/// in the Czech pilot is in crowns.
String money(int minor, String locale, {String currency = 'CZK'}) {
  final code = currency.isEmpty ? 'CZK' : currency.toUpperCase();
  final whole = minor % 100 == 0;
  final f = NumberFormat.simpleCurrency(locale: locale, name: code, decimalDigits: whole ? 0 : 2);
  return f.format(minor / 100);
}
