import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double total;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your order #$orderId has been placed successfully.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Amount: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'We\'ll send you a confirmation email with your order details shortly.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                CustomButton(
                  text: 'Track Order',
                  onPressed: () {
                    Navigator.pushNamed(context, '/orders');
                  },
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Continue Shopping',
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  backgroundColor: Colors.white,
                  textColor: primaryColor,
                  borderColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 