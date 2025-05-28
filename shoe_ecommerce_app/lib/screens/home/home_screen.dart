import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../utils/theme.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final categories = ['All', 'Running', 'Basketball', 'Casual', 'Formal'];
  String selectedCategory = 'All';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFetchProducts();
    });
  }

  Future<void> _checkAndFetchProducts() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    // Only fetch if products list is empty
    if (provider.products.isEmpty && !provider.isLoading) {
      debugPrint('Home screen: Products list is empty, triggering fetch');
      await _fetchProducts(forceRefresh: false);
    } else {
      debugPrint(
          'Home screen: Products already loaded (${provider.products.length} items)');
    }
  }

  Future<void> _fetchProducts({bool forceRefresh = false}) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('Fetching data with forceRefresh: $forceRefresh');

    try {
      // Refresh auth status first
      if (forceRefresh) {
        await authProvider.checkAuthStatus(forceRefresh: true);
      }

      // Fetch cart items if user is authenticated
      if (authProvider.isAuthenticated) {
        await cartProvider.fetchCart(forceRefresh: forceRefresh);
      }

      // Fetch products
      await provider.fetchProducts(
        category: selectedCategory == 'All' ? null : selectedCategory,
        forceRefresh: forceRefresh,
      );

      // Fetch featured products
      await provider.fetchFeaturedProducts(forceRefresh: forceRefresh);

      debugPrint('Loaded ${provider.products.length} total products');
      debugPrint(
          'Loaded ${provider.featuredProducts.length} featured products');

      if (forceRefresh) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data refreshed from server'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Add a method to refresh all data
  Future<void> _refreshAllData() async {
    debugPrint('Manual refresh triggered');
    return _fetchProducts(forceRefresh: true);
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });

    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.fetchProducts(
      category: category == 'All' ? null : category,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home - do nothing, already on home
        break;
      case 1: // Cart
        Navigator.pushNamed(context, '/cart');
        break;
      case 2: // Favorites
        Navigator.pushNamed(context, '/favorites');
        break;
      case 3: // Profile
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoe Shop'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
            tooltip: 'Refresh data',
          ),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          // Cart icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (authProvider.isAuthenticated && cartProvider.itemCount > 0)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: authProvider.isAuthenticated &&
                            authProvider.user?.photoUrl != null
                        ? NetworkImage(authProvider.user!.photoUrl!)
                        : null,
                    child: authProvider.isAuthenticated &&
                            authProvider.user?.photoUrl != null
                        ? null
                        : Icon(
                            Icons.person,
                            size: 30,
                            color: primaryColor,
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.isAuthenticated
                        ? authProvider.user?.name ?? 'User'
                        : 'Guest User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (authProvider.isAuthenticated)
                    Text(
                      authProvider.user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('My Cart'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Favorites'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/favorites');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Orders'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/orders');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  // Add debug mode option
                  if (kDebugMode)
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('Debug'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/debug');
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
            if (authProvider.isAuthenticated)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: productProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'New Collection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Discount 50% for the first order',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/featured-products',
                                      arguments: {
                                        'title': 'New Collection',
                                        'products': productProvider.products
                                            .where((p) => p.stockQuantity < 20)
                                            .toList(),
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: primaryColor,
                                  ),
                                  child: const Text('Shop Now'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Category selector
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCategory == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: InkWell(
                              onTap: () => _onCategorySelected(category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Featured products
                    if (productProvider.featuredProducts.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Featured Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/featured-products',
                                arguments: {
                                  'title': 'Featured Products',
                                  'products': productProvider.featuredProducts,
                                },
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: productProvider.featuredProducts.length,
                          itemBuilder: (ctx, i) => ProductCard(
                            product: productProvider.featuredProducts[i],
                            isHorizontal: true,
                            isFavorite: authProvider.isAuthenticated &&
                                authProvider.user!.favorites.contains(
                                  productProvider.featuredProducts[i].id,
                                ),
                            onFavoritePressed: authProvider.isAuthenticated
                                ? () async {
                                    try {
                                      await authProvider.toggleFavorite(
                                        productProvider.featuredProducts[i].id,
                                      );
                                      setState(() {});
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to update favorites: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    // Products by selected category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCategory == 'All'
                              ? 'All Products'
                              : '$selectedCategory Shoes',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/featured-products',
                              arguments: {
                                'title': selectedCategory == 'All'
                                    ? 'All Products'
                                    : '$selectedCategory Shoes',
                                'products': productProvider.products,
                              },
                            );
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Show error message if there's an error
                    if (productProvider.error.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Error loading products',
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              productProvider.error,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _refreshAllData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade800,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),

                    productProvider.products.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 30),
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  productProvider.error.isEmpty
                                      ? 'No products found'
                                      : 'Error loading products',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (productProvider.products.isEmpty &&
                                    productProvider.error.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: ElevatedButton(
                                      onPressed: _refreshAllData,
                                      child: const Text('Refresh'),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                            ),
                            itemCount: productProvider.products.length,
                            itemBuilder: (ctx, i) => ProductCard(
                              product: productProvider.products[i],
                              isFavorite: authProvider.isAuthenticated &&
                                  authProvider.user!.favorites.contains(
                                    productProvider.products[i].id,
                                  ),
                              onFavoritePressed: authProvider.isAuthenticated
                                  ? () async {
                                      try {
                                        await authProvider.toggleFavorite(
                                          productProvider.products[i].id,
                                        );
                                        setState(() {});
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to update favorites: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
