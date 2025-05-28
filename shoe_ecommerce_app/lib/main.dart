import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/search_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/profile/orders_screen.dart';
import 'screens/profile/favorites_screen.dart';
import 'screens/home/product_detail_screen.dart';
import 'utils/theme.dart';
import 'utils/firebase_test.dart';
import 'utils/google_sign_in_test.dart';
import 'models/product.dart';
import 'screens/debug_screen.dart';
// import 'screens/profile/settings_screen.dart';  // Commented out for now

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with the app even if Firebase fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = ProductProvider();
          // This will trigger the initialization in the background
          Future.microtask(() => provider.initialize());
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final cartProvider = CartProvider();
          // Preload cart data in the background
          Future.microtask(() => cartProvider.initialize());
          return cartProvider;
        }),
        ChangeNotifierProvider(create: (_) {
          final orderProvider = OrderProvider();
          // Preload orders in the background
          Future.microtask(() => orderProvider.initialize());
          return orderProvider;
        }),
      ],
      child: MaterialApp(
        title: 'Shoe E-commerce',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/search': (context) => const SearchScreen(),
          '/featured-products': (context) => ProductListScreen(
                title: 'Featured Products',
                products: Provider.of<ProductProvider>(context, listen: false)
                    .featuredProducts,
              ),
          '/debug': (context) => const DebugScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/product-detail': (context) =>
              const ProductDetailScreen(product: null),

          // Firebase test route
          '/firebase-test': (context) => const FirebaseTestScreen(),

          // Google Sign-In test route
          '/google-sign-in-test': (context) => const GoogleSignInTest(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/product-list') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ProductListScreen(
                title: args['title'] as String,
                products: args['products'] as List<Product>,
              ),
            );
          } else if (settings.name == '/product-detail') {
            final argument = settings.arguments;
            if (argument is Product) {
              return MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: argument),
              );
            } else if (argument is String) {
              return MaterialPageRoute(
                builder: (context) => ProductDetailScreen(),
                settings: RouteSettings(
                  name: '/product-detail',
                  arguments: argument,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(),
            );
          } else if (settings.name == '/order-confirmation') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                orderId: args['orderId'] as String,
                total: args['total'] as double,
              ),
            );
          }
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 80, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Page Not Found',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'The page you requested could not be found.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
