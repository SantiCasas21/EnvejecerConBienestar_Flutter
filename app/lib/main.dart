import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init warning: $e\n$st');
  }
  runApp(
    const ProviderScope(
      child: EnvejecerConBienestarApp(),
    ),
  );
}
