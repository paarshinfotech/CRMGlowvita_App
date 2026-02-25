import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/custom_drawer.dart';
import 'services/api_service.dart';

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

  int get _answeredCount =>
      _allQuestions.where((q) => q['isAnswered'] == true).length;
  int get _pendingCount =>
      _allQuestions.where((q) => q['isAnswered'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Product Questions'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Product Questions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchQuestions,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade400, size: 48),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.red.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchQuestions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search questions...',
                            hintStyle: GoogleFonts.poppins(fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      // Status filter dropdown
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _statusFilters
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status,
                                        style:
                                            GoogleFonts.poppins(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedStatus = value!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats cards
                      SizedBox(
                        height: 100,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.check_circle_outline,
                                  label: 'Answered',
                                  count: _answeredCount,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.pending_outlined,
                                  label: 'Pending',
                                  count: _pendingCount,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.question_answer,
                                  color: Theme.of(context).primaryColor,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Product Questions',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '${_filteredQuestions.length} questions in total',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_filteredQuestions.length}',
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Customer Questions',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Questions list
                      Expanded(
                        child: _filteredQuestions.isEmpty
                            ? Center(
                                child: Text(
                                  'No questions found.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredQuestions.length,
                                itemBuilder: (context, index) =>
                                    _buildQuestionCard(
                                        _filteredQuestions[index]),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon, required String label, required int count}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final isAnswered = question['isAnswered'] == true;
    final isPublished = question['isPublished'] == true;
    final productIdMap = question['productId'];
    final productName = productIdMap is Map<String, dynamic>
        ? (productIdMap['productName'] ?? 'Unknown Product')
        : 'Unknown Product';
    final userName = question['userName'] ?? 'Anonymous';
    final userEmail = question['userEmail'] ?? '';
    final questionText = question['question'] ?? '';
    final answer = question['answer'];
    final qId = question['_id'] as String? ?? '';
    final createdAt = question['createdAt'] as String? ?? '';

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        dateStr = createdAt;
      }
    }

    final statusColor = isAnswered ? Colors.green : Colors.orange;
    final statusLabel = isAnswered ? 'Answered' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: product name + badges + delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Product',
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              // Status badges + delete
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Answer status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(statusLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: statusColor,
                            fontWeight: FontWeight.w500)),
                  ),
                  // Published badge
                  if (isPublished)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Published',
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),
                  // Delete icon button
                  InkWell(
                    onTap: () => _confirmDelete(qId),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Customer info
          Row(
            children: [
              Icon(Icons.person_outline, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(userName,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade700)),
              if (userEmail.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.email_outlined,
                    size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(userEmail,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Question text
          Text(
            questionText,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500),
          ),
          // Answer section (only if answered)
          if (isAnswered && answer != null && answer.toString().isNotEmpty) ...[
            const Divider(height: 16, thickness: 1, color: Color(0xFFEEEEEE)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.reply,
                    size: 14, color: Theme.of(context).primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Answer:',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor)),
                      const SizedBox(height: 2),
                      Text(answer.toString(),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade800)),
                    ],
                  ),
                ),
              ],
            ),
            // Edit answer button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAnswerDialog(question, isEdit: true),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: Text('Edit Answer',
                    style: GoogleFonts.poppins(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 0),
                ),
              ),
            ),
          ] else if (!isAnswered) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showAnswerDialog(question, isEdit: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Answer Question',
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 10),
          // Date
          Text(dateStr,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

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
                      // Dialog header
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
                      // Product & question context card
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
                      // Answer field label
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
                      // Publish Answer toggle
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
                      // Action buttons
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
