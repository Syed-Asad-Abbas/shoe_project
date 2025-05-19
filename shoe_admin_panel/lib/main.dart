import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ShoeAdminApp());
}

class ShoeAdminApp extends StatelessWidget {
  const ShoeAdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Shoe Shop Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}
