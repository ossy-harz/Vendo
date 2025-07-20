import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../chat/chat_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  
  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isLoading = true;
  Service? _service;
  Map<String, dynamic>? _providerData;
  bool _isMySelf = false;
  
  @override
  void initState() {
    super.initState();
    _loadService();
  }
  
  Future<void> _loadService() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final serviceService = Provider.of<ServiceService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Get service
      final service = await serviceService.getServiceById(widget.serviceId);
      
      if (service != null) {
        // Increment view count
        await serviceService.incrementViewCount(widget.serviceId);
        
        // Check if current user is the provider
        final currentUserId = authService.currentUser?.uid;
        final isMySelf = currentUserId == service.providerId;
        
        // Get provider data
        Map<String, dynamic>? providerData;
        if (!isMySelf) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(service.providerId)
              .get();
          providerData = doc.data();
        }
        
        if (mounted) {
          setState(() {
            _service = service;
            _providerData = providerData;
            _isMySelf = isMySelf;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service not found'),
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
            content: Text('Error loading service: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _markAsUnavailable() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final serviceService = Provider.of<ServiceService>(context, listen: false);
      await serviceService.markServiceAsUnavailable(widget.serviceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service marked as unavailable'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking service as unavailable: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _deleteService() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final serviceService = Provider.of<ServiceService>(context, listen: false);
      await serviceService.deleteService(widget.serviceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service deleted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting service: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _contactProvider() {
    if (_service == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          recipientId: _service!.providerId,
          recipientName: _providerData?['name'] ?? 'Provider',
          serviceId: _service!.id,
          serviceTitle: _service!.title,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        actions: [
          if (_isMySelf)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // Navigate to edit screen
                } else if (value == 'mark_unavailable') {
                  _markAsUnavailable();
                } else if (value == 'delete') {
                  _deleteService();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'mark_unavailable',
                  child: Text('Mark as Unavailable'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _service == null
              ? const Center(child: Text('Service not found'))
              : Column(
                  children: [
                    // Service details
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Images
                            _buildImageGallery(),
                            
                            // Service info
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and price
                                  Text(
                                    _service!.title,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${_service!.price.toStringAsFixed(2)} / ${_service!.priceType}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Location and date
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _service!.location,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(_service!.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Views
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_service!.viewCount} views',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Divider
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  
                                  // Details
                                  Text(
                                    'Details',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Category', _service!.category),
                                  const SizedBox(height: 16),
                                  
                                  // Description
                                  Text(
                                    'Description',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_service!.description),
                                  const SizedBox(height: 16),
                                  
                                  // Work History
                                  if (_service!.workHistory.isNotEmpty) ...[
                                    Text(
                                      'Work History',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _service!.workHistory.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          leading: const Icon(Icons.work_outline),
                                          title: Text(_service!.workHistory[index]),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Testimonials
                                  if (_service!.testimonials.isNotEmpty) ...[
                                    Text(
                                      'Testimonials',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _service!.testimonials.length,
                                      itemBuilder: (context, index) {
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.format_quote,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _service!.testimonials[index],
                                                        style: const TextStyle(
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Tags
                                  if (_service!.tags.isNotEmpty) ...[
                                    Text(
                                      'Tags',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _service!.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(tag),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Provider info
                                  if (!_isMySelf && _providerData != null) ...[
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Service Provider',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          child: _providerData!['photoUrl'] != null && _providerData!['photoUrl'].isNotEmpty
                                              ? null
                                              : Icon(
                                                  Icons.person,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _providerData!['name'] ?? 'Provider',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_providerData!['isVerified'] == true)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.verified,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Verified Provider',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Contact button
                    if (!_isMySelf)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: CustomButton(
                          text: 'Contact Provider',
                          onPressed: _contactProvider,
                        ),
                      ),
                  ],
                ),
    );
  }
  
  Widget _buildImageGallery() {
    if (_service!.images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            Icons.image,
            size: 100,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: _service!.images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: _service!.images[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

