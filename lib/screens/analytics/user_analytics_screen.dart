import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      final userId = authService.currentUser!.uid;

      final statistics = await analyticsService.getUserStatistics(userId);

      if (mounted) {
        setState(() {
          _statistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    
                    // Listings section
                    Text(
                      'Listings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildListingsSection(),
                    const SizedBox(height: 24),
                    
                    // Transactions section
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildTransactionsSection(),
                    const SizedBox(height: 24),
                    
                    // Reviews section
                    Text(
                      'Reviews & Ratings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildReviewsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Earnings',
                value: currencyFormat.format(_statistics['totalEarnings'] ?? 0),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Spent',
                value: currencyFormat.format(_statistics['totalSpent'] ?? 0),
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Average Rating',
                value: (_statistics['averageRating'] ?? 0).toStringAsFixed(1),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Reviews',
                value: '${_statistics['reviewsCount'] ?? 0}',
                icon: Icons.rate_review,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              title: 'Products Listed',
              value: '${_statistics['productsCount'] ?? 0}',
              icon: Icons.shopping_bag_outlined,
            ),
            const Divider(),
            _buildStatRow(
              title: 'Services Listed',
              value: '${_statistics['servicesCount'] ?? 0}',
              icon: Icons.handyman_outlined,
            ),
            const Divider(),
            _buildStatRow(
              title: 'Products Sold',
              value: '${_statistics['soldProductsCount'] ?? 0}',
              icon: Icons.sell_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              title: 'Sales',
              value: '${_statistics['sellerTransactionsCount'] ?? 0}',
              icon: Icons.trending_up,
            ),
            const Divider(),
            _buildStatRow(
              title: 'Purchases',
              value: '${_statistics['buyerTransactionsCount'] ?? 0}',
              icon: Icons.shopping_cart_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              title: 'Reviews Received',
              value: '${_statistics['reviewsCount'] ?? 0}',
              icon: Icons.comment_outlined,
            ),
            const Divider(),
            _buildStatRow(
              title: 'Average Rating',
              value: '${(_statistics['averageRating'] ?? 0).toStringAsFixed(1)} ★',
              icon: Icons.star_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

