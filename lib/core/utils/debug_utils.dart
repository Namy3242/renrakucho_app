import 'package:flutter/foundation.dart';

class DebugUtils {
  static void logNavigation(String from, String to, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      print('🧭 Navigation: $from -> $to');
      if (params != null) {
        print('📦 Params: $params');
      }
    }
  }
}
