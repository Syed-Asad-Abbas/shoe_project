import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/network_utils.dart';

class NetworkErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const NetworkErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  factory NetworkErrorWidget.defaultError({required VoidCallback onRetry}) {
    return NetworkErrorWidget(
      message:
          'Network connection error. Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.signal_wifi_off,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Problem',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final hasConnection =
                    await NetworkUtils.hasInternetConnection();
                if (hasConnection) {
                  onRetry();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'No internet connection detected. Please check your network settings.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Check Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
