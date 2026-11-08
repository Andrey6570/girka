import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(GirkaApp(state: state));
}
