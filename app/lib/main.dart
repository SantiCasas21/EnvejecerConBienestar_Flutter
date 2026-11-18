import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase en segundo plano sin bloquear el primer renderizado de la app
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((Object e, StackTrace st) {
    debugPrint('Firebase init warning: $e');
    return Firebase.app();
  });

  runApp(
    const ProviderScope(
      child: EnvejecerConBienestarApp(),
    ),
  );
}
