import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/state/app_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(appControllerProvider).init();
  runApp(UncontrolledProviderScope(
    container: container,
    child: const OrderFlowApp(),
  ));
}
