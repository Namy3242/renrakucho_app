import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/firebase/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firebaseService = FirebaseService();
    await firebaseService.enablePersistence();
    
    // オフライン永続化の設定
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    final isFirestoreAvailable = await firebaseService.checkFirestoreConnection();
    
    if (!isFirestoreAvailable) {
      print('Warning: Firestore is not available');
      // エラーハンドリングを実装
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Webプラットフォームの場合、Connectivity Plusの初期化
  if (kIsWeb) {
    Connectivity();
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
