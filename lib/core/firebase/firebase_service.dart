import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());
final firestoreConnectionProvider = StateProvider<bool>((ref) => true);

class FirebaseService {
  Future<bool> checkFirestoreConnection() async {
    try {
      // テストコレクションへの書き込みを試行
      final testDoc = FirebaseFirestore.instance.collection('_test').doc();
      await testDoc.set({'timestamp': FieldValue.serverTimestamp()});
      await testDoc.delete();
      return true;
    } catch (e) {
      print('Firestore connection error: $e');
      return false;
    }
  }

  Stream<bool> monitorConnection() {
    return FirebaseFirestore.instance
        .collection('_status')
        .doc('connectivity')
        .snapshots()
        .map((_) => true)
        .handleError((error) => false);
  }

  Future<void> enablePersistence() async {
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  }
}
