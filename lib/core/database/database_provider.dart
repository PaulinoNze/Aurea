// lib/core/database/database_provider.dart
// Riverpod provider para AppDatabase

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Provider singleton para toda la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
