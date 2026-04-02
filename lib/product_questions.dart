import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';
import 'widgets/subscription_wrapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductQuestionsPage extends StatefulWidget {
  const ProductQuestionsPage({super.key});

  @override
  State<ProductQuestionsPage> createState() => _ProductQuestionsPageState();
}

class _ProductQuestionsPageState extends State<ProductQuestionsPage> {
  List<Map<String, dynamic>> _allQuestions = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  final List<String> _statusFilters = ['All', 'Answered', 'Pending'];

  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;
  final List<int> _pageSizeOptions = [10, 20, 50];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── API Methods (unchanged) ───────────────────────────────────────────────

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final questions = await ApiService.getProductQuestions();
      setState(() {
        _allQuestions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load questions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer(
      String questionId, String answer, bool isPublished) async {
    try {
      await ApiService.answerProductQuestion(questionId, answer, isPublished);
      await _fetchQuestions();
    } catch (e) {
      _showError('Error submitting answer: $e');
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await ApiService.deleteProductQuestion(questionId);
      await _fetchQuestions();
    } catch (e) {
      _showError('Error deleting question: $e');
    }
  }

  Future<void> _togglePublish(String questionId, bool currentValue) async {
    try {
      await ApiService.togglePublishProductQuestion(questionId, !currentValue);
      await _fetchQuestions();
    } catch (e) {
      _showError('Error updating publish status: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ── Filtered & paginated data ─────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredQuestions {
    return _allQuestions.where((question) {
      final productId = question['productId'];
      final productName = productId is Map<String, dynamic>
          ? (productId['productName'] ?? '').toString()
          : '';
      final userName = question['userName'] ?? '';
      final questionText = question['question'] ?? '';
      final answer = question['answer'] ?? '';

      final matchesSearch = _searchQuery.isEmpty ||
          productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          questionText.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          answer.toLowerCase().contains(_searchQuery.toLowerCase());

      final isAnswered = question['isAnswered'] == true;
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Answered' && isAnswered) ||
          (_selectedStatus == 'Pending' && !isAnswered);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> get _pagedQuestions {
    final all = _filteredQuestions;
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredQuestions.length / _pageSize).ceil().clamp(1, 9999);

  int get _answeredCount =>
      _allQuestions.where((q) => q['isAnswered'] == true).length;
  int get _pendingCount =>
      _allQuestions.where((q) => q['isAnswered'] != true).length;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Product Questions'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Product Questions',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 12.sp),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.black87, size: 20),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: Colors.black87, size: 20),
              onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: accent.withOpacity(0.12),
              child: Text('A',
                  style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SubscriptionWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError()
                : _buildBody(accent),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_errorMessage!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.red.shade600),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _fetchQuestions, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody(Color accent) {
    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _currentPage = 1;
            }),
            style: GoogleFonts.poppins(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search questions, products or customers...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade400),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.grey, size: 18),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 1;
                        });
                      },
                    ),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // ── Status filter dropdown ────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: _statusFilters
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black87))))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedStatus = v!;
                _currentPage = 1;
              }),
            ),
          ),
        ),

        // ── Stats cards ───────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              // Total Customer Questions
              Expanded(
                child: _StatCard(
                  emoji: '👥',
                  label: 'Total Customer\nQuestions',
                  value: _allQuestions.length,
                  valueColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              // Answered
              Expanded(
                child: _StatCard(
                  emoji: '💡',
                  label: 'Answered',
                  value: _answeredCount,
                  valueColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              // Awaiting response (full width card)
              Expanded(
                child: _StatCard(
                  emoji: '🕐',
                  label: 'Awaiting response',
                  value: _pendingCount,
                  valueColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // ── Questions list ────────────────────────────────────────────
        Expanded(
          child: _pagedQuestions.isEmpty
              ? Center(
                  child: Text('No questions found.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade600)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  itemCount: _pagedQuestions.length,
                  itemBuilder: (context, index) =>
                      _buildQuestionCard(_pagedQuestions[index]),
                ),
        ),

        // ── Pagination footer ─────────────────────────────────────────
        _buildPaginationFooter(),
      ],
    );
  }

  // ── Pagination Footer ─────────────────────────────────────────────────────
  Widget _buildPaginationFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text('Show',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6)),
            child: DropdownButton<int>(
              value: _pageSize,
              underline: const SizedBox(),
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
              items: _pageSizeOptions
                  .map((n) => DropdownMenuItem(
                      value: n,
                      child:
                          Text('$n', style: GoogleFonts.poppins(fontSize: 11))))
                  .toList(),
              onChanged: (v) => setState(() {
                _pageSize = v!;
                _currentPage = 1;
              }),
            ),
          ),
          const Spacer(),
          // Prev
          _PageBtn(
            icon: Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 6),
          Text('Page $_currentPage',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 6),
          // Next
          _PageBtn(
            icon: Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  // ── Question Card ─────────────────────────────────────────────────────────
  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final isAnswered = question['isAnswered'] == true;
    final isPublished = question['isPublished'] == true;
    final productIdMap = question['productId'];
    final productName = productIdMap is Map<String, dynamic>
        ? (productIdMap['productName'] ?? 'Unknown Product')
        : 'Unknown Product';
    final productImages = productIdMap is Map<String, dynamic>
        ? (productIdMap['productImages'] as List? ?? [])
        : <dynamic>[];
    final userName = question['userName'] ?? 'Anonymous';
    final userEmail = question['userEmail'] ?? '';
    final questionText = question['question'] ?? '';
    final answer = question['answer'];
    final salePrice =
        productIdMap is Map<String, dynamic> ? productIdMap['salePrice'] : null;
    final qId = question['_id'] as String? ?? '';
    final createdAt = question['createdAt'] as String? ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      } catch (_) {
        dateStr = createdAt;
      }
    }

    final accent = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // Product image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: productImages.isNotEmpty
                        ? _buildThumb(productImages[0])
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image,
                                size: 20, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 10),
                // Product name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (salePrice != null)
                        Text('₹ $salePrice/-',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? Colors.green.withOpacity(0.10)
                        : Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAnswered ? Icons.check_circle : Icons.circle_outlined,
                        size: 9,
                        color: isAnswered ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAnswered ? 'Answered' : 'Pending',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isAnswered ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Date
                Text(dateStr,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: Colors.grey.shade400)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── User info ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Anonymous',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(userEmail.isNotEmpty ? userEmail : userName,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Question text ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '"$questionText"',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400),
            ),
          ),

          const SizedBox(height: 10),

          // ── Answer section ─────────────────────────────────────────
          if (isAnswered && answer != null && answer.toString().isNotEmpty) ...[
            // Green answer bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  answer.toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF2E7D32)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Edit + delete row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconActionBtn(
                    icon: Icons.edit_outlined,
                    color: Colors.black54,
                    onTap: () => _showAnswerDialog(question, isEdit: true),
                  ),
                  const SizedBox(width: 6),
                  _IconActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    onTap: () => _confirmDelete(qId),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Reply button + delete icon row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  // Reply button
                  GestureDetector(
                    onTap: () => _showAnswerDialog(question, isEdit: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Reply',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _IconActionBtn(
                    icon: Icons.edit_outlined,
                    color: Colors.black54,
                    onTap: () => _showAnswerDialog(question, isEdit: false),
                  ),
                  const SizedBox(width: 6),
                  _IconActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    onTap: () => _confirmDelete(qId),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Thumbnail helper ──────────────────────────────────────────────────────
  Widget _buildThumb(dynamic image) {
    if (image == null)
      return Container(
          color: Colors.grey.shade100,
          child: const Icon(Icons.image, size: 20, color: Colors.grey));
    if (image is String) {
      if (image.startsWith('http'))
        return Image.network(image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade100,
                child: const Icon(Icons.image, size: 20, color: Colors.grey)));
      if (image.contains('/')) {
        final url =
            'https://partners.glowvitasalon.com/${image.startsWith('/') ? image.substring(1) : image}';
        return Image.network(url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade100,
                child: const Icon(Icons.image, size: 20, color: Colors.grey)));
      }
    }
    return Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.image, size: 20, color: Colors.grey));
  }

  // ── Dialogs (logic unchanged) ─────────────────────────────────────────────

  void _confirmDelete(String questionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Question',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
        content: Text(
          'Are you sure you want to delete this question? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteQuestion(questionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(Map<String, dynamic> question,
      {required bool isEdit}) {
    final productIdMap = question['productId'];
    final productName = productIdMap is Map<String, dynamic>
        ? (productIdMap['productName'] ?? 'Unknown Product')
        : 'Unknown Product';
    final userName = question['userName'] ?? 'Anonymous';
    final questionText = question['question'] ?? '';
    final existingAnswer = (question['answer'] ?? '').toString();
    final qId = question['_id'] as String? ?? '';
    final answerController =
        TextEditingController(text: isEdit ? existingAnswer : '');
    bool isPublished = question['isPublished'] == true;
    const int minChars = 10;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stContext, setDialogState) {
            final charCount = answerController.text.length;
            final isValid = charCount >= minChars;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Answer' : 'Answer Question',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(dialogContext),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provide a helpful answer to the customer\'s question',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productName,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            Text('Asked by $userName',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('Question:',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(questionText,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Your Answer *',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: answerController,
                        maxLines: 5,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type your answer here...',
                          hintStyle: GoogleFonts.poppins(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum $minChars characters ($charCount/$minChars)',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isValid
                              ? Colors.green.shade600
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Publish Answer',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Make this Q&A visible on the product page',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isPublished,
                              onChanged: (val) =>
                                  setDialogState(() => isPublished = val),
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey.shade700)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isValid
                                ? () {
                                    Navigator.pop(dialogContext);
                                    _submitAnswer(
                                        qId,
                                        answerController.text.trim(),
                                        isPublished);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              isEdit ? 'Update Answer' : 'Submit Answer',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
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
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color valueColor;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 2),
                Text('$value',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon action button
// ─────────────────────────────────────────────────────────────────────────────
class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination button
// ─────────────────────────────────────────────────────────────────────────────
class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            border: Border.all(
                color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon,
            size: 16, color: enabled ? Colors.black54 : Colors.grey.shade300),
      ),
    );
  }
}
