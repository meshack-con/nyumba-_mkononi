class AppNotification {
  const AppNotification({
    this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.propertyId,
    this.otherUserId,
    this.otherUserName,
  });

  final int? id;
  final String kind; // "system" au "message"
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final int? propertyId;
  final int? otherUserId;
  final String? otherUserName;

  bool get isMessage => kind == 'message';

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int?,
        kind: json['kind'] as String? ?? 'system',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
        propertyId: json['property_id'] as int?,
        otherUserId: json['other_user_id'] as int?,
        otherUserName: json['other_user_name'] as String?,
      );
}
