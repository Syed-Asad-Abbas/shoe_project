import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/theme.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;

  const ProductDetailScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  double _selectedSize = 0;
  int _currentColorIndex = 0;
  bool _isLoading = false;
  String? _error;
  Product? _product;
  PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    // Delayed initialization to avoid dependOnInheritedWidgetOfExactType error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProduct();
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _initializeProduct() {
    if (_product != null) {
      if (_product!.sizes.isNotEmpty) {
        setState(() {
          _selectedSize = _product!.sizes[0];
        });
      }
    } else {
      _fetchProductFromArguments();
    }
  }

  Future<void> _fetchProductFromArguments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productId = ModalRoute.of(context)?.settings.arguments;
      if (productId != null && productId is String) {
        // Use ProductProvider to fetch product by ID with improved error handling
        final productProvider =
            Provider.of<ProductProvider>(context, listen: false);

        try {
          // Try to fetch from API directly with cache optimization
          _product = await productProvider.getProductById(productId,
              forceRefresh: false);
        } catch (e) {
          // Try to find it in local cache if API fetch fails
          _product = productProvider.products.firstWhere(
            (p) => p.id == productId,
            orElse: () => productProvider.featuredProducts.firstWhere(
              (p) => p.id == productId,
              orElse: () => throw Exception('Product not found'),
            ),
          );
        }

        if (_product != null && _product!.sizes.isNotEmpty) {
          setState(() {
            _selectedSize = _product!.sizes[0];
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load product details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _setSize(double size) {
    setState(() {
      _selectedSize = size;
    });
  }

  void _setColorIndex(int index) {
    setState(() {
      _currentColorIndex = index;
    });
  }

  Future<void> _addToCart() async {
    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSize == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size'),
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to add items to cart'),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
          'Adding product ${_product!.id} to cart with size $_selectedSize and quantity $_quantity');
      await cartProvider.addToCart(_product!.id, _quantity, _selectedSize);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${_product!.name} (Size: $_selectedSize) added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider.value to avoid initializing providers again
    final authProvider = context.watch<AuthProvider>();
    final cartProvider = context.watch<CartProvider>();

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildBackButton(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Product not found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Product is loaded
    final List<Color> availableColors = [
      Colors.blue,
      Colors.red,
      Colors.black,
      Colors.white,
      Colors.green,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation with back button and cart
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Images Carousel with 360 View Indicator
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Stack(
                        children: [
                          // Product image
                          PageView.builder(
                            controller: _imagePageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount:
                                3, // Dummy count, use actual images from API
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                ),
                                child: Center(
                                  child: Hero(
                                    tag: 'product-${_product!.id}',
                                    child: CachedNetworkImage(
                                      imageUrl: _product!.imageUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error, color: Colors.red),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Page indicator
                          Positioned(
                            bottom: 70,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3, // Dummy count, use actual images from API
                                (index) => Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.blue
                                        : Colors.grey[300],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Favorite button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  authProvider.isAuthenticated &&
                                          authProvider.user!.favorites
                                              .contains(_product!.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  if (!authProvider.isAuthenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Please login to add to favorites'),
                                        action: SnackBarAction(
                                          label: 'Login',
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, '/login');
                                          },
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await authProvider
                                        .toggleFavorite(_product!.id);
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
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Product Information Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BEST SELLER Tag if applicable
                          if (_product!.featured)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BEST SELLER',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          SizedBox(height: 8),

                          // Product Name
                          Text(
                            _product!.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8),

                          // Product Price with discount if applicable
                          Row(
                            children: [
                              Text(
                                '\$${_product!.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_product!.discount > 0) ...[
                                SizedBox(width: 8),
                                Text(
                                  '\$${(_product!.price / (1 - _product!.discount / 100)).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          SizedBox(height: 16),

                          // Product Description
                          Text(
                            _product!.description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: 24),

                          // Gallery title
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 12),

                          // Image thumbnails
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3, // Dummy count
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _imagePageController.animateToPage(
                                      index,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 70,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _currentImageIndex == index
                                            ? Colors.blue
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: _product!.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 24),

                          // Size Section
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Size',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'EU',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'US',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'UK',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Size selection
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _product!.sizes.length,
                              itemBuilder: (context, index) {
                                final size = _product!.sizes[index];
                                final isSelected = size == _selectedSize;

                                return GestureDetector(
                                  onTap: () => _setSize(size),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 10),
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      size.toInt().toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 24),

                          // Price with Quantity and Add to Cart
                          Row(
                            children: [
                              // Price display
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '\$${(_product!.price * _quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20),
                              // Add to Cart button
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: CustomButton(
                                    text: 'ADD TO CART',
                                    onPressed: _addToCart,
                                    isLoading: cartProvider.isLoading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, size: 20),
      ),
    );
  }
}
