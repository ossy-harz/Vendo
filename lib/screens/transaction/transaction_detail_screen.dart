import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  Transaction? _transaction;
  Map<String, dynamic>? _buyerData;
  Map<String, dynamic>? _sellerData;
  bool _showReviewForm = false;
  final _reviewController = TextEditingController();
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactionService = Provider.of<TransactionService>(context, listen: false);
      final transaction = await transactionService.getTransactionById(widget.transactionId);

      if (transaction != null) {
        // Get buyer and seller data using the aliased Firestore instance.
        final buyerDoc = await firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(transaction.buyerId)
            .get();

        final sellerDoc = await firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(transaction.sellerId)
            .get();

        if (mounted) {
          setState(() {
            _transaction = transaction;
            _buyerData = buyerDoc.data();
            _sellerData = sellerDoc.data();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction not found'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTransactionStatus(TransactionStatus status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactionService = Provider.of<TransactionService>(context, listen: false);
      await transactionService.updateTransactionStatus(
        transactionId: widget.transactionId,
        status: status,
      );

      await _loadTransaction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTrackingNumber() async {
    final trackingController = TextEditingController();

    final trackingNumber = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tracking Number'),
        content: TextField(
          controller: trackingController,
          decoration: const InputDecoration(
            hintText: 'Enter tracking number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(trackingController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (trackingNumber != null && trackingNumber.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final transactionService = Provider.of<TransactionService>(context, listen: false);
        await transactionService.updateTransactionStatus(
          transactionId: widget.transactionId,
          status: _transaction!.status,
          trackingNumber: trackingNumber,
        );

        await _loadTransaction();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding tracking number: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionService = Provider.of<TransactionService>(context, listen: false);
      await transactionService.addReview(
        transactionId: widget.transactionId,
        rating: _rating,
        review: _reviewController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _showReviewForm = false;
        });

        await _loadTransaction();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: ${e.toString()}'),
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
        title: const Text('Transaction Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
          ? const Center(child: Text('Transaction not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction ID
            Text(
              'Transaction ID',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _transaction!.id,
              style: const TextStyle(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),

            // Status
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Item details
            Text(
              'Item Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _transaction!.type == TransactionType.product
                              ? Icons.shopping_bag_outlined
                              : Icons.handyman_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _transaction!.type == TransactionType.product
                              ? 'Product'
                              : 'Service',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transaction!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: \$${_transaction!.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    if (_transaction!.paymentMethod != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Payment Method: ${_transaction!.paymentMethod}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMM d, yyyy').format(_transaction!.createdAt)}',
                    ),
                    if (_transaction!.completedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Completed: ${DateFormat('MMM d, yyyy').format(_transaction!.completedAt!)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shipping details (for products)
            if (_transaction!.type == TransactionType.product) ...[
              Text(
                'Shipping Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_transaction!.shippingAddress != null) ...[
                        Text(
                          'Shipping Address:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_transaction!.shippingAddress!),
                        const SizedBox(height: 8),
                      ],
                      if (_transaction!.trackingNumber != null) ...[
                        Text(
                          'Tracking Number:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(_transaction!.trackingNumber!),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                // Open tracking link
                              },
                              child: const Text('Track'),
                            ),
                          ],
                        ),
                      ] else if (_transaction!.sellerId == Provider.of<AuthService>(context).currentUser!.uid) ...[
                        CustomButton(
                          text: 'Add Tracking Number',
                          onPressed: _addTrackingNumber,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Buyer and seller info
            Text(
              'Buyer & Seller',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buyer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_buyerData?['name'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seller',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_sellerData?['name'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            if (_transaction!.notes != null) ...[
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_transaction!.notes!),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Review form
            if (_showReviewForm) ...[
              Text(
                'Write a Review',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rating',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (int i = 1; i <= 5; i++)
                            IconButton(
                              icon: Icon(
                                i <= _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = i.toDouble();
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Review',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reviewController,
                        decoration: const InputDecoration(
                          hintText: 'Write your review here',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showReviewForm = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _submitReview,
                            child: const Text('Submit Review'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    // Determine status color based on the transaction status.
    Color statusColor;
    switch (_transaction!.status) {
      case TransactionStatus.completed:
        statusColor = Colors.green;
        break;
      case TransactionStatus.cancelled:
      case TransactionStatus.refunded:
        statusColor = Colors.red;
        break;
      case TransactionStatus.processing:
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(_transaction!.status),
              color: statusColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _transaction!.status.toString().split('.').last,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(_transaction!.status),
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending_outlined;
      case TransactionStatus.processing:
        return Icons.local_shipping_outlined;
      case TransactionStatus.completed:
        return Icons.check_circle_outline;
      case TransactionStatus.cancelled:
        return Icons.cancel_outlined;
      case TransactionStatus.refunded:
        return Icons.money_off_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDescription(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Waiting for processing';
      case TransactionStatus.processing:
        return 'Your order is being processed';
      case TransactionStatus.completed:
        return 'Transaction completed successfully';
      case TransactionStatus.cancelled:
        return 'Transaction has been cancelled';
      case TransactionStatus.refunded:
        return 'Payment has been refunded';
      default:
        return 'Unknown status';
    }
  }

  Widget _buildActionButtons() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isBuyer = _transaction!.buyerId == authService.currentUser!.uid;
    final isSeller = _transaction!.sellerId == authService.currentUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buyer actions
        if (isBuyer) ...[
          if (_transaction!.status == TransactionStatus.pending)
            CustomButton(
              text: 'Cancel Order',
              onPressed: () => _updateTransactionStatus(TransactionStatus.cancelled),
              backgroundColor: Colors.red.shade100,
              textColor: Colors.red,
            ),

          if (_transaction!.status == TransactionStatus.processing)
            CustomButton(
              text: 'Mark as Received',
              onPressed: () => _updateTransactionStatus(TransactionStatus.completed),
            ),

          if (_transaction!.status == TransactionStatus.completed && !_transaction!.isReviewed)
            CustomButton(
              text: 'Write a Review',
              onPressed: () {
                setState(() {
                  _showReviewForm = true;
                });
              },
            ),
        ],

        // Seller actions
        if (isSeller) ...[
          if (_transaction!.status == TransactionStatus.pending)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomButton(
                  text: 'Process Order',
                  onPressed: () => _updateTransactionStatus(TransactionStatus.processing),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Cancel Order',
                  onPressed: () => _updateTransactionStatus(TransactionStatus.cancelled),
                  backgroundColor: Colors.red.shade100,
                  textColor: Colors.red,
                ),
              ],
            ),

          if (_transaction!.status == TransactionStatus.processing && _transaction!.type == TransactionType.product)
            CustomButton(
              text: _transaction!.trackingNumber == null
                  ? 'Add Tracking Number'
                  : 'Update Tracking Number',
              onPressed: _addTrackingNumber,
            ),
        ],
      ],
    );
  }
}
