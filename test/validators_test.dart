import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_availability_finder/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email validator accepts normal email addresses', () {
      expect(Validators.email('patient@example.com'), isNull);
    });

    test('password validator rejects short passwords', () {
      expect(Validators.password('123'), isNotNull);
    });
  });
}
