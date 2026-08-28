import 'package:aesthetic_coach/core/network/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig.baseUrl', () {
    test('always ends with exactly one trailing slash', () {
      expect(ApiConfig.baseUrl.endsWith('/'), isTrue);
      expect(ApiConfig.baseUrl.endsWith('//'), isFalse);
    });

    test(
      'combining with a leading-slash-free relative path never drops the '
      'separator between segments (regression: Dio does a naive '
      "'baseUrl + path' string concatenation with no separator of its own)",
      () {
        final combined = '${ApiConfig.baseUrl}auth/register';

        expect(combined, endsWith('/auth/register'));
        expect(combined, isNot(contains('v1auth')));
      },
    );
  });
}
