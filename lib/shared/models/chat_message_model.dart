import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String type; // text | image | video | audio | file | system
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final int? audioDurationSeconds;
  final DateTime sentAt;
  final bool isRead;
  final List<String> readBy;

  const ChatMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.type,
    this.text,
    this.mediaUrl,
    this.fileName,
    this.fileSizeBytes,
    this.audioDurationSeconds,
    required this.sentAt,
    required this.isRead,
    required this.readBy,
  });

  bool get isMedia =>
      type == 'image' || type == 'video' || type == 'audio' || type == 'file';

  bool get isSystemMessage => type == 'system';

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderImageUrl: data['senderImageUrl'],
      type: data['type'] ?? 'text',
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      fileName: data['fileName'],
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt(),
      audioDurationSeconds: (data['audioDurationSeconds'] as num?)?.toInt(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'audioDurationSeconds': audioDurationSeconds,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'readBy': readBy,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    String? type,
    String? text,
    String? mediaUrl,
    String? fileName,
    int? fileSizeBytes,
    int? audioDurationSeconds,
    DateTime? sentAt,
    bool? isRead,
    List<String>? readBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }
}
