import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/database_health_service.dart';

void main() {
  test('reports a healthy database when SQLite integrity check succeeds', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final health = await DatabaseHealthService(database).check();

    expect(health.isHealthy, isTrue);
    expect(health.detail, 'ok');
  });
}
