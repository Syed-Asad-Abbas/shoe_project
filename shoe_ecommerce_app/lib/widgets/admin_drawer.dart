import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  '/admin/dashboard',
                ),
                _buildDrawerItem(
                  context,
                  'Products',
                  Icons.inventory,
                  '/admin/products',
                ),
                _buildDrawerItem(
                  context,
                  'Orders',
                  Icons.shopping_bag,
                  '/admin/orders',
                ),
                _buildDrawerItem(
                  context,
                  'Customers',
                  Icons.people,
                  '/admin/customers',
                ),
                _buildDrawerItem(
                  context,
                  'Analytics',
                  Icons.bar_chart,
                  '/admin/analytics',
                ),
                _buildDrawerItem(
                  context,
                  'Marketing',
                  Icons.campaign,
                  '/admin/marketing',
                ),
                _buildDrawerItem(
                  context,
                  'Settings',
                  Icons.settings,
                  '/admin/settings',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  'Help & Support',
                  Icons.help,
                  '/admin/support',
                ),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.blue,
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Admin Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'admin@shoeshop.com',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    final isSelected = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[900],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
      onTap: () {
        if (route != currentRoute) {
          Navigator.of(context).pushReplacementNamed(route);
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Perform logout and navigate to login screen
                    Navigator.of(context).pushReplacementNamed('/admin/login');
                  },
                  child: const Text('Logout'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 