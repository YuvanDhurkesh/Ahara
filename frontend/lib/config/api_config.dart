import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {

  /// Returns the backend base URL
  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];

    // If .env variable is missing, use fallback
    if (envUrl == null || envUrl.isEmpty) {
      if (kDebugMode) {
        print("⚠️ BASE_URL not found in .env, using fallback.");
      }

      // Default fallback for local development
      //return "http://localhost:5000/api";
      return "http://10.12.66.118:5000/api";

    }

    return envUrl;
  }
}
