import 'package:flutter_test/flutter_test.dart';
import 'package:terrareality/src/push/push_registrar.dart';

void main() {
  test('push payloads map to app routes', () {
    expect(routeForPush({'kind': 'conversation', 'id': 'c1'}), '/zpravy/c1');
    expect(routeForPush({'kind': 'lease', 'id': 'l1'}), '/smlouvy/l1');
    expect(routeForPush({'kind': 'viewing', 'id': 'b1'}), '/prohlidky');
    expect(routeForPush({'conversation_id': 'c2', 'link': 'https://terrareality.cz/zpravy/c2'}), '/zpravy/c2');
    expect(routeForPush({'link': 'https://terrareality.cz/zadosti/a1'}), '/zadosti/a1');
    expect(routeForPush({'link': 'https://terrareality.cz/admin'}), isNull);
    expect(routeForPush({}), isNull);
  });
}
