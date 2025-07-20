import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final stripeService = Provider.of<StripePaymentService>(context, listen: false);
      final userId = authService.currentUser!.uid;

      final paymentMethods = await stripeService.getUserPaymentMethods(userId);

      if (mounted) {
        setState(() {
          _paymentMethods = paymentMethods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment methods: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final stripeService = Provider.of<StripePaymentService>(context, listen: false);
      final userId = authService.currentUser!.uid;

      await stripeService.setDefaultPaymentMethod(
        userId: userId,
        paymentMethodId: paymentMethodId,
      );

      await _loadPaymentMethods();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting default payment method: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePaymentMethod(String paymentMethodId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final stripeService = Provider.of<StripePaymentService>(context, listen: false);
      final userId = authService.currentUser!.uid;

      await stripeService.deletePaymentMethod(
        userId: userId,
        paymentMethodId: paymentMethodId,
      );

      await _loadPaymentMethods();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing payment method: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentMethods,
              child: _paymentMethods.isEmpty
                  ? _buildEmptyState()
                  : _buildPaymentMethodsList(),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          text: 'Add Payment Method',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddPaymentMethodScreen(),
              ),
            ).then((_) => _loadPaymentMethods());
          },
          icon: Icons.add,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No payment methods added yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a payment method to make purchases',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final paymentMethod = _paymentMethods[index];
        return _buildPaymentMethodCard(paymentMethod);
      },
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> paymentMethod) {
    final bool isDefault = paymentMethod['isDefault'] ?? false;
    final String brand = paymentMethod['brand'] ?? 'card';
    final String last4 = paymentMethod['last4'] ?? '****';
    final int expMonth = paymentMethod['expMonth'] ?? 12;
    final int expYear = paymentMethod['expYear'] ?? 2025;
    final String paymentMethodId = paymentMethod['paymentMethodId'] ?? '';

    IconData cardIcon;
    switch (brand.toLowerCase()) {
      case 'visa':
        cardIcon = Icons.credit_card;
        break;
      case 'mastercard':
        cardIcon = Icons.credit_card;
        break;
      case 'amex':
        cardIcon = Icons.credit_card;
        break;
      default:
        cardIcon = Icons.credit_card;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          cardIcon,
          color: Theme.of(context).colorScheme.primary,
          size: 36,
        ),
        title: Row(
          children: [
            Text(
              '${brand.capitalize()} •••• $last4',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isDefault)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('Expires $expMonth/$expYear'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'default') {
              _setDefaultPaymentMethod(paymentMethodId);
            } else if (value == 'delete') {
              _deletePaymentMethod(paymentMethodId);
            }
          },
          itemBuilder: (context) => [
            if (!isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

