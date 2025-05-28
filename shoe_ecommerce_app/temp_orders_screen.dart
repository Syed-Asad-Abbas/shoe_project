/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/admin_drawer.dart';
import '../../../services/order_service.dart';
import '../../../models/order.dart';
import '../../../models/cart_item.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/admin/orders';

  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';
  String _sortBy = 'Date (newest)';
  bool _isSearching = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);

    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get orders from the backend
      final orders = await _orderService.getAllOrders();

      setState(() {
        _orders = orders;
        _applyFilters(); // This will set _filteredOrders
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load orders: ${e.toString()}';
      });
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      switch (_tabController.index) {
        case 0: // All
          _filterStatus = 'All';
          break;
        case 1: // Processing
          _filterStatus = 'Processing';
          break;
        case 2: // Shipped
          _filterStatus = 'Shipped';
          break;
        case 3: // Delivered
          _filterStatus = 'Delivered';
          break;
        case 4: // Other
          _filterStatus = 'Other';
          break;
      }
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Apply status filter
        if (_filterStatus != 'All' && _filterStatus != 'Other') {
          // Convert OrderStatus enum to string for comparison
          String orderStatus = _getStatusString(order.status);
          if (orderStatus != _filterStatus) return false;
        } else if (_filterStatus == 'Other') {
          String orderStatus = _getStatusString(order.status);
          if (orderStatus == 'Processing' ||
              orderStatus == 'Shipped' ||
              orderStatus == 'Delivered') {
            return false;
          }
        }

        // Apply search filter if any
        if (_searchController.text.isNotEmpty) {
          String searchTerm = _searchController.text.toLowerCase();
          return order.id.toLowerCase().contains(searchTerm) ||
              order.customerName.toLowerCase().contains(searchTerm);
        }

        return true;
      }).toList();

      // Apply sorting
      _applySorting();
    });
  }

  String _getStatusString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  OrderStatus _getStatusEnum(String status) {
    switch (status) {
      case 'Pending':
        return OrderStatus.pending;
      case 'Processing':
        return OrderStatus.processing;
      case 'Shipped':
        return OrderStatus.shipped;
      case 'Delivered':
        return OrderStatus.delivered;
      case 'Cancelled':
        return OrderStatus.cancelled;
      case 'Refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'Date (newest)':
        _filteredOrders.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Date (oldest)':
        _filteredOrders.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Total (highest)':
        _filteredOrders.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'Total (lowest)':
        _filteredOrders.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'Customer (A-Z)':
        _filteredOrders
            .sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case 'Customer (Z-A)':
        _filteredOrders
            .sort((a, b) => b.customerName.compareTo(a.customerName));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search orders...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                onChanged: (value) {
                  _applyFilters();
                },
              )
            : const Text('Orders'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _applyFilters();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applySorting();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Date (newest)',
                child: Text('Date (newest)'),
              ),
              const PopupMenuItem(
                value: 'Date (oldest)',
                child: Text('Date (oldest)'),
              ),
              const PopupMenuItem(
                value: 'Total (highest)',
                child: Text('Total (highest)'),
              ),
              const PopupMenuItem(
                value: 'Total (lowest)',
                child: Text('Total (lowest)'),
              ),
              const PopupMenuItem(
                value: 'Customer (A-Z)',
                child: Text('Customer (A-Z)'),
              ),
              const PopupMenuItem(
                value: 'Customer (Z-A)',
                child: Text('Customer (Z-A)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Processing'),
            Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      drawer: const AdminDrawer(currentRoute: OrdersScreen.routeName),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorWidget()
              : _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _filterStatus != 'All')
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _tabController.animateTo(0);
                                setState(() {
                                  _filterStatus = 'All';
                                  _applyFilters();
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateOrderDialog();
        },
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Define colors for different statuses
    final statusColors = {
      'Processing': Colors.blue,
      'Shipped': Colors.orange,
      'Delivered': Colors.green,
      'Cancelled': Colors.red,
      'Refunded': Colors.purple,
    };

    final Color statusColor =
        statusColors[_getStatusString(order.status)] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header with ID and date
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(order.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: statusColor,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        _getStatusString(order.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Order details in 2 columns
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Items', '${order.items.length}'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Payment', order.paymentMethod),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              'Total',
                              NumberFormat.currency(symbol: '\$')
                                  .format(order.totalAmount)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Email', order.email),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Shipping address
                _buildDetailRow('Shipping Address', order.shippingAddress),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _showOrderDetailsDialog(order);
                  },
                  child: const Text('View Details'),
                ),
                TextButton(
                  onPressed: () {
                    _showUpdateStatusDialog(order);
                  },
                  child: const Text('Update Status'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.filter_list),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildFilterChip('All', _filterStatus, (val) {
                        setState(() {
                          _filterStatus = 'All';
                        });
                      }),
                      _buildFilterChip('Processing', _filterStatus, (val) {
                        setState(() {
                          _filterStatus = 'Processing';
                        });
                      }),
                      _buildFilterChip('Shipped', _filterStatus, (val) {
                        setState(() {
                          _filterStatus = 'Shipped';
                        });
                      }),
                      _buildFilterChip('Delivered', _filterStatus, (val) {
                        setState(() {
                          _filterStatus = 'Delivered';
                        });
                      }),
                      _buildFilterChip('Cancelled', _filterStatus, (val) {
                        setState(() {
                          _filterStatus = 'Cancelled';
                        });
                      }),
                      _buildFilterChip('Refunded', _filterStatus, (val) {
                        setState(() {
                          _filterStatus = 'Refunded';
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Update the tab controller to match the filter
                            switch (_filterStatus) {
                              case 'All':
                                _tabController.animateTo(0);
                                break;
                              case 'Processing':
                                _tabController.animateTo(1);
                                break;
                              case 'Shipped':
                                _tabController.animateTo(2);
                                break;
                              case 'Delivered':
                                _tabController.animateTo(3);
                                break;
                              default:
                                _tabController.animateTo(4);
                                break;
                            }

                            // Apply filters and close the sheet
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
      String label, String selectedValue, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selectedValue == label,
      onSelected: onSelected,
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
    );
  }

  void _showOrderDetailsDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(order.id),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Order Information', [
                _buildDetailItem('Date',
                    DateFormat('MMMM dd, yyyy • hh:mm a').format(order.date)),
                _buildDetailItem('Status', _getStatusString(order.status)),
                _buildDetailItem(
                    'Total',
                    NumberFormat.currency(symbol: '\$')
                        .format(order.totalAmount)),
                _buildDetailItem('Items', '${order.items.length}'),
                _buildDetailItem('Payment Method', order.paymentMethod),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Customer Information', [
                _buildDetailItem('Name', order.customerName),
                _buildDetailItem('Email', order.email),
                _buildDetailItem('Phone', order.phone),
                _buildDetailItem('Shipping Address', order.shippingAddress),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Order Items', [
                // This is a mock - in a real app you would list actual order items
                _buildOrderItemRow(
                    'Running Shoes - Black', 'Size 10', 1, 89.99),
                _buildOrderItemRow('Athletic Socks', 'Medium', 2, 12.50),
                if (order.items.length >= 3)
                  _buildOrderItemRow('Shoe Cleaner Kit', '', 1, 24.99),
                if (order.items.length >= 4)
                  _buildOrderItemRow('Insoles - Sport', 'Size 10', 1, 29.99),
                if (order.items.length >= 5)
                  _buildOrderItemRow('Shoelaces', 'Black', 1, 4.99),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Order Summary', [
                _buildDetailItem(
                    'Subtotal',
                    NumberFormat.currency(symbol: '\$')
                        .format(order.totalAmount * 0.9)),
                _buildDetailItem('Shipping', '\$9.99'),
                _buildDetailItem(
                    'Tax',
                    NumberFormat.currency(symbol: '\$')
                        .format(order.totalAmount * 0.06)),
                const Divider(),
                _buildDetailItem(
                    'Total',
                    NumberFormat.currency(symbol: '\$')
                        .format(order.totalAmount),
                    isBold: true),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, you would print or generate an invoice here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice printed successfully')),
              );
            },
            child: const Text('Print Invoice'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateStatusDialog(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
            ),
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(
      String name, String variant, int quantity, double price) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (variant.isNotEmpty)
                  Text(
                    variant,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Text('x$quantity'),
          const SizedBox(width: 12),
          Text(
            NumberFormat.currency(symbol: '\$').format(price),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(Order order) {
    String selectedStatus = _getStatusString(order.status);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('Update Order ${order.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioTile('Processing', selectedStatus, (value) {
                setState(() {
                  selectedStatus = value!;
                });
              }),
              _buildRadioTile('Shipped', selectedStatus, (value) {
                setState(() {
                  selectedStatus = value!;
                });
              }),
              _buildRadioTile('Delivered', selectedStatus, (value) {
                setState(() {
                  selectedStatus = value!;
                });
              }),
              _buildRadioTile('Cancelled', selectedStatus, (value) {
                setState(() {
                  selectedStatus = value!;
                });
              }),
              _buildRadioTile('Refunded', selectedStatus, (value) {
                setState(() {
                  selectedStatus = value!;
                });
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updating order status...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  // Update the order status in the backend
                  final OrderStatus newStatus = _getStatusEnum(selectedStatus);
                  await _orderService.updateOrderStatus(order.id, newStatus);

                  // Refresh the orders list
                  _loadOrders();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Order ${order.id} updated to $selectedStatus'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update order: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
              ),
              child: const Text('Update'),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRadioTile(
      String title, String groupValue, Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Text(title),
      value: title,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.blue[800],
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showCreateOrderDialog() {
    final _formKey = GlobalKey<FormState>();
    final customerNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Order'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Shipping Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shipping address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: Product selection would be added in a complete version',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Creating order...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  // Create new order data
                  final orderData = {
                    'customerName': customerNameController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                    'shippingAddress': addressController.text,
                    'products':
                        [], // In a real app, we would add selected products
                    'paymentMethod': 'Credit Card', // Default for now
                  };

                  // Create the order in the backend
                  await _orderService.createOrder(orderData);

                  // Refresh the orders list
                  _loadOrders();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order created successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create order: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
            ),
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
*/