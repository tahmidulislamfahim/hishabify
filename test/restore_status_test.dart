import 'package:flutter_test/flutter_test.dart';
import 'package:hishabify/features/settings/data/backup_restore_service.dart';

void main() {
  test('RestoreStatus enum values are defined and distinct', () {
    expect(RestoreStatus.values.length, 4);
    expect(RestoreStatus.success, isNot(equals(RestoreStatus.error)));
    expect(RestoreStatus.cancelled, isNot(equals(RestoreStatus.invalidFile)));
  });
}
