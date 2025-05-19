import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard/chart_container.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_container.dart';

class AnalyticsScreen extends StatefulWidget {
  static const String routeName = '/analytics';

  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Map<String, dynamic> _salesOverview = {};
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _customersByRegion = [];
  List<Map<String, dynamic>> _categoryPerformance = [];
  List<Map<String, dynamic>> _customerAcquisition = [];

  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final salesOverview = await _apiService.getSalesOverview();
      final salesData = await _apiService.getSalesByPeriod(_selectedPeriod);
      final customersByRegion = await _apiService.getCustomersByRegion();
      final categoryPerformance = await _apiService.getCategoryPerformance();
      final customerAcquisition = await _apiService.getCustomerAcquisition();

      setState(() {
        _salesOverview = salesOverview;
        _salesData = salesData;
        _customersByRegion = customersByRegion;
        _categoryPerformance = categoryPerformance;
        _customerAcquisition = customerAcquisition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading analytics data...');
    }

    if (_hasError) {
      return ErrorContainer(
        message: _errorMessage,
        onRetry: _loadAnalyticsData,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),
          _buildOverviewCards(),
          const SizedBox(height: 30),
          _buildSalesChart(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildCustomersByRegion(),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: _buildCategoryPerformance(),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildCustomerAcquisitionChart(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'daily',
          label: Text('Daily'),
        ),
        ButtonSegment<String>(
          value: 'weekly',
          label: Text('Weekly'),
        ),
        ButtonSegment<String>(
          value: 'monthly',
          label: Text('Monthly'),
        ),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (Set<String> selection) {
        _changePeriod(selection.first);
      },
    );
  }

  Widget _buildOverviewCards() {
    final formatter = NumberFormat.currency(symbol: '\$');

    return GridView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      children: [
        _buildOverviewCard(
          'Total Revenue',
          formatter.format(_salesOverview['totalSales'] ?? 0),
          Icons.attach_money,
          Colors.green,
          _salesOverview['salesChange'] ?? 0,
        ),
        _buildOverviewCard(
          'Orders',
          '${_salesOverview['ordersCount'] ?? 0}',
          Icons.shopping_cart,
          Colors.blue,
          _salesOverview['ordersChange'] ?? 0,
        ),
        _buildOverviewCard(
          'Average Order',
          formatter.format(_salesOverview['averageOrderValue'] ?? 0),
          Icons.shopping_bag,
          Colors.orange,
          _salesOverview['aovChange'] ?? 0,
        ),
        _buildOverviewCard(
          'Conversion Rate',
          '${_salesOverview['conversionRate'] ?? 0}%',
          Icons.trending_up,
          Colors.purple,
          _salesOverview['conversionChange'] ?? 0,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double percentChange,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  percentChange >= 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: percentChange >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: percentChange >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'vs last period',
                  style: TextStyle(
                    color: Colors.grey[600],
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

  Widget _buildSalesChart() {
    return ChartContainer(
      title: 'Sales Trend',
      height: 350,
      child: _salesData.isEmpty
          ? const Center(child: Text('No sales data available'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= _salesData.length) {
                          return const SizedBox.shrink();
                        }

                        String dateStr = _salesData[value.toInt()]['date'];
                        DateTime date = DateTime.parse(dateStr);
                        String formattedDate = '';

                        switch (_selectedPeriod) {
                          case 'daily':
                            formattedDate = DateFormat('d').format(date);
                            break;
                          case 'weekly':
                            formattedDate = DateFormat('MMM d').format(date);
                            break;
                          case 'monthly':
                            formattedDate = DateFormat('MMM').format(date);
                            break;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: _salesData.length - 1.0,
                minY: 0,
                maxY: _salesData.isEmpty
                    ? 1000
                    : _salesData
                            .map((data) => data['sales'] as num)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _salesData.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        (_salesData[index]['sales'] as num).toDouble(),
                      ),
                    ),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.5),
                        Theme.of(context).primaryColor,
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.2),
                          Theme.of(context).primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCustomersByRegion() {
    return ChartContainer(
      title: 'Customers by Region',
      height: 350,
      child: _customersByRegion.isEmpty
          ? const Center(child: Text('No region data available'))
          : PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _getRegionSections(),
              ),
            ),
    );
  }

  List<PieChartSectionData> _getRegionSections() {
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    for (int i = 0; i < _customersByRegion.length; i++) {
      final data = _customersByRegion[i];
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: (data['percentage'] as num).toDouble(),
          title: '${data['percentage']}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildCategoryPerformance() {
    return ChartContainer(
      title: 'Category Performance',
      height: 350,
      child: _categoryPerformance.isEmpty
          ? const Center(child: Text('No category data available'))
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _categoryPerformance.isEmpty
                    ? 100
                    : _categoryPerformance
                            .map((data) => data['revenue'] as num)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= _categoryPerformance.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _categoryPerformance[value.toInt()]['category'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                barGroups: List.generate(
                  _categoryPerformance.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (_categoryPerformance[index]['revenue'] as num)
                            .toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade300,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerAcquisitionChart() {
    return ChartContainer(
      title: 'Customer Acquisition Trend',
      height: 300,
      child: _customerAcquisition.isEmpty
          ? const Center(child: Text('No customer acquisition data available'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= _customerAcquisition.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _customerAcquisition[value.toInt()]['month'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: _customerAcquisition.length - 1.0,
                minY: 0,
                maxY: _customerAcquisition.isEmpty
                    ? 10
                    : _customerAcquisition
                            .map((data) => data['customers'] as num)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _customerAcquisition.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        (_customerAcquisition[index]['customers'] as num)
                            .toDouble(),
                      ),
                    ),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade300,
                        Colors.orange.shade700,
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade300.withOpacity(0.2),
                          Colors.orange.shade300.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
