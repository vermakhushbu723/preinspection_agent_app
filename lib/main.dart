import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/orientation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppOrientation.lockPortrait();
  runApp(const ProviderScope(child: PreinspectionAgentApp()));
}
