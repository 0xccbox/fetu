import 'package:fetu/app.dart';
import 'package:fetu/core/di/service_locator.dart';
import 'package:flutter/material.dart';

/// Точка входа приложения Fetu.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const FetuApp());
}
