import 'database.dart';

class DatabaseHealthService {
  DatabaseHealthService(this._database);

  final AppDatabase _database;

  Future<DatabaseHealth> check() async {
    final row = await _database
        .customSelect('PRAGMA integrity_check')
        .getSingle();
    final result = row.read<String>('integrity_check');
    return DatabaseHealth(isHealthy: result == 'ok', detail: result);
  }
}

class DatabaseHealth {
  const DatabaseHealth({required this.isHealthy, required this.detail});

  final bool isHealthy;
  final String detail;
}
