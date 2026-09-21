import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApiClient.instance.getNotifications();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Endapo imeshindwa, orodha inabaki kama ilivyokuwa.
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _openItem(AppNotification item) async {
    if (item.isMessage) {
      if (item.propertyId == null || item.otherUserId == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            propertyId: item.propertyId!,
            otherUserId: item.otherUserId!,
            otherUserName: item.otherUserName ?? '',
          ),
        ),
      );
      _load();
    } else if (item.id != null && !item.isRead) {
      try {
        await ApiClient.instance.markNotificationRead(item.id!);
      } catch (_) {}
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arifa', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Column(children: [
                        Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.muted),
                        SizedBox(height: 12),
                        Text('Bado hujapata arifa yoyote.', style: TextStyle(color: AppTheme.muted)),
                      ]),
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final unread = !item.isRead;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: unread ? AppTheme.coral : AppTheme.sand,
                          child: Icon(
                            item.isMessage ? Icons.chat_bubble_rounded : Icons.campaign_rounded,
                            color: unread ? Colors.white : AppTheme.navy,
                            size: 20,
                          ),
                        ),
                        title: Text(item.title, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w700)),
                        subtitle: Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: unread ? AppTheme.navy : AppTheme.muted, fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
                        ),
                        trailing: Text(_formatWhen(item.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                        onTap: () => _openItem(item),
                      );
                    },
                  ),
      ),
    );
  }
}
