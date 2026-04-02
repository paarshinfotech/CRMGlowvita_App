import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'vendor_model.dart';
import 'services/api_service.dart';
import 'my_Profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'controllers/notification_controller.dart';
import 'models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationController _controller = NotificationController();
  VendorProfile? _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfile();
    _controller.addListener(_onControllerUpdate);
    _controller.fetchNotifications();
    _controller.fetchBroadcastLogs(); // Fetch CRM Broadcasts
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getVendorProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Notifications'),
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 12.sp)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.4,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => My_Profile())),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 16.r,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage:
                    (_profile != null && _profile!.profileImage.isNotEmpty)
                        ? NetworkImage(_profile!.profileImage)
                        : null,
                child: (_profile == null || _profile!.profileImage.isEmpty)
                    ? Text(
                        (_profile?.businessName ?? 'H')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsSection(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Inbox'),
              Tab(text: 'Sent Broadcasts'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInboxSection(),
                _buildSentSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxSection() {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.notifications.isEmpty) {
      return Center(
        child: Text(
          'No received notifications yet.',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = _controller.notifications[index];
        return _buildInboxCard(notification);
      },
    );
  }

  Widget _buildSentSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              'Broadcast History',
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
    );
  }

  Widget _buildInboxCard(NotificationModel notification) {
    final Color typeColor = _controller.getColorForType(notification.type);
    final IconData typeIcon = _controller.getIconForType(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : typeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : typeColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, hh:mm a')
                          .format(notification.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 2),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: typeColor,
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Stats section (Using Dynamic Data) ----------

  Widget _buildStatsSection() {
    final stats = _controller.broadcastStats;
    final totalSent = stats['total'] ?? 0;
    final pushSent = stats['pushSent'] ?? 0;
    final smsSent = stats['smsSent'] ?? 0;
    final mostTargeted = stats['mostTargeted'] ?? 'None';

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
    if (_controller.isLoading && _controller.broadcastLogs.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _controller.broadcastLogs
            .map((notification) =>
                _buildNotificationCard(notification as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // Determine status color based on presence or fields
    final status = notification['status'] ?? 'Sent';
    final channels = List<String>.from(notification['channels'] ?? ['Push']);

    Color statusColor;
    switch (status) {
      case 'Sent':
        statusColor = Theme.of(context).primaryColor;
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
                _buildInfoRow(
                    'Target',
                    notification['targetType'] ??
                        notification['target'] ??
                        'All'),
                const SizedBox(height: 6),
                _buildInfoRow(
                    'Date',
                    notification['createdAt'] != null
                        ? DateFormat('yyyy-MM-dd HH:mm')
                            .format(DateTime.parse(notification['createdAt']))
                        : (notification['date'] ?? 'N/A')),
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

  // ---------- Broadcast CRUD Operations ----------

  void _editNotification(Map<String, dynamic> notification) {
    // Optional: Implement broadcast editing if API supports it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit broadcast is coming soon.')),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    final id = notification['_id'] ?? notification['id'];
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Delete Broadcast Log',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this broadcast log?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.deleteBroadcast(id);
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: Text('Delete', style: GoogleFonts.poppins(fontSize: 11)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return NotificationDialog(
          mode: NotificationDialogMode.create,
          onSubmit: (data) async {
            final success = await _controller.createBroadcast(data);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast sent successfully!')),
              );
            }
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
  late TextEditingController _targetsController;
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
    _targetsController =
        TextEditingController(text: (n?['targets'] as List? ?? []).join(', '));
    final channels = (n?['channels'] as List<dynamic>? ?? []);
    _pushSelected = channels.isEmpty || channels.contains('Push');
    _smsSelected = channels.contains('SMS');
    _target = n?['targetType'] as String? ?? 'all_online_clients';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _targetsController.dispose();
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
        child: SingleChildScrollView(
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
                    onChanged: (v) =>
                        setState(() => _pushSelected = v ?? false),
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
                    value: 'all_online_clients',
                    groupValue: _target,
                    onChanged: (v) =>
                        setState(() => _target = v ?? 'all_online_clients'),
                  ),
                  _audienceRadio(
                    label: 'All Offline',
                    value: 'all_offline_clients',
                    groupValue: _target,
                    onChanged: (v) =>
                        setState(() => _target = v ?? 'all_online_clients'),
                  ),
                  _audienceRadio(
                    label: 'Specific Clients',
                    value: 'specific_clients',
                    groupValue: _target,
                    onChanged: (v) =>
                        setState(() => _target = v ?? 'all_online_clients'),
                  ),
                  _audienceRadio(
                    label: 'All Staffs',
                    value: 'all_staffs',
                    groupValue: _target,
                    onChanged: (v) =>
                        setState(() => _target = v ?? 'all_online_clients'),
                  ),
                ],
              ),

              if (_target == 'specific_clients') ...[
                const SizedBox(height: 16),
                Text(
                  'Client Emails (comma separated)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                TextField(
                  controller: _targetsController,
                  decoration: InputDecoration(
                    hintText: 'e.g., client1@email.com, client2@email.com',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 1.4),
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
              ],

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
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      // Basic validation
      return;
    }

    final channels = <String>[
      if (_pushSelected) 'Push',
      if (_smsSelected) 'SMS',
    ];

    final List<String> targetList = _target == 'specific_clients'
        ? _targetsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : [];

    final data = {
      'title': title,
      'content': content,
      'channels': channels,
      'targetType': _target,
      'targets': targetList,
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
