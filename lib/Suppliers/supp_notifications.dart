import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supp_drawer.dart';
import '../supplier_model.dart';
import '../services/api_service.dart';
import 'supp_profile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../widgets/subscription_wrapper.dart';

class SuppNotificationsPage extends StatefulWidget {
  const SuppNotificationsPage({super.key});

  @override
  State<SuppNotificationsPage> createState() => _SuppNotificationsPageState();
}

class _SuppNotificationsPageState extends State<SuppNotificationsPage> {
  final NotificationController _controller = NotificationController();
  SupplierProfile? _profile;
  String _searchQuery = '';
  String _selectedStatus = 'All Statuses';

  final List<String> _statuses = ['All Statuses', 'Sent', 'Scheduled'];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _controller.addListener(_onControllerUpdate);
    _controller.fetchBroadcastLogs(); // Fetch CRM Broadcasts
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await ApiService.getSupplierProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      debugPrint('fetchProfile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SupplierDrawer(currentPage: 'Notifications'),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontSize: 14.sp,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuppProfilePage()),
            ),
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
                        (_profile?.shopName ?? 'S')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SubscriptionWrapper(
        child: Column(
          children: [
            _buildHeaderSection(),
            Expanded(child: _buildNotificationHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by title or content...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Filters & Export
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      items: _statuses.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _exportToCSV,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Export',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(
                          Icons.download,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateNotificationDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Create New',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _controller.broadcastStats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(
          'Total Sent',
          '${stats['total'] ?? 0}',
          Icons.mark_email_read_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Push Sent',
          '${stats['pushSent'] ?? 0}',
          Icons.notifications_active_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          'SMS Sent',
          '${stats['smsSent'] ?? 0}',
          Icons.send_outlined,
          Colors.indigo,
        ),
        _buildStatCard(
          'Most Targeted',
          stats['mostTargeted'] ?? 'All Offline Clients',
          Icons.track_changes,
          Colors.pink,
          isTarget: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isTarget = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTarget ? 9 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistory() {
    if (_controller.isLoading && _controller.broadcastLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredLogs = _controller.broadcastLogs.where((log) {
      final l = log as Map<String, dynamic>;
      final title = (l['title'] ?? '').toString().toLowerCase();
      final body = (l['body'] ?? '').toString().toLowerCase();
      final status = (l['status'] ?? 'Sent').toString();

      final matchesSearch =
          title.contains(_searchQuery.toLowerCase()) ||
          body.contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == 'All Statuses' || status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    if (filteredLogs.isEmpty) {
      return Center(
        child: Text(
          'No notifications found',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(
          filteredLogs[index] as Map<String, dynamic>,
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status'] ?? 'Sent';
    final channels = List<String>.from(notification['channels'] ?? ['Push']);
    final date = notification['createdAt'] != null
        ? DateTime.parse(notification['createdAt'])
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification['title'] ?? 'Weekend Offer',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (status == 'Scheduled' ? Colors.blue : Colors.green)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              (status == 'Scheduled'
                                      ? Colors.blue
                                      : Colors.green)
                                  .withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: status == 'Scheduled'
                              ? Colors.blue
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Channel : ${channels.join(', ')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('d MMM yyyy').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notification['targetType'] ?? 'All Offline Clients',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => _editNotification(notification),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteNotification(notification),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    try {
      final List<List<dynamic>> rows = [];
      // Header
      rows.add(["ID", "Title", "Channels", "Target", "Status", "Created At"]);

      // Data
      for (var log in _controller.broadcastLogs) {
        final l = log as Map<String, dynamic>;
        rows.add([
          l['_id'] ?? "",
          l['title'] ?? "",
          (l['channels'] as List?)?.join(', ') ?? "",
          l['targetType'] ?? "",
          l['status'] ?? "Sent",
          l['createdAt'] ?? "",
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final path =
          "${directory.path}/notifications_export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
        OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _editNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View/Edit detail feature coming soon.')),
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
            'Delete Notification',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete this notification log?',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.deleteBroadcast(id);
                if (mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
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

    _titleController = TextEditingController(
      text: n?['title'] as String? ?? '',
    );
    _contentController = TextEditingController();
    _targetsController = TextEditingController(
      text: (n?['targets'] as List? ?? []).join(', '),
    );
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
    final dialogTitle = _isEdit
        ? 'Edit Notification'
        : 'Create New Notification';
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
                      color: Theme.of(context).primaryColor,
                      width: 1.4,
                    ),
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
                      color: Theme.of(context).primaryColor,
                      width: 1.4,
                    ),
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
                        color: Theme.of(context).primaryColor,
                        width: 1.4,
                      ),
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
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
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
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}
