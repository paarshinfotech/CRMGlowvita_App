import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './supp_drawer.dart';

class SuppProductQuestionsPage extends StatefulWidget {
  const SuppProductQuestionsPage({super.key});

  @override
  State<SuppProductQuestionsPage> createState() => _ProductQuestionsPageState();
}

class _ProductQuestionsPageState extends State<SuppProductQuestionsPage> {
  // Sample product questions data
  final List<Map<String, dynamic>> questions = [
    {
      'id': '1',
      'customerName': 'Priya Sharma',
      'productName': 'Hydrating Face Serum',
      'question': 'Does this serum work for oily skin as well?',
      'answer':
          'Yes, this serum is suitable for all skin types including oily skin. It\'s non-comedogenic and won\'t clog pores.',
      'date': '2025-11-15',
      'status': 'Answered',
      'hasAnswer': true,
    },
    {
      'id': '2',
      'customerName': 'Rahul Mehta',
      'productName': 'Luxury Body Butter',
      'question': 'How often should I apply this body butter?',
      'answer': null,
      'date': '2025-11-10',
      'status': 'Pending',
      'hasAnswer': false,
    },
    {
      'id': '3',
      'customerName': 'Anjali Patel',
      'productName': 'Argan Oil Hair Mask',
      'question': 'Can I use this on colored hair?',
      'answer':
          'Absolutely! This hair mask is safe for colored hair and will help maintain your color while nourishing your hair.',
      'date': '2025-11-05',
      'status': 'Answered',
      'hasAnswer': true,
    },
    {
      'id': '4',
      'customerName': 'Vikram Singh',
      'productName': 'Matte Lipstick Set',
      'question': 'Are these lipsticks long-lasting?',
      'answer': null,
      'date': '2025-10-28',
      'status': 'Pending',
      'hasAnswer': false,
    },
    {
      'id': '5',
      'customerName': 'Sneha Reddy',
      'productName': 'Gel Nail Polish Kit',
      'question': 'Do I need a UV lamp for all the colors?',
      'answer':
          'Yes, all gel polishes in this kit require a UV or LED lamp for curing. The kit includes a UV lamp for your convenience.',
      'date': '2025-10-20',
      'status': 'Answered',
      'hasAnswer': true,
    },
  ];

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  // Filter options
  final List<String> _statusFilters = ['All', 'Answered', 'Pending'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtered questions getter
  List<Map<String, dynamic>> get _filteredQuestions {
    return questions.where((question) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          question['customerName']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          question['productName']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          question['question']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (question['answer']
                  ?.toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);

      // Status filter
      final matchesStatus =
          _selectedStatus == 'All' || question['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SupplierDrawer(currentPage: 'Product Questions'),
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Product Questions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            // Single filter row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Status filter dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        underline: const SizedBox(),
                        items: _statusFilters
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Header stats (answered and pending counts)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
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
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Answered',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getAnsweredCount()}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
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
                              Icon(
                                Icons.pending_outlined,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pending',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getPendingCount()}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Count card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.question_answer,
                        color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product Questions',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Text('${_filteredQuestions.length} questions in total',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_filteredQuestions.length}',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Questions list header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Questions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Questions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredQuestions.length,
                itemBuilder: (context, index) {
                  final question = _filteredQuestions[index];
                  return _buildQuestionCard(question);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getAnsweredCount() {
    return questions
        .where((question) => question['status'] == 'Answered')
        .length;
  }

  int _getPendingCount() {
    return questions
        .where((question) => question['status'] == 'Pending')
        .length;
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final status = question['status'] as String;
    final hasAnswer = question['hasAnswer'] as bool;

    Color statusColor;
    switch (status) {
      case 'Answered':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

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
          // Product name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question['productName'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Product',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Customer name
          Text(
            'by ${question['customerName']}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          // Question text
          Text(
            question['question'] as String,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          // Answer section
          if (hasAnswer) ...[
            const Divider(height: 16, thickness: 1, color: Colors.grey),
            Text(
              'Answer:',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              question['answer'] as String,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade800,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Show answer dialog
                _showAnswerDialog(question);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Answer Question',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Date
          Text(
            question['date'] as String,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(Map<String, dynamic> question) {
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Answer Question',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question['question'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Answer:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: answerController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (answerController.text.trim().isNotEmpty) {
                  // Update the question with the answer
                  setState(() {
                    final index =
                        questions.indexWhere((q) => q['id'] == question['id']);
                    if (index != -1) {
                      questions[index]['answer'] = answerController.text.trim();
                      questions[index]['status'] = 'Answered';
                      questions[index]['hasAnswer'] = true;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
