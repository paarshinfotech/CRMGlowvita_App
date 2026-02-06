import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Sample notification data
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'Appointment Reminder',
      'channels': ['Push', 'SMS'],
      'target': 'All Online',
      'date': '2025-11-20 09:00 AM',
      'status': 'Sent',
    },
    {
      'id': '2',
      'title': 'Special Offer',
      'channels': ['Push'],
      'target': 'Specific Clients',
      'date': '2025-11-19 02:30 PM',
      'status': 'Sent',
    },
    {
      'id': '3',
      'title': 'Service Update',
      'channels': ['SMS'],
      'target': 'All Staffs',
      'date': '2025-11-18 11:15 AM',
      'status': 'Scheduled',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Notifications'),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.4,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCreateNotificationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create New Notification',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Notification History',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildNotificationHistory(),
          ],
        ),
      ),
    );
  }

  // ---------- Stats section (SMS + Most Targeted on second line) ----------

  Widget _buildStatsSection() {
    final totalSent = notifications.where((n) => n['status'] == 'Sent').length;
    final pushSent = notifications
        .where((n) => n['channels'].contains('Push') && n['status'] == 'Sent')
        .length;
    final smsSent = notifications
        .where((n) => n['channels'].contains('SMS') && n['status'] == 'Sent')
        .length;

    String mostTargeted = 'None';
    if (notifications.isNotEmpty) {
      final targetCounts = <String, int>{};
      for (var notification in notifications) {
        final target = notification['target'] as String;
        targetCounts[target] = (targetCounts[target] ?? 0) + 1;
      }
      if (targetCounts.isNotEmpty) {
        mostTargeted = targetCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // first row – Total + Push
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatCard('Total Sent', '$totalSent', Icons.send),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Push Sent',
                  '$pushSent',
                  Icons.notifications_active,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // second row – SMS + Most Targeted side‑by‑side
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatCard('SMS Sent', '$smsSent', Icons.sms),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Most Targeted',
                  mostTargeted,
                  Icons.group,
                  isMostTargeted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    bool isMostTargeted = false,
  }) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isMostTargeted ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------- Notification history ----------

  Widget _buildNotificationHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: notifications
            .map((notification) => _buildNotificationCard(notification))
            .toList(),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status'] as String;
    final channels = notification['channels'] as List<String>;

    Color statusColor;
    switch (status) {
      case 'Sent':
        statusColor = Theme.of(context).primaryColor; // active brand color
        break;
      case 'Scheduled':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    notification['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // content
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Channel', channels.join(', ')),
                const SizedBox(height: 6),
                _buildInfoRow('Target', notification['target'] as String),
                const SizedBox(height: 6),
                _buildInfoRow('Date', notification['date'] as String),
              ],
            ),
          ),
          // actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _editNotification(notification),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _deleteNotification(notification),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Edit & Delete using reusable dialog ----------

  void _editNotification(Map<String, dynamic> notification) {
    final index = notifications.indexOf(notification);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return NotificationDialog(
          mode: NotificationDialogMode.edit,
          initialNotification: notification,
          onSubmit: (updated) {
            setState(() {
              notifications[index] = updated;
            });
          },
        );
      },
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    final index = notifications.indexOf(notification);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Delete Notification',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this notification?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontSize: 11),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  notifications.removeAt(index);
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- Create (reusing same dialog) ----------

  void _showCreateNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return NotificationDialog(
          mode: NotificationDialogMode.create,
          onSubmit: (data) {
            setState(() {
              notifications.insert(0, data);
            });
          },
        );
      },
    );
  }
}

// ---------- Reusable create/edit dialog ----------

enum NotificationDialogMode { create, edit }

class NotificationDialog extends StatefulWidget {
  final NotificationDialogMode mode;
  final Map<String, dynamic>? initialNotification;
  final void Function(Map<String, dynamic>) onSubmit;

  const NotificationDialog({
    super.key,
    required this.mode,
    required this.onSubmit,
    this.initialNotification,
  });

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _pushSelected;
  late bool _smsSelected;
  late String _target;

  bool get _isEdit => widget.mode == NotificationDialogMode.edit;

  @override
  void initState() {
    super.initState();
    final n = widget.initialNotification;

    _titleController =
        TextEditingController(text: n?['title'] as String? ?? '');
    _contentController = TextEditingController();
    final channels = (n?['channels'] as List<String>? ?? []);
    _pushSelected = channels.isEmpty || channels.contains('Push');
    _smsSelected = channels.contains('SMS');
    _target = n?['target'] as String? ?? 'All Online';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle =
        _isEdit ? 'Edit Notification' : 'Create New Notification';
    final primaryLabel = _isEdit ? 'Save Changes' : 'Send Notification';
    final subtitle = _isEdit
        ? 'Update and resend this notification.'
        : 'Compose and send a new notification to your audience.';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dialogTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),

            // Channels
            Text(
              'Channels',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _channelCheckbox(
                  label: 'Push Notification',
                  value: _pushSelected,
                  onChanged: (v) => setState(() => _pushSelected = v ?? false),
                ),
                const SizedBox(width: 16),
                _channelCheckbox(
                  label: 'SMS',
                  value: _smsSelected,
                  onChanged: (v) => setState(() => _smsSelected = v ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Title',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Special Weekend Offer',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor, width: 1.4),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              'Content',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notification content here...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor, width: 1.4),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Target audience
            Text(
              'Target Audience',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _audienceRadio(
                  label: 'All Online',
                  value: 'All Online',
                  groupValue: _target,
                  onChanged: (v) => setState(() => _target = v ?? 'All Online'),
                ),
                _audienceRadio(
                  label: 'All Offline',
                  value: 'All Offline',
                  groupValue: _target,
                  onChanged: (v) => setState(() => _target = v ?? 'All Online'),
                ),
                _audienceRadio(
                  label: 'Specific Clients',
                  value: 'Specific Clients',
                  groupValue: _target,
                  onChanged: (v) => setState(() => _target = v ?? 'All Online'),
                ),
                _audienceRadio(
                  label: 'All Staffs',
                  value: 'All Staffs',
                  groupValue: _target,
                  onChanged: (v) => setState(() => _target = v ?? 'All Online'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    primaryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final channels = <String>[
      if (_pushSelected) 'Push',
      if (_smsSelected) 'SMS',
    ];

    final base = widget.initialNotification ?? {};
    final data = {
      'id': base['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _titleController.text.trim(),
      'channels': channels,
      'target': _target,
      'date': base['date'] ?? 'Just now',
      'status': base['status'] ?? 'Sent',
    };

    widget.onSubmit(data);
    Navigator.of(context).pop();
  }

  Widget _channelCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ],
    );
  }

  Widget _audienceRadio({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ],
    );
  }
}
