import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

// This file is built for the web. It provides the web-specific database implementation.

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'xfin-db', // Your database name
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        // You can add more robust error handling here if you want.
        // For now, we'll just log a warning.
        // ignore: avoid_print
        print('Warning: Some features are not supported by your browser.');
      }

      return result.resolvedExecutor;
    }),
  );
}
