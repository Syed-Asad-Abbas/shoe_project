import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Map<String, dynamic> _salesOverview = {};
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, dynamic> _orderStatusDistribution = {};
  List<Map<String, dynamic>> _customerAcquisition = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final salesOverview = await _apiService.getSalesOverview();
      final salesData = await _apiService.getSalesData('weekly');
      final topProducts = await _apiService.getTopProducts();
      final orderStatusDistribution =
          await _apiService.getOrderStatusDistribution();
      final customerAcquisition = await _apiService.getCustomerAcquisition();

      setState(() {
        _salesOverview = salesOverview;
        _salesData = salesData;
        _topProducts = topProducts;
        _orderStatusDistribution = orderStatusDistribution;
        _customerAcquisition = customerAcquisition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading dashboard data...');
    }

    if (_hasError) {
      return ErrorContainer(
        message: _errorMessage,
        onRetry: _loadDashboardData,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            _buildStatsGrid(context),
            const SizedBox(height: 10),
            _buildRecentOrders(context),
            const SizedBox(height: 10),
            _buildSalesChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDashboardCard(
          title: 'Total Sales',
          subtitle:
              '\$${_salesOverview['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
          icon: Icons.attach_money,
          color: Colors.green[700]!,
          context: context,
        ),
        _buildDashboardCard(
          title: 'Orders',
          subtitle: '${_salesOverview['ordersCount'] ?? '0'}',
          icon: Icons.shopping_cart,
          color: Colors.blue[700]!,
          context: context,
        ),
        _buildDashboardCard(
          title: 'Products',
          subtitle: '${_salesOverview['productCount'] ?? '0'}',
          icon: Icons.inventory,
          color: Colors.orange[700]!,
          context: context,
        ),
        _buildDashboardCard(
          title: 'Customers',
          subtitle: '${_salesOverview['customerCount'] ?? '0'}',
          icon: Icons.people,
          color: Colors.purple[700]!,
          context: context,
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.arrow_upward,
                  color: Colors.green[700],
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${_salesOverview['weeklyChange']?.toString() ?? '0'}%',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  ' vs last week',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/orders');
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildTopProductsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No products data available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topProducts.length > 5 ? 5 : _topProducts.length,
      itemBuilder: (ctx, i) {
        final product = _topProducts[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  product['imageUrl'] ?? 'https://via.placeholder.com/150',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 20),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sales: ${product['sales'] ?? 0}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${product['revenue'] ?? 0}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: 'weekly',
              isDense: true,
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Weekly', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text('Monthly', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'yearly',
                  child: Text('Yearly', style: TextStyle(fontSize: 14)),
                ),
              ],
              onChanged: (value) {
                // Implement period change
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: _salesData.isEmpty
                            ? const Center(
                                child: Text('No sales data available'))
                            : _buildBarChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: _orderStatusDistribution.isEmpty
                            ? const Center(
                                child: Text('No order status data available'))
                            : _buildPieChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Acquisition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _customerAcquisition.isEmpty
                      ? const Center(child: Text('No customer data available'))
                      : _buildCustomerChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _salesData
                .map((data) => (data['sales'] as num))
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${_salesData[group.x.toInt()]['sales']}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= _salesData.length)
                  return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _salesData[value.toInt()]['date'].toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          _salesData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (_salesData[index]['sales'] as num).toDouble(),
                color: Colors.blue.shade700,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _salesData
                          .map((data) => (data['sales'] as num))
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final pieColors = [
      Colors.blue.shade500,
      Colors.green.shade500,
      Colors.orange.shade500,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade500,
    ];

    int i = 0;
    final sections = _orderStatusDistribution.entries.map((entry) {
      final color = pieColors[i % pieColors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: (entry.value as num).toDouble(),
        title: '${entry.value}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Text(
          entry.key,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
          ),
        ),
        badgePositionPercentageOffset: 1.4,
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 30,
        sectionsSpace: 2,
        startDegreeOffset: -90,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCustomerChart() {
    final List<FlSpot> spots = [];
    for (int i = 0; i < _customerAcquisition.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        (_customerAcquisition[i]['customers'] as num).toDouble(),
      ));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= _customerAcquisition.length)
                  return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _customerAcquisition[value.toInt()]['month'].toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple.shade400,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: Colors.purple.shade400,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  '${_customerAcquisition[touchedSpot.x.toInt()]['month']}: ${touchedSpot.y.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
