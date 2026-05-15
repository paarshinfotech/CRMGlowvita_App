import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'vendor_model.dart';
import 'Notification.dart';
import 'my_Profile.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  VendorProfile? _profile;
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        ApiService.getVendorProfile(),
        ApiService.fetchWalletData(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as VendorProfile?;
          _walletData = results[1] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWithdrawalDialog(double balance, double maxWithdrawable) {
    final amountController = TextEditingController();
    final holderNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ifscController = TextEditingController();
    final upiIdController = TextEditingController();
    String payoutMethod = 'bank_transfer';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 330.w,
              padding: EdgeInsets.all(16.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request Withdrawal',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            size: 16.sp,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Enter your details to initiate a payout to your bank or UPI account.',
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Text(
                      'Withdrawal Amount (₹)',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 10.sp),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Max allowed today: ₹${maxWithdrawable.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 7.sp,
                        color: Colors.grey[500],
                      ),
                    ),

                    SizedBox(height: 12.h),
                    Text(
                      'Payout Method',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(
                              () => payoutMethod = 'bank_transfer',
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                color: payoutMethod == 'bank_transfer'
                                    ? const Color(0xFF2D1B2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: payoutMethod == 'bank_transfer'
                                      ? const Color(0xFF2D1B2E)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Bank Transfer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5.sp,
                                    color: payoutMethod == 'bank_transfer'
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setDialogState(() => payoutMethod = 'upi'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                color: payoutMethod == 'upi'
                                    ? const Color(0xFF2D1B2E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: payoutMethod == 'upi'
                                      ? const Color(0xFF2D1B2E)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Instant UPI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5.sp,
                                    color: payoutMethod == 'upi'
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),
                    Text(
                      'Account Holder Name',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: holderNameController,
                      style: GoogleFonts.poppins(fontSize: 10.sp),
                      decoration: InputDecoration(
                        hintText: 'As per bank records',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),

                    if (payoutMethod == 'bank_transfer') ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Account Number',
                        style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextField(
                        controller: accountNumberController,
                        style: GoogleFonts.poppins(fontSize: 10.sp),
                        decoration: InputDecoration(
                          hintText: 'Enter account number',
                          isDense: true,
                          contentPadding: EdgeInsets.all(10.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'IFSC Code',
                        style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextField(
                        controller: ifscController,
                        style: GoogleFonts.poppins(fontSize: 10.sp),
                        decoration: InputDecoration(
                          hintText: 'SBIN0001234',
                          isDense: true,
                          contentPadding: EdgeInsets.all(10.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 12.h),
                      Text(
                        'UPI ID',
                        style: GoogleFonts.poppins(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextField(
                        controller: upiIdController,
                        style: GoogleFonts.poppins(fontSize: 10.sp),
                        decoration: InputDecoration(
                          hintText: 'username@upi',
                          isDense: true,
                          contentPadding: EdgeInsets.all(10.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (amountController.text.isEmpty ||
                                        holderNameController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please fill all fields',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final amount =
                                        double.tryParse(
                                          amountController.text,
                                        ) ??
                                        0;
                                    if (amount <= 0 ||
                                        amount > maxWithdrawable) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid amount'),
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSubmitting = true);

                                    final Map<String, dynamic> body = {
                                      'amount': amount,
                                      'withdrawalMethod': payoutMethod,
                                      'bankDetails': {
                                        'accountHolderName':
                                            holderNameController.text,
                                      },
                                    };

                                    if (payoutMethod == 'bank_transfer') {
                                      body['bankDetails']['accountNumber'] =
                                          accountNumberController.text;
                                      body['bankDetails']['ifsc'] =
                                          ifscController.text;
                                    } else {
                                      body['bankDetails']['upiId'] =
                                          upiIdController.text;
                                    }

                                    final result =
                                        await ApiService.requestWithdrawal(
                                          body,
                                        );

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] ??
                                                (result['success'] == true
                                                    ? 'Withdrawal requested successfully'
                                                    : 'Failed to request withdrawal'),
                                          ),
                                          backgroundColor:
                                              result['success'] == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                      if (result['success'] == true) {
                                        _fetchInitialData();
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA59D9E),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? SizedBox(
                                    height: 12.sp,
                                    width: 12.sp,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Confirm Payout',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
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
        },
      ),
    );
  }

  Widget _buildInitialAvatar() {
    final displayName = _profile?.businessName ?? 'G';
    return Text(
      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14.sp,
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount ?? 0);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '---';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yy').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    final balance = _walletData?['balance'] ?? 0;
    final referralCode = _walletData?['referralCode'] ?? '---';
    final transactions = _walletData?['transactions'] as List? ?? [];
    final settings = _walletData?['settings'] ?? {};

    final maxWithdrawablePerc = (settings['maxWithdrawablePercentage'] ?? 50)
        .toDouble();
    final withdrawableBalance = (balance * (maxWithdrawablePerc / 100))
        .toDouble();
    final minWithdrawal = settings['minWithdrawalAmount'] ?? 100;

    return Scaffold(
      drawer: CustomDrawer(
        currentPage: 'Wallet',
        userName: _profile?.businessName ?? '',
        profileImageUrl: _profile?.profileImage ?? '',
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Wallet & Payouts',
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  referralCode,
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const My_Profile()),
            ),
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: ClipOval(
                  child: (_profile != null && _profile!.profileImage.isNotEmpty)
                      ? Image.network(
                          _profile!.profileImage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => _buildInitialAvatar(),
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                              ? child
                              : const CircularProgressIndicator(),
                        )
                      : _buildInitialAvatar(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchInitialData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12.w),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    Text(
                      'Manage your earnings, referral bonuses, and payout requests.',
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Stats Cards Row 1
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Wallet Balance',
                            value: _formatAmount(balance),
                            subtitle: 'Total earnings',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _StatCard(
                            label: 'Withdrawable',
                            value: _formatAmount(withdrawableBalance),
                            subtitle:
                                '${maxWithdrawablePerc.toStringAsFixed(0)}% of total balance',
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Stats Cards Row 2
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Referral Rewards',
                            value: _formatAmount(
                              _walletData?['referralRewards'] ?? 0,
                            ),
                            subtitle: 'Bonus earnings',
                            icon: Icons.card_giftcard_outlined,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _StatCard(
                            label: 'Min. Balance',
                            value: _formatAmount(minWithdrawal),
                            subtitle: 'Required for payout',
                            icon: Icons.info_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Withdrawal Requests
                    _SectionCard(
                      title: 'Withdrawal Requests',
                      titleIcon: Icons.credit_card_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Available for Payout
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available for Payout',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  _formatAmount(withdrawableBalance),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Info box
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 12.sp,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    'You can withdraw up to $maxWithdrawablePerc% of your wallet balance. Minimum withdrawal amount is ${_formatAmount(minWithdrawal)}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Withdraw Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: balance >= minWithdrawal
                                  ? () => _showWithdrawalDialog(
                                      balance.toDouble(),
                                      withdrawableBalance,
                                    )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A2C3C),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 11.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Withdraw Rewards',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Processing info
                          _InfoRow(
                            icon: Icons.access_time_outlined,
                            title: 'Processing Time',
                            subtitle:
                                'Most payouts are processed within 24-48 hours via RazorpayX.',
                          ),
                          SizedBox(height: 8.h),
                          _InfoRow(
                            icon: Icons.account_balance_outlined,
                            title: 'Bank & UPI',
                            subtitle:
                                'Instant UPI transfers or Direct Bank Payouts available.',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Recent Transactions
                    _SectionCard(
                      title: 'Recent Transactions',
                      titleIcon: Icons.history_rounded,
                      subtitle: 'Your latest credits and debits',
                      child: Column(
                        children: [
                          // Table header
                          Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              children: [
                                _TableHeader('Created At', flex: 2),
                                _TableHeader('Description', flex: 4),
                                _TableHeader('Txn ID', flex: 3),
                                _TableHeader(
                                  'Amount',
                                  flex: 2,
                                  align: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: const Color(0xFFEEEEEE)),
                          if (transactions.isEmpty) ...[
                            SizedBox(height: 24.h),
                            // Empty state
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 28.sp,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    'No transactions found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.sp,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ] else ...[
                            ...transactions.map((tx) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Row(
                                  children: [
                                    _TableData(
                                      _formatDate(tx['createdAt']?.toString()),
                                      flex: 2,
                                    ),
                                    _TableData(
                                      tx['description'] ?? '---',
                                      flex: 4,
                                    ),
                                    _TableData(
                                      tx['transactionId']
                                              ?.toString()
                                              .toUpperCase() ??
                                          '---',
                                      flex: 3,
                                    ),
                                    _TableData(
                                      _formatAmount(tx['amount']),
                                      flex: 2,
                                      align: TextAlign.right,
                                      color: (tx['type'] == 'credit'
                                          ? Colors.green
                                          : Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(icon, size: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 7.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.titleIcon,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, size: 13.sp, color: Colors.black87),
              SizedBox(width: 5.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.only(left: 18.w),
              child: Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13.sp, color: Colors.grey[500]),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;

  const _TableHeader(this.text, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.poppins(
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}

class _TableData extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  final Color? color;

  const _TableData(
    this.text, {
    this.flex = 1,
    this.align = TextAlign.left,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.poppins(
          fontSize: 8.sp,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
