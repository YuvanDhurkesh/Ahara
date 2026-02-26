import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];

    if (envUrl == null || envUrl.isEmpty) {
      throw Exception("BASE_URL not configured in .env");
    }

    return envUrl;
  }
}