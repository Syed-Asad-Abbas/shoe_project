import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NetworkUtils {
  // Check internet connectivity by making a request to Google
  static Future<bool> hasInternetConnection() async {
    try {
      final response =
          await http.get(Uri.parse('https://www.google.com')).timeout(
                const Duration(seconds: 5),
              );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Internet connectivity check failed: $e');
      return false;
    }
  }

  // Check if a specific domain/API is reachable
  static Future<bool> canReachFirebase() async {
    try {
      final response =
          await http.get(Uri.parse('https://firebase.google.com')).timeout(
                const Duration(seconds: 5),
              );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Firebase connectivity check failed: $e');
      return false;
    }
  }

  // Get a more specific error message based on the network error
  static String getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Connection timed out. Please check your internet speed and try again.';
    } else if (errorString.contains('unreachable host') ||
        errorString.contains('connection refused')) {
      return 'Could not connect to the server. Please try again later.';
    } else if (errorString.contains('network is unreachable')) {
      return 'Network is unreachable. Please check your WiFi or mobile data connection.';
    } else if (errorString.contains('no internet')) {
      return 'No internet connection. Please connect to WiFi or mobile data.';
    } else {
      return 'A network error occurred. Please check your connection and try again.';
    }
  }

  // Retry a function with exponential backoff
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() function,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await function();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;

        // Check if it's a network error that can be retried
        final errorString = e.toString().toLowerCase();
        final isNetworkError = errorString.contains('network') ||
            errorString.contains('timeout') ||
            errorString.contains('connection');

        if (!isNetworkError) rethrow;

        debugPrint('Retry $retryCount after $delay - Error: $e');
        await Future.delayed(delay);

        // Exponential backoff
        delay *= 2;
      }
    }
  }
}
