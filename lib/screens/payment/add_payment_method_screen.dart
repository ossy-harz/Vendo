import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would use a package like stripe_sdk to collect card details securely
      // For this demo, we'll simulate adding a card
      
      // Parse expiry date
      final expiryParts = _expiryController.text.split('/');
      final expMonth = int.parse(expiryParts[0].trim());
      final expYear = int.parse('20${expiryParts[1].trim()}');
      
      // Get last 4 digits of card number
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final last4 = cardNumber.substring(cardNumber.length - 4);
      
      // Determine card brand (simplified)
      String brand = 'unknown';
      if (cardNumber.startsWith('4')) {
        brand = 'visa';
      } else if (cardNumber.startsWith('5')) {
        brand = 'mastercard';
      } else if (cardNumber.startsWith('3')) {
        brand = 'amex';
      }
      
      // Generate a fake payment method ID
      final paymentMethodId = 'pm_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save to Firestore
      final authService = Provider.of<AuthService>(context, listen: false);
      final stripeService = Provider.of<StripePaymentService>(context, listen: false);
      final userId = authService.currentUser!.uid;
      
      await stripeService.savePaymentMethod(
        userId: userId,
        paymentMethodId: paymentMethodId,
        brand: brand,
        last4: last4,
        expMonth: expMonth,
        expYear: expYear,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment method: ${e.toString()}'),
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
        title: const Text('Add Payment Method'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card details
              Text(
                'Card Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Card number
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '4242 4242 4242 4242',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  final cardNumber = value.replaceAll(' ', '');
                  if (cardNumber.length < 16) {
                    return 'Please enter a valid card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Expiry and CVC
              Row(
                children: [
                  // Expiry date
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                          return 'Use MM/YY format';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // CVC
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Invalid CVC';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Cardholder name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Add button
              CustomButton(
                text: 'Add Card',
                isLoading: _isLoading,
                onPressed: _addPaymentMethod,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

