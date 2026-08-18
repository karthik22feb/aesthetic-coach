import 'package:aesthetic_coach/core/storage/secure_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements TokenKeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  group('SecureTokenStorage', () {
    late _FakeStore fakeStore;
    late SecureTokenStorage storage;

    setUp(() {
      fakeStore = _FakeStore();
      storage = SecureTokenStorage(store: fakeStore);
    });

    test(
      'reading before anything is saved returns null (empty storage behavior)',
      () async {
        expect(await storage.readRefreshToken(), isNull);
      },
    );

    test('saves and reads back a refresh token', () async {
      await storage.saveRefreshToken('token-a');
      expect(await storage.readRefreshToken(), 'token-a');
    });

    test('saving a new token replaces the previous one (rotation)', () async {
      await storage.saveRefreshToken('token-a');
      await storage.saveRefreshToken('token-b');

      expect(await storage.readRefreshToken(), 'token-b');
      expect(fakeStore._data.values, isNot(contains('token-a')));
    });

    test('clear removes the stored token', () async {
      await storage.saveRefreshToken('token-a');
      await storage.clear();

      expect(await storage.readRefreshToken(), isNull);
    });

    test('clear on already-empty storage does not throw', () async {
      await expectLater(storage.clear(), completes);
    });
  });
}
