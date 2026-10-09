import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  await AppDatabase.instance.database;

  runApp(
    const ProviderScope(
      child: HishabifyApp(),
    ),
  );
}
