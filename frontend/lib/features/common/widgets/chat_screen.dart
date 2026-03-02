import 'package:flutter/material.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/backend_service.dart';
import '../../../data/services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String currentUserId;
  final String currentUserRole;
  final String recipientName;
  final String recipientRole;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.currentUserId,
    required this.currentUserRole,
    required this.recipientName,
    required this.recipientRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  Future<void> _loadMessages() async {
    try {
      final rawMessages = await BackendService.getOrderMessages(widget.orderId);
      final messages = rawMessages.map((json) => MessageModel.fromJson(json)).toList();
      
      // Filter out messages not meant for this chat window
      // We only want:
      // 1. Messages WE sent TO them (where we are the sender role, and we know the other side) 
      //    Wait, the database doesn't store recipient. It just stores who sent it to the broadcast room.
      // So in the history, we only want messages sent by us or by the target recipient.
      final filteredMessages = messages.where((m) {
        return m.senderRole == widget.currentUserRole || m.senderRole == widget.recipientRole;
      }).toList();

      if (mounted) {
        setState(() {
          _messages = filteredMessages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error loading messages: \$e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupSocket() {
    SocketService.joinOrderRoom(widget.orderId);
    
    SocketService.onReceiveMessage((data) {
    if (data['orderId'] == widget.orderId) {
      final newMessage = MessageModel.fromJson(data);
      if (!_messages.any((m) => m.id == newMessage.id && m.id.isNotEmpty)) {
        // ONLY append the message to the view if it matches the role we are talking to
        if (newMessage.senderRole == widget.recipientRole || 
            newMessage.senderRole == widget.currentUserRole) {
           setState(() {
             _messages.add(newMessage);
           });
           _scrollToBottom();
        }
      }
    }
  });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Send through Socket
    SocketService.sendMessage(
      orderId: widget.orderId,
      senderId: widget.currentUserId,
      senderRole: widget.currentUserRole,
      text: text,
    );

    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    SocketService.offReceiveMessage();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final isMe = msg.senderId == widget.currentUserId;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.orange.shade600 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                msg.senderRole.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            if (!isMe) const SizedBox(height: 2),
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.recipientName),
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleTextStyle: const TextStyle(
          color: Colors.black87, 
          fontSize: 18, 
          fontWeight: FontWeight.w600
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          "No messages yet. Say hi!",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                )
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 12
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
