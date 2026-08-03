import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Initializes SQLite for web.
///
/// Uses the no-web-worker factory to avoid shared service-worker caching/version
/// mismatch issues during development. This runs sqlite3 (wasm) on the main
/// isolate, which is reliable for a local-first app of this size.
Future<void> initDatabase() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }
}
