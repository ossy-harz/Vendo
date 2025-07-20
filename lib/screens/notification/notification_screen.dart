import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../product/product_detail_screen.dart';
import '../service/service_detail_screen.dart';
import '../transaction/transaction_detail_screen.dart';
import '../chat/chat_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUser?.uid;
    
    if (currentUserId == null) {
      return const Center(
        child: Text('Please sign in to view your notifications'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              Provider.of<NotificationService>(context, listen: false)
                  .markAllNotificationsAsRead(currentUserId);
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: Provider.of<NotificationService>(context).getNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildNotificationItem(BuildContext context, AppNotification notification) {
    // Icon based on notification type
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        iconColor = Colors.blue;
        break;
      case NotificationType.offer:
        icon = Icons.local_offer_outlined;
        iconColor = Colors.green;
        break;
      case NotificationType.transaction:
        icon = Icons.receipt_long_outlined;
        iconColor = Colors.purple;
        break;
      case NotificationType.review:
        icon = Icons.star_outline;
        iconColor = Colors.amber;
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
        break;
    }
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<NotificationService>(context, listen: false)
            .deleteNotification(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.05),
        onTap: () {
          // Mark as read
          Provider.of<NotificationService>(context, listen: false)
              .markNotificationAsRead(notification.id);
          
          // Navigate based on notification type
          if (notification.relatedId != null) {
            _navigateToRelatedScreen(context, notification);
          }
        },
      ),
    );
  }
  
  void _navigateToRelatedScreen(BuildContext context, AppNotification notification) {
    switch (notification.type) {
      case NotificationType.message:
        if (notification.data != null && 
            notification.data!['chatId'] != null &&
            notification.data!['senderId'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: notification.data!['chatId'],
                recipientId: notification.data!['senderId'],
                recipientName: notification.data!['senderName'] ?? 'User',
              ),
            ),
          );
        }
        break;
      case NotificationType.transaction:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transactionId: notification.relatedId!,
            ),
          ),
        );
        break;
      case NotificationType.review:
        if (notification.data != null) {
          if (notification.data!['productId'] != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  productId: notification.data!['productId'],
                ),
              ),
            );
          } else if (notification.data!['serviceId'] != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(
                  serviceId: notification.data!['serviceId'],
                ),
              ),
            );
          }
        }
        break;
      default:
        break;
    }
  }
}

