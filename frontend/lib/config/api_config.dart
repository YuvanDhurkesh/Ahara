import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];

    if (envUrl == null || envUrl.isEmpty) {
      if (kDebugMode) {
        print("⚠️ BASE_URL not found in .env, using fallback.");
      }

      // Default fallback for local development
      return "http://aharabackend-env.eba-nn8ggm5m.ap-south-1.elasticbeanstalk.com/api";
      //return "http://localhost:5000/api";
    }

    return envUrl;
  }
}