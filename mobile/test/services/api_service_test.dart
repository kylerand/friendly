import 'package:flutter_test/flutter_test.dart';
import 'package:friendly/services/api_service.dart';

void main() {
  group('ApiException', () {
    test('stores status code and message', () {
      const ex = ApiException(404, 'Not Found');
      expect(ex.statusCode, 404);
      expect(ex.message, 'Not Found');
    });

    test('toString includes code and message', () {
      const ex = ApiException(500, 'Internal Server Error');
      expect(ex.toString(), 'ApiException(500): Internal Server Error');
    });

    test('implements Exception', () {
      const ex = ApiException(401, 'Unauthorized');
      expect(ex, isA<Exception>());
    });
  });
}
