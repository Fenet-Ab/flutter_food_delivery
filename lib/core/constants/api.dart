import 'dart:io';
import 'package:flutter/foundation.dart';

class Api {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:5000";
      // Works for iOS simulator and desktop
      return "http://localhost:5000";
    } catch (_) {
      return "http://localhost:5000";
    }
  }
}
