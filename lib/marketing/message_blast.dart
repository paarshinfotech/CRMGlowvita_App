import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MessageBlastPage extends StatefulWidget {
  const MessageBlastPage({super.key});

  @override
  State<MessageBlastPage> createState() => _MessageBlastPageState();
}

class _MessageBlastPageState extends State<MessageBlastPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> campaigns = [];
  List<dynamic> smsPackages = [];
  bool isLoading = true;
  bool isLoadingPackages = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCampaigns();
    _fetchSMSPackages();
  }

  Future<void> _fetchSMSPackages() async {
    setState(() => isLoadingPackages = true);
    final response = await ApiService.fetchSMSPackages();
    if (response['success'] == true) {
      setState(() {
        smsPackages = response['data'] ?? [];
        isLoadingPackages = false;
      });
    } else {
      setState(() => isLoadingPackages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to fetch SMS packages',
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchCampaigns() async {
    setState(() => isLoading = true);
    final response = await ApiService.fetchCampaigns();
    if (response['success'] == true) {
      setState(() {
        campaigns = response['data'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to fetch campaigns'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Message Blast',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B2D3D),
              indicatorWeight: 2,
              labelColor: const Color(0xFF3B2D3D),
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 8.sp,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 8.sp,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 12.sp),
                      SizedBox(width: 6.w),
                      const Text('SMS Packages'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 12.sp),
                      SizedBox(width: 6.w),
                      const Text('Campaign'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSMSPackages(), _buildCampaigns()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSMSPackages() {
    if (isLoadingPackages) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B2D3D)),
      );
    }

    if (smsPackages.isEmpty) {
      return Center(
        child: Text(
          'No SMS packages found',
          style: GoogleFonts.poppins(fontSize: 10.sp),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSMSPackages,
      color: const Color(0xFF3B2D3D),
      child: ListView.builder(
        padding: EdgeInsets.all(14.w),
        itemCount: smsPackages.length,
        itemBuilder: (context, index) {
          final package = smsPackages[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      package['name'] ?? 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (package['isPopular'] == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'POPULAR',
                          style: GoogleFonts.poppins(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${package['price'] ?? 0}',
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '/package',
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 12.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${package['smsCount'] ?? 0} SMS',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  'Valid for ${package['validityDays'] ?? 0} days',
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    color: Colors.blue[400],
                  ),
                ),
                if (package['description'] != null &&
                    package['description'].toString().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    package['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B2D3D),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buy Now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaigns() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B2D3D)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCampaigns,
      color: const Color(0xFF3B2D3D),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Campaigns',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Manage your marketing campaigns',
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateCampaignDialog(),
                  icon: const Icon(Icons.add, size: 13, color: Colors.white),
                  label: Text(
                    'Create Campaign',
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B2D3D),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: campaigns.isEmpty
                ? Center(
                    child: Text(
                      'No campaigns found',
                      style: GoogleFonts.poppins(fontSize: 10.sp),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) =>
                        _buildCampaignCard(campaigns[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final String status = campaign['status'] ?? 'Draft';
    Color statusColor = const Color(0xFF1B263B);
    if (status == 'Active') statusColor = Colors.green[700]!;
    if (status == 'Completed') statusColor = Colors.blue[700]!;

    final String campaignType =
        (campaign['type'] is List && (campaign['type'] as List).isNotEmpty)
        ? (campaign['type'] as List).first
        : (campaign['type']?.toString() ?? 'SMS');

    final String createdAt = campaign['createdAt'] != null
        ? DateFormat('d/M/yyyy').format(DateTime.parse(campaign['createdAt']))
        : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + badges
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign['name'] ?? 'No Name',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              _buildPill(campaignType, Colors.grey[100]!, Colors.grey[700]!),
              SizedBox(width: 4.w),
              _buildPill(status, statusColor.withOpacity(0.12), statusColor),
            ],
          ),
          SizedBox(height: 6.h),
          // Message preview
          Text(
            campaign['content'] ?? 'No Content',
            style: GoogleFonts.poppins(
              fontSize: 8.sp,
              color: Colors.purple[300],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10.h),
          // Meta row
          Wrap(
            spacing: 10.w,
            runSpacing: 4.h,
            children: [
              _buildCampaignMeta(
                'Target:',
                campaign['targetAudience'] ?? 'All Customers',
              ),
              _buildCampaignMeta('Budget:', '₹${campaign['budget'] ?? 0}'),
              _buildCampaignMeta('Created:', createdAt),
            ],
          ),
          SizedBox(height: 10.h),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(
                    fontSize: 7.5.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B2D3D),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Launch',
                  style: GoogleFonts.poppins(
                    fontSize: 7.5.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bg, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 7.sp,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCampaignMeta(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: GoogleFonts.poppins(
            fontSize: 7.5.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 7.5.sp, color: Colors.blue[400]),
        ),
      ],
    );
  }

  void _showCreateCampaignDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateCampaignDialog(onSuccess: _fetchCampaigns),
    );
  }
}

// ─────────────────────────────────────────────
//  CreateCampaignDialog
// ─────────────────────────────────────────────
class CreateCampaignDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const CreateCampaignDialog({super.key, required this.onSuccess});

  @override
  State<CreateCampaignDialog> createState() => _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends State<CreateCampaignDialog> {
  String selectedType = 'SMS';
  String? selectedTemplateId;
  List<dynamic> templates = [];
  bool isLoadingTemplates = true;

  /// Controls whether the "Create New Template" inline form is visible.
  bool _showNewTemplateForm = false;

  final TextEditingController _campaignNameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController(
    text: 'Hello!',
  );
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _templateNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? selectedDate;

  String selectedAudience = 'All Customers';
  bool isSubmitting = false;

  static const List<String> _audienceOptions = [
    'All Customers',
    'New Customers',
    'Returning Customers',
    'Premium Customers',
    'Inactive Customers',
  ];

  Future<void> _submitCampaign() async {
    if (_campaignNameController.text.isEmpty ||
        _messageController.text.isEmpty ||
        _budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final campaignData = {
      "name": _campaignNameController.text,
      "content": _messageController.text,
      "type": [selectedType],
      "status": "Draft",
      "targetAudience": selectedAudience,
      "budget": int.tryParse(_budgetController.text) ?? 0,
    };

    if (selectedDate != null) {
      campaignData["scheduledDate"] = selectedDate!.toIso8601String();
    }

    final response = await ApiService.createCampaign(campaignData);

    if (response['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully')),
        );
        widget.onSuccess();
        Navigator.pop(context);
      }
    } else {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to create campaign'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    setState(() => isLoadingTemplates = true);
    final response = await ApiService.fetchCampaigns(limit: 5);
    if (response['success'] == true) {
      setState(() {
        templates = response['data'] ?? [];
        isLoadingTemplates = false;
        if (templates.isNotEmpty) {
          selectedTemplateId = templates.first['_id'];
          _messageController.text = templates.first['content'] ?? 'Hello!';
        }
      });
    } else {
      setState(() => isLoadingTemplates = false);
    }
  }

  @override
  void dispose() {
    _campaignNameController.dispose();
    _messageController.dispose();
    _budgetController.dispose();
    _templateNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(14.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Campaign',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Fill in the details below to create a new campaign.',
                        style: GoogleFonts.poppins(
                          fontSize: 8.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 20.h, color: Colors.grey[200]),

            // ── Scrollable body ──────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SMS Templates header row
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 12.sp,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'SMS Templates',
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Test DB',
                            style: GoogleFonts.poppins(
                              fontSize: 7.5.sp,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // Tapping "+ New Template" reveals the inline form
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showNewTemplateForm = true;
                              _templateNameController.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '+ New Template',
                            style: GoogleFonts.poppins(
                              fontSize: 7.5.sp,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // ── Inline "Create New Template" form ──
                    // Shown only when _showNewTemplateForm == true
                    if (_showNewTemplateForm) ...[
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple.shade100),
                          borderRadius: BorderRadius.circular(8.r),
                          color: Colors.purple.shade50.withOpacity(0.3),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+ Create New Template',
                              style: GoogleFonts.poppins(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Template Name',
                              style: GoogleFonts.poppins(
                                fontSize: 7.5.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 32.h,
                                    child: TextField(
                                      controller: _templateNameController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 8.sp,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter template name',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 8.sp,
                                          color: Colors.grey[400],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 6.h,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                ElevatedButton(
                                  onPressed: () {
                                    // handle create logic here
                                    setState(
                                      () => _showNewTemplateForm = false,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B2D3D),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    elevation: 0,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Create',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                // Cancel hides the form
                                TextButton(
                                  onPressed: () => setState(
                                    () => _showNewTemplateForm = false,
                                  ),
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 6.h,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],

                    // Template card (always visible)
                    if (isLoadingTemplates)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B2D3D),
                        ),
                      )
                    else if (templates.isEmpty)
                      Center(
                        child: Text(
                          'No templates available',
                          style: GoogleFonts.poppins(fontSize: 8.sp),
                        ),
                      )
                    else
                      Column(
                        children: templates
                            .map((t) => _buildTemplateCard(t))
                            .toList(),
                      ),
                    SizedBox(height: 16.h),
                    Divider(color: Colors.grey[200]),
                    SizedBox(height: 12.h),

                    // Campaign Details
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 12.sp,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Campaign Details',
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    _buildLabel('Campaign Name'),
                    _buildTextField(
                      controller: _campaignNameController,
                      hint: 'Enter a descriptive campaign name',
                    ),
                    SizedBox(height: 12.h),

                    _buildLabel('Campaign Type'),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        _buildTypeChip(
                          'SMS',
                          isSelected: selectedType == 'SMS',
                        ),
                        SizedBox(width: 10.w),
                        _buildTypeChip(
                          'Email',
                          isSelected: selectedType == 'Email',
                        ),
                        SizedBox(width: 10.w),
                        _buildTypeChip(
                          'WhatsApp',
                          isSelected: selectedType == 'WhatsApp',
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    _buildLabel('Message Content'),
                    _buildMessageTextField(),
                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Target Audience'),
                              _buildDropdown(),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Budget (₹)'),
                              _buildTextField(
                                controller: _budgetController,
                                hint: 'Enter campaign budget',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    _buildLabelOptional('Scheduled Date (Optional)'),
                    _buildDateField(context),
                    SizedBox(height: 6.h),
                    Text(
                      'Leave empty to send immediately or schedule for a future date',
                      style: GoogleFonts.poppins(
                        fontSize: 7.5.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Selected template indicator
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7.w,
                            height: 7.w,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Selected Template',
                            style: GoogleFonts.poppins(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Padding(
                      padding: EdgeInsets.only(left: 15.w),
                      child: Text(
                        'Using template: ${templates.firstWhere((t) => t['_id'] == selectedTemplateId, orElse: () => {'name': 'None'})['name']}',
                        style: GoogleFonts.poppins(
                          fontSize: 7.5.sp,
                          color: Colors.blue[400],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submitCampaign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B2D3D),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            height: 12.h,
                            width: 12.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Campaign',
                            style: GoogleFonts.poppins(
                              fontSize: 8.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Template card ──────────────────────────
  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final isSelected = selectedTemplateId == template['_id'];
    return GestureDetector(
      onTap: () => setState(() {
        selectedTemplateId = template['_id'];
        _messageController.text = template['content'] ?? 'Hello!';
      }),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF3B2D3D) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[600],
                    size: 14.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name'] ?? 'Unnamed Template',
                        style: GoogleFonts.poppins(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        template['content'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 7.5.sp,
                          color: Colors.grey[500],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _buildBadge(
                  (template['type'] is List &&
                          (template['type'] as List).isNotEmpty)
                      ? (template['type'] as List).first
                      : 'SMS',
                  Colors.grey[200]!,
                  Colors.grey[700]!,
                ),
                SizedBox(width: 6.w),
                _buildBadge(
                  template['status'] ?? 'Active',
                  Colors.green[100]!,
                  Colors.green[700]!,
                ),
                SizedBox(width: 6.w),
                _buildBadge(
                  '₹${template['budget'] ?? 0}',
                  Colors.orange[100]!,
                  Colors.orange[800]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 7.5.sp,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Form helpers ───────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.poppins(
            fontSize: 8.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelOptional(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 8.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF3B2D3D)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildMessageTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _messageController,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 8.sp),
          decoration: InputDecoration(
            hintStyle: GoogleFonts.poppins(
              fontSize: 8.sp,
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF3B2D3D)),
            ),
            contentPadding: EdgeInsets.all(12.w),
          ),
        ),
        SizedBox(height: 3.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SMS limit: 160 characters per message',
              style: GoogleFonts.poppins(
                fontSize: 7.5.sp,
                color: Colors.grey[500],
              ),
            ),
            Row(
              children: [
                Text(
                  '123/160',
                  style: GoogleFonts.poppins(
                    fontSize: 7.5.sp,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '1 SMS',
                  style: GoogleFonts.poppins(
                    fontSize: 7.5.sp,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAudience,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 15.sp,
            color: Colors.grey,
          ),
          style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.black87),
          items: _audienceOptions.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (value) => setState(() => selectedAudience = value!),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextField(
      controller: _dateController,
      readOnly: true,
      style: GoogleFonts.poppins(fontSize: 8.sp),
      onTap: () async {
        DateTime? date = await showModalBottomSheet<DateTime>(
          context: context,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          builder: (context) {
            DateTime tempDate = selectedDate ?? DateTime.now();
            return Container(
              height: 400.h,
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Date',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, tempDate),
                        child: Text(
                          'Next',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B2D3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CalendarDatePicker(
                      initialDate: tempDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (DateTime newDate) {
                        tempDate = newDate;
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (date != null) {
          final TimeOfDay? time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF3B2D3D),
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (time != null) {
            setState(() {
              selectedDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              _dateController.text = DateFormat(
                'dd-MM-yyyy HH:mm',
              ).format(selectedDate!);
            });
          }
        }
      },
      decoration: InputDecoration(
        hintText: 'dd-mm-yyyy --:--',
        hintStyle: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          size: 13.sp,
          color: Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF3B2D3D)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildTypeChip(String type, {required bool isSelected}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B2D3D)
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8.r),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 12.sp,
                color: isSelected ? const Color(0xFF3B2D3D) : Colors.grey[400],
              ),
              SizedBox(width: 5.w),
              Text(
                type,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
