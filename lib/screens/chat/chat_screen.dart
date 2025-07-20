import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String recipientId;
  final String recipientName;
  final String? productId;
  final String? productTitle;
  final String? serviceId;
  final String? serviceTitle;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.recipientId,
    required this.recipientName,
    this.productId,
    this.productTitle,
    this.serviceId,
    this.serviceTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  String? _chatId;
  bool _isLoading = false;
  bool _showOfferInput = false;
  final TextEditingController _offerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    if (_chatId != null) {
      // Mark messages as read
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      await chatService.markMessagesAsRead(
        chatId: _chatId!,
        userId: authService.currentUser!.uid,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // Create or get chat room
      final chatId = await chatService.createOrGetChatRoom(
        currentUserId: authService.currentUser!.uid,
        otherUserId: widget.recipientId,
        productId: widget.productId,
        productTitle: widget.productTitle,
        serviceId: widget.serviceId,
        serviceTitle: widget.serviceTitle,
      );
      
      if (mounted) {
        setState(() {
          _chatId = chatId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    chatService.sendMessage(
      chatId: _chatId!,
      senderId: authService.currentUser!.uid,
      content: _messageController.text.trim(),
      productId: widget.productId,
      serviceId: widget.serviceId,
    );
    
    _messageController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      await chatService.sendImageMessage(
        chatId: _chatId!,
        senderId: authService.currentUser!.uid,
        imageFile: File(pickedFile.path),
        productId: widget.productId,
        serviceId: widget.serviceId,
      );
    }
  }

  void _sendOffer() {
    if (_offerController.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    chatService.sendOffer(
      chatId: _chatId!,
      senderId: authService.currentUser!.uid,
      amount: _offerController.text.trim(),
      productId: widget.productId,
      serviceId: widget.serviceId,
    );
    
    _offerController.clear();
    setState(() {
      _showOfferInput = false;
    });
  }

  Future<void> _updateOfferStatus(String messageId, String status) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.updateOfferStatus(
      messageId: messageId,
      status: status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show chat info
            },
          ),
        ],
      ),
      body: _isLoading || _chatId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Product/Service info
                if (widget.productTitle != null || widget.serviceTitle != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      children: [
                        Icon(
                          widget.productTitle != null
                              ? Icons.shopping_bag
                              : Icons.handyman,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.productTitle ?? widget.serviceTitle ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Messages
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: Provider.of<ChatService>(context).getMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet. Say hello!',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }

                      // Mark messages as read
                      final authService = Provider.of<AuthService>(context);
                      final chatService = Provider.of<ChatService>(context);
                      
                      chatService.markMessagesAsRead(
                        chatId: _chatId!,
                        userId: authService.currentUser!.uid,
                      );

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == authService.currentUser!.uid;
                          
                          return _buildMessageItem(message, isMe);
                        },
                      );
                    },
                  ),
                ),
                
                // Offer input
                if (_showOfferInput)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _offerController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Enter offer amount',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _sendOffer,
                          child: const Text('Send Offer'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showOfferInput = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                
                // Message input
                Container(
                  padding: const EdgeInsets.all(8),
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
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_money),
                        onPressed: () {
                          setState(() {
                            _showOfferInput = !_showOfferInput;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: _sendImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, bool isMe) {
    final authService = Provider.of<AuthService>(context);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image message
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  message.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Offer message
            if (message.offerAmount != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 16,
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${message.offerAmount}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (message.offerStatus == 'pending' && !isMe)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateOfferStatus(message.id, 'accepted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateOfferStatus(message.id, 'rejected'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      )
                    else if (message.offerStatus == 'accepted')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Accepted',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    else if (message.offerStatus == 'rejected')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Declined',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              )
            // Text message
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                  ),
                ),
              ),
            
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
                bottom: 6,
                left: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.jm().format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isMe)
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: Colors.white70,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

