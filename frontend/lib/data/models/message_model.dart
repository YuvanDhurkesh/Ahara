class MessageModel {
  final String id;
  final String orderId;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderRole: json['senderRole'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'orderId': orderId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
