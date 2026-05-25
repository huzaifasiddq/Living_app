import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackQueriesScreen extends StatefulWidget {
  const FeedbackQueriesScreen({super.key});

  @override
  State<FeedbackQueriesScreen> createState() => _FeedbackQueriesScreenState();
}

class _FeedbackQueriesScreenState extends State<FeedbackQueriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteFeedback(String id) async {
    await FirebaseFirestore.instance.collection('feedback').doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback deleted')),
    );
  }

  Future<void> _markAsRead(String id, bool isRead) async {
    await FirebaseFirestore.instance.collection('feedback').doc(id).update({
      'isRead': !isRead,
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterFeedback(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();

      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final message = (data['message'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          message.contains(query);
    }).toList();
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Feedback?'),
        content: const Text('Are you sure you want to delete this feedback/query?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteFeedback(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openDetails(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackDetailScreen(
          feedbackId: id,
          data: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          'Feedback & Queries',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('feedback')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final feedbacks = _filterFeedback(snapshot.data?.docs ?? []);

                if (feedbacks.isEmpty) {
                  return Center(
                    child: Text(
                      'No feedback found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: feedbacks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = feedbacks[index];
                    final data = doc.data();

                    return _feedbackCard(
                      id: doc.id,
                      data: data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => searchText = value);
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
          hintText: 'Search feedback',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _feedbackCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final name = data['name'] ?? 'Unknown User';
    final email = data['email'] ?? 'No Email';
    final message = data['message'] ?? '';
    final contact = data['contact'] ?? data['phone'] ?? '';
    final isRead = data['isRead'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openDetails(id, data),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : const Color(0xFF2E7D32).withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                name.toString().isNotEmpty
                    ? name.toString()[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if (!isRead)
                        _badge('New', Colors.green),
                    ],
                  ),

                  Text(
                    email.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                    ),
                  ),

                  if (contact.toString().isNotEmpty)
                    Text(
                      contact.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey[500],
                      ),
                    ),

                  const SizedBox(height: 5),

                  Text(
                    message.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.2,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read') {
                  _markAsRead(id, isRead);
                } else if (value == 'delete') {
                  _confirmDelete(id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'read',
                  child: Text(isRead ? 'Mark Unread' : 'Mark Read'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FeedbackDetailScreen extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> data;

  const FeedbackDetailScreen({
    super.key,
    required this.feedbackId,
    required this.data,
  });

  Future<void> _markAsRead() async {
    await FirebaseFirestore.instance.collection('feedback').doc(feedbackId).update({
      'isRead': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    _markAsRead();

    final name = data['name'] ?? 'Unknown User';
    final email = data['email'] ?? 'No Email';
    final contact = data['contact'] ?? data['phone'] ?? '';
    final message = data['message'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          'Feedback Detail',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                email.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),

              if (contact.toString().isNotEmpty)
                Text(
                  contact.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),

              const SizedBox(height: 20),

              Text(
                'Message',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}