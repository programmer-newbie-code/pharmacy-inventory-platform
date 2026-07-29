import 'dart:convert';

class BackupValidationException implements Exception {
  BackupValidationException(this.message);

  final String message;

  @override
  String toString() => 'BackupValidationException: $message';
}

class BackupDocument {
  BackupDocument({
    required this.schemaVersion,
    required this.createdAt,
    required this.data,
  });

  static const currentSchemaVersion = 2;

  static const requiredCollections = <String>[
    'users',
    'storageLocations',
    'products',
    'stockBatches',
    'saleTransactions',
    'saleItems',
    'auditLogs',
    'backupLogs',
    'cashierShifts',
    'returnTransactions',
    'returnItems',
    'suppliers',
    'purchaseOrders',
    'purchaseOrderItems',
  ];

  final int schemaVersion;
  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> data;

  static BackupDocument parseAndValidate(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw BackupValidationException('Backup is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw BackupValidationException('Backup root must be an object.');
    }

    final version = decoded['schemaVersion'] ?? decoded['version'];
    if (version is! int || version < 1 || version > currentSchemaVersion) {
      throw BackupValidationException('Unsupported backup schema version.');
    }

    final createdAtValue = decoded['createdAt'] ?? decoded['exportedAt'];
    final createdAt = createdAtValue is String ? DateTime.tryParse(createdAtValue) : null;
    if (createdAt == null) {
      throw BackupValidationException('Backup creation date is invalid.');
    }

    final rawData = version == 1 ? decoded : decoded['data'];
    if (rawData is! Map<String, dynamic>) {
      throw BackupValidationException('Backup data must be an object.');
    }

    final data = <String, List<Map<String, Object?>>>{};
    for (final collection in requiredCollections) {
      final rawRows = rawData[collection];
      if (rawRows == null && version == 1) {
        data[collection] = [];
        continue;
      }
      if (rawRows is! List) {
        throw BackupValidationException('Backup collection "$collection" is missing or invalid.');
      }
      data[collection] = rawRows.map((row) {
        if (row is! Map) {
          throw BackupValidationException('Backup collection "$collection" contains an invalid row.');
        }
        return Map<String, Object?>.from(row);
      }).toList(growable: false);
    }

    _validateCounts(decoded['counts'], data, version);
    final ids = _validateIds(data);
    _validateReferences(data, ids);

    return BackupDocument(schemaVersion: version, createdAt: createdAt, data: data);
  }

  static void _validateCounts(
    Object? rawCounts,
    Map<String, List<Map<String, Object?>>> data,
    int version,
  ) {
    if (rawCounts == null && version == 1) return;
    if (rawCounts is! Map) {
      throw BackupValidationException('Backup record counts are missing or invalid.');
    }
    for (final collection in requiredCollections) {
      final count = rawCounts[collection];
      if (count is! int || count != data[collection]!.length) {
        throw BackupValidationException('Backup count for "$collection" does not match its records.');
      }
    }
  }

  static Map<String, Set<int>> _validateIds(
    Map<String, List<Map<String, Object?>>> data,
  ) {
    final result = <String, Set<int>>{};
    for (final entry in data.entries) {
      final ids = <int>{};
      for (final row in entry.value) {
        final id = row['id'];
        if (id is! int || id <= 0 || !ids.add(id)) {
          throw BackupValidationException('Backup collection "${entry.key}" contains a duplicate or invalid ID.');
        }
      }
      result[entry.key] = ids;
    }
    return result;
  }

  static void _validateReferences(
    Map<String, List<Map<String, Object?>>> data,
    Map<String, Set<int>> ids,
  ) {
    _reference(data['products']!, 'storageLocationId', ids['storageLocations']!, nullable: true);
    _reference(data['stockBatches']!, 'productId', ids['products']!);
    _reference(data['saleTransactions']!, 'cashierId', ids['users']!);
    _reference(data['saleItems']!, 'transactionId', ids['saleTransactions']!);
    _reference(data['saleItems']!, 'productId', ids['products']!);
    _reference(data['saleItems']!, 'batchId', ids['stockBatches']!);
    _reference(data['auditLogs']!, 'userId', ids['users']!);
    _reference(data['cashierShifts']!, 'cashierId', ids['users']!);
    _reference(data['returnTransactions']!, 'originalTxnId', ids['saleTransactions']!);
    _reference(data['returnTransactions']!, 'processedBy', ids['users']!);
    _reference(data['returnItems']!, 'returnTxnId', ids['returnTransactions']!);
    _reference(data['returnItems']!, 'saleItemId', ids['saleItems']!);
    _reference(data['purchaseOrders']!, 'supplierId', ids['suppliers']!);
    _reference(data['purchaseOrderItems']!, 'purchaseOrderId', ids['purchaseOrders']!);
    _reference(data['purchaseOrderItems']!, 'productId', ids['products']!);
  }

  static void _reference(
    List<Map<String, Object?>> rows,
    String field,
    Set<int> targetIds, {
    bool nullable = false,
  }) {
    for (final row in rows) {
      final value = row[field];
      if (value == null && nullable) continue;
      if (value is! int || !targetIds.contains(value)) {
        throw BackupValidationException('Backup reference "$field" is invalid.');
      }
    }
  }
}
