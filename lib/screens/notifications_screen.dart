import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() {
        _pendingNotifications = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showImmediateNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification from MedRec',
    );

    if (mounted) {
      AppSnackBar.showSuccess(context, 'Test notification sent!');
    }
  }

  Future<void> _cancelAllNotifications() async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Cancel All Notifications',
      message: 'Are you sure you want to cancel all scheduled notifications?',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
      isDangerous: true,
    );

    if (confirm == true) {
      await _notificationService.cancelAllNotifications();
      await _loadPendingNotifications();

      if (mounted) {
        AppSnackBar.showInfo(context, 'All notifications cancelled');
      }
    }
  }

  Future<void> _cancelNotification(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    await _notificationService.cancelNotification(id);
    await _loadPendingNotifications();

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading notifications...')
          : Column(
              children: [
                _buildHeader(),
                const Divider(),
                Expanded(child: _buildNotificationsList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active),
        title: const Text('Scheduled Notifications'),
        subtitle: Text('${_pendingNotifications.length} pending'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.send),
            label: const Text('Test Notification'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed:
                _pendingNotifications.isEmpty ? null : _cancelAllNotifications,
            icon: const Icon(Icons.clear_all),
            label: const Text('Cancel All'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    if (_pendingNotifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off,
        title: 'No pending notifications',
        subtitle: 'Appointment reminders will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingNotifications.length,
      itemBuilder: (context, index) {
        final notification = _pendingNotifications[index];
        return NotificationCard(
          notification: notification,
          onCancel: () => _cancelNotification(notification.id),
        );
      },
    );
  }
}

/// A card displaying a pending notification.
class NotificationCard extends StatelessWidget {
  final PendingNotificationRequest notification;
  final VoidCallback? onCancel;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.notifications,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          notification.title ?? 'Notification',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body ?? ''),
            const SizedBox(height: 4),
            Text(
              'ID: ${notification.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: onCancel,
          tooltip: 'Cancel notification',
        ),
      ),
    );
  }
}
