import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL for the API
  static String baseUrl =
      'http://192.168.1.1:8000'; // Default IP, will be changed

  // API endpoints
  static String get busRoutesEndpoint => '$baseUrl/api/bus-routes';
  static String get busDetailsEndpoint => '$baseUrl/api/bus-details';
  static String get busTrackingEndpoint => '$baseUrl/api/bus-tracking';

  // Method to update the base URL (e.g., when IP changes)
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    debugPrint('API base URL updated to: $baseUrl');
  }
}
