import 'package:flutter/material.dart';
import '../products/products_screen.dart';
import '../orders/orders_screen.dart';
import '../customers/customers_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProductsScreen(),
    OrdersScreen(),
    CustomersScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Products',
    'Orders',
    'Customers',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'admin@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'Products',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.shopping_cart,
              title: 'Orders',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Customers',
              index: 3,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Implement logout functionality
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blue[700] : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.blue[700] : Colors.black,
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.of(context).pop();
      },
      selected: _selectedIndex == index,
    );
  }
}
