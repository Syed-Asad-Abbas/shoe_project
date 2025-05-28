import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;
  Map<String, dynamic> _testResults = {};
  bool _isTestingConnection = false;
  int _connectionRetryCount = 0;
  static const int _maxConnectionRetries = 5;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _testResults = {};
    });

    _addLog('Starting tests...');

    // Test API connection
    await _testApiConnection();

    // Test product endpoints
    await _testProductEndpoints();

    // Test featured products
    await _testFeaturedProducts();

    // Test category products
    await _testCategoryProducts();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testApiConnection() async {
    _addLog('Testing API connection...');
    _isTestingConnection = true;
    _connectionRetryCount = 0;

    while (_connectionRetryCount < _maxConnectionRetries) {
      try {
        final response = await http.get(
          Uri.parse('${Constants.apiUrl}/products'),
          headers: {'Cache-Control': 'no-cache'},
        ).timeout(const Duration(seconds: 5));

        _testResults['apiConnection'] = {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'statusCode': response.statusCode,
          'responseLength': response.body.length,
          'attempts': _connectionRetryCount + 1,
        };

        _addLog(
            'API connection: ${_testResults['apiConnection']['success'] ? 'SUCCESS' : 'FAILED'} (status: ${response.statusCode}, attempt: ${_connectionRetryCount + 1})');

        // If successful, stop retrying
        if (_testResults['apiConnection']['success'] == true) {
          break;
        }

        // If we get a response but it's an error, stop retrying as well
        if (response.statusCode >= 400) {
          _addLog(
              'Received error status code ${response.statusCode}, stopping retries');
          break;
        }

        _connectionRetryCount++;
        if (_connectionRetryCount < _maxConnectionRetries) {
          _addLog('Retrying connection in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        _testResults['apiConnection'] = {
          'success': false,
          'error': e.toString(),
          'attempts': _connectionRetryCount + 1,
        };
        _addLog(
            'API connection attempt ${_connectionRetryCount + 1} failed: $e');

        _connectionRetryCount++;
        if (_connectionRetryCount < _maxConnectionRetries) {
          _addLog(
              'Retrying connection in ${_connectionRetryCount + 1} seconds...');
          await Future.delayed(Duration(seconds: _connectionRetryCount + 1));
        }
      }
    }

    _isTestingConnection = false;

    if (_connectionRetryCount == _maxConnectionRetries) {
      _addLog('Maximum retry attempts reached. Cannot connect to API.');
    }
  }

  Future<void> _testProductEndpoints() async {
    _addLog('Testing products endpoint...');
    try {
      final response = await http
          .get(Uri.parse('${Constants.apiUrl}/products'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> products = jsonDecode(response.body);
        _testResults['products'] = {
          'success': true,
          'count': products.length,
          'firstProduct': products.isNotEmpty ? products.first : null,
        };
        _addLog('Products endpoint: SUCCESS (${products.length} products)');
      } else {
        _testResults['products'] = {
          'success': false,
          'statusCode': response.statusCode,
          'response': response.body,
        };
        _addLog('Products endpoint: FAILED (status: ${response.statusCode})');
      }
    } catch (e) {
      _testResults['products'] = {
        'success': false,
        'error': e.toString(),
      };
      _addLog('Products endpoint failed: $e');
    }
  }

  Future<void> _testFeaturedProducts() async {
    _addLog('Testing featured products endpoint...');
    try {
      final response = await http
          .get(Uri.parse('${Constants.apiUrl}/products/featured'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> products = jsonDecode(response.body);
        _testResults['featuredProducts'] = {
          'success': true,
          'count': products.length,
          'firstProduct': products.isNotEmpty ? products.first : null,
        };
        _addLog(
            'Featured products endpoint: SUCCESS (${products.length} products)');
      } else {
        _testResults['featuredProducts'] = {
          'success': false,
          'statusCode': response.statusCode,
          'response': response.body,
        };
        _addLog(
            'Featured products endpoint: FAILED (status: ${response.statusCode})');
      }
    } catch (e) {
      _testResults['featuredProducts'] = {
        'success': false,
        'error': e.toString(),
      };
      _addLog('Featured products endpoint failed: $e');
    }
  }

  Future<void> _testCategoryProducts() async {
    _addLog('Testing category products endpoint...');

    final categories = ['Running', 'Casual', 'Basketball'];

    for (final category in categories) {
      try {
        final response = await http
            .get(Uri.parse('${Constants.apiUrl}/products/category/$category'))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final List<dynamic> products = jsonDecode(response.body);
          _testResults['category_$category'] = {
            'success': true,
            'count': products.length,
          };
          _addLog(
              'Category $category endpoint: SUCCESS (${products.length} products)');
        } else {
          _testResults['category_$category'] = {
            'success': false,
            'statusCode': response.statusCode,
          };
          _addLog(
              'Category $category endpoint: FAILED (status: ${response.statusCode})');
        }
      } catch (e) {
        _testResults['category_$category'] = {
          'success': false,
          'error': e.toString(),
        };
        _addLog('Category $category endpoint failed: $e');
      }
    }
  }

  Future<void> _refreshAllDataFromProviders() async {
    _addLog('Refreshing all data from providers...');

    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.refreshAllData();
      _addLog('ProductProvider refresh completed');
      _addLog('Products count: ${productProvider.products.length}');
      _addLog(
          'Featured products count: ${productProvider.featuredProducts.length}');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        await authProvider.refreshUserProfile();
        _addLog(
            'AuthProvider refresh completed: ${authProvider.user?.name ?? 'No user'}');
      } else {
        _addLog('User not authenticated');
      }
    } catch (e) {
      _addLog('Error refreshing data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnectionWithRetry() async {
    setState(() {
      _isLoading = true;
      _connectionRetryCount = 0;
      _isTestingConnection = true;
    });

    _addLog('Starting connection test with retry...');
    await _testApiConnection();

    setState(() {
      _isLoading = false;
      _isTestingConnection = false;
    });
  }

  // Test loading settings, which can help show if the Settings screen will work properly
  Future<void> _testLoadSettings() async {
    _addLog('Testing settings endpoint...');
    try {
      final response = await http
          .get(Uri.parse('${Constants.apiUrl}/settings'))
          .timeout(const Duration(seconds: 5));

      _testResults['settings'] = {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
      };

      _addLog(
          'Settings endpoint: ${_testResults['settings']['success'] ? 'SUCCESS' : 'FAILED'} (status: ${response.statusCode})');
    } catch (e) {
      _testResults['settings'] = {
        'success': false,
        'error': e.toString(),
      };
      _addLog('Settings endpoint failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        actions: [
          _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _runTests,
                  tooltip: 'Run tests again',
                ),
        ],
      ),
      body: _isLoading && !_isTestingConnection
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Info
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Connection',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _testResults['apiConnection']?['success'] ==
                                        true
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _testResults['apiConnection']
                                            ?['success'] ==
                                        true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'API Status: ${_testResults['apiConnection']?['success'] == true ? 'Connected' : 'Failed'}',
                                style: TextStyle(
                                  color: _testResults['apiConnection']
                                              ?['success'] ==
                                          true
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_testResults['apiConnection']?['attempts'] !=
                                  null)
                                Text(
                                  ' (Attempts: ${_testResults['apiConnection']?['attempts']})',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('API URL: ${Constants.apiUrl}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _isTestingConnection
                                    ? null
                                    : _testConnectionWithRetry,
                                child: Text(_isTestingConnection
                                    ? 'Testing... (${_connectionRetryCount + 1}/$_maxConnectionRetries)'
                                    : 'Test Connection'),
                              ),
                              const SizedBox(width: 8),
                              if (_isTestingConnection)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Provider Data
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Provider Data',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                productProvider.products.isNotEmpty
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: productProvider.products.isNotEmpty
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  'Products: ${productProvider.products.length}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                productProvider.featuredProducts.isNotEmpty
                                    ? Icons.check_circle
                                    : Icons.error,
                                color:
                                    productProvider.featuredProducts.isNotEmpty
                                        ? Colors.green
                                        : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  'Featured Products: ${productProvider.featuredProducts.length}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                authProvider.isAuthenticated
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: authProvider.isAuthenticated
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  'User Authenticated: ${authProvider.isAuthenticated}'),
                            ],
                          ),
                          if (authProvider.isAuthenticated)
                            Padding(
                              padding: const EdgeInsets.only(left: 32, top: 4),
                              child: Text(
                                  'User: ${authProvider.user?.name ?? 'Unknown'}'),
                            ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _refreshAllDataFromProviders,
                            child: const Text('Refresh All Data'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Product Tests
                  if (_testResults.containsKey('products'))
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Products Test',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _testResults['products']?['success'] == true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _testResults['products']?['success'] ==
                                          true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Products: ${_testResults['products']?['count'] ?? 0}',
                                  style: TextStyle(
                                    color: _testResults['products']
                                                ?['success'] ==
                                            true
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Featured Products Tests
                  if (_testResults.containsKey('featuredProducts'))
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Featured Products Test',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _testResults['featuredProducts']
                                              ?['success'] ==
                                          true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _testResults['featuredProducts']
                                              ?['success'] ==
                                          true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Featured Products: ${_testResults['featuredProducts']?['count'] ?? 0}',
                                  style: TextStyle(
                                    color: _testResults['featuredProducts']
                                                ?['success'] ==
                                            true
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Logs
                  Text(
                    'Logs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color color = Colors.black;

                        if (log.contains('SUCCESS')) {
                          color = Colors.green;
                        } else if (log.contains('FAILED') ||
                            log.contains('Error')) {
                          color = Colors.red;
                        }

                        return Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
