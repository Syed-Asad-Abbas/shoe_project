import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_container.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final orders = await _apiService.getAllOrders();
      setState(() {
        _orders = orders;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading orders...');
    }

    if (_hasError) {
      return ErrorContainer(
        message: _errorMessage,
        onRetry: _loadOrders,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Orders Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage and process customer orders',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildOrderFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: _orders.isEmpty ? _buildEmptyState() : _buildOrdersTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New orders will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          hint: const Text('Filter by Status'),
          onChanged: (String? newValue) {
            // Implement filter by status
          },
          items: <String>[
            'All',
            'Pending',
            'Processing',
            'Shipped',
            'Delivered',
            'Cancelled',
            'Refunded'
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOrdersTable() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _buildOrderRow(order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Row(
      children: [
        SizedBox(
            width: 100,
            child: Text('Order ID',
                style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(
            width: 120,
            child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(
            width: 150,
            child: Text('Customer',
                style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(
            width: 120,
            child:
                Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(
            width: 120,
            child:
                Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            child:
                Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildOrderRow(Order order) {
    return InkWell(
      onTap: () => _showOrderDetails(order),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                _safeSubstring(order.id, 0, 6) + '...',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                _formatDate(order.orderDate),
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                order.customerName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: _buildStatusChip(order.status),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _showOrderDetails(order),
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditStatusDialog(order),
                    tooltip: 'Edit Status',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.processing:
        color = Colors.blue;
        label = 'Processing';
        break;
      case OrderStatus.shipped:
        color = Colors.indigo;
        label = 'Shipped';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        label = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('Order #${_safeSubstring(order.id, 0, 6)}'),
            const Spacer(),
            _buildStatusChip(order.status),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection(
                  'Order Information',
                  [
                    {'ID': order.id},
                    {'Date': _formatDate(order.orderDate)},
                    {'Status': _getStatusString(order.status)},
                    {'Total Amount': '\$${order.total.toStringAsFixed(2)}'},
                  ],
                ),
                const Divider(),
                _buildDetailSection(
                  'Customer Information',
                  [
                    {'Name': order.customerName},
                    {'Email': order.customerEmail},
                    {'Payment Method': order.paymentMethod},
                  ],
                ),
                const Divider(),
                _buildDetailSection(
                  'Shipping Information',
                  [
                    {'Address': order.shippingAddress},
                    {
                      'Tracking Number': order.trackingNumber ?? 'Not available'
                    },
                    {
                      'Expected Delivery': order.deliveryDate != null
                          ? _formatDate(order.deliveryDate!)
                          : 'Not available'
                    },
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Ordered Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items
                    .map((item) => _buildOrderItemCard(item))
                    .toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _showEditStatusDialog(order),
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Map<String, String>> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...details.map((detail) {
          final entry = detail.entries.first;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(entry.value),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.network(
              item.product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Size: ${item.size}, Color: ${item.color ?? "N/A"}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusString(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  void _showEditStatusDialog(Order order) {
    OrderStatus selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Order Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Order #${_safeSubstring(order.id, 0, 6)}'),
                const SizedBox(height: 16),
                const Text('Current Status:'),
                const SizedBox(height: 8),
                _buildStatusChip(order.status),
                const SizedBox(height: 16),
                const Text('New Status:'),
                const SizedBox(height: 8),
                DropdownButton<OrderStatus>(
                  value: selectedStatus,
                  onChanged: (OrderStatus? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedStatus = newValue;
                      });
                    }
                  },
                  items: OrderStatus.values
                      .map<DropdownMenuItem<OrderStatus>>((OrderStatus value) {
                    return DropdownMenuItem<OrderStatus>(
                      value: value,
                      child: Text(_getStatusString(value)),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Updating order status...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  try {
                    await _apiService.updateOrderStatus(
                        order.id, selectedStatus);
                    if (!mounted) return;

                    // Refresh orders list
                    _loadOrders();

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order status updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to update order status: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Add a safe substring function to avoid range errors
  String _safeSubstring(String text, int start, int end) {
    if (text.isEmpty) return '';

    int safeStart = start.clamp(0, text.length);
    int safeEnd = end.clamp(0, text.length);

    if (safeStart >= safeEnd) return '';
    return text.substring(safeStart, safeEnd);
  }
}
