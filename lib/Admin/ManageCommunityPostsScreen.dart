import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageCommunityPostsScreen extends StatefulWidget {
  const ManageCommunityPostsScreen({super.key});

  @override
  State<ManageCommunityPostsScreen> createState() =>
      _ManageCommunityPostsScreenState();
}

class _ManageCommunityPostsScreenState
    extends State<ManageCommunityPostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deletePost(String id) async {
    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(id)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted')),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this community post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deletePost(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final username = (data['userName'] ?? '').toString().toLowerCase();
      final content = (data['content'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          username.contains(query) ||
          content.contains(query);
    }).toList();
  }

  Future<void> _toggleFeatured(String id, bool featured) async {
    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(id)
        .update({
      'featured': !featured,
    });
  }

  Future<void> _toggleHidden(String id, bool hidden) async {
    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(id)
        .update({
      'hidden': !hidden,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          'Community Posts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final posts = _filterPosts(snapshot.data?.docs ?? []);

                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      'No community posts found',
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
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    final data = doc.data();

                    return _postCard(
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
          hintText: 'Search posts',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _postCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] ?? 'Community Post';
    final content = data['content'] ?? '';
    final userName = data['userName'] ?? 'Unknown User';
    final imageUrl = data['imageUrl'] ?? '';
    final likes = data['likes'] ?? 0;
    final comments = data['comments'] ?? 0;
    final featured = data['featured'] == true;
    final hidden = data['hidden'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hidden ? Colors.red.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hidden
              ? Colors.red.withOpacity(0.25)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl.toString(),
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),

          if (imageUrl.toString().isNotEmpty) const SizedBox(height: 12),

          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.person, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userName.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
              if (featured)
                _badge('Featured', Colors.orange),
              if (hidden)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _badge('Hidden', Colors.red),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title.toString(),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            content.toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: Colors.red[400]),
              const SizedBox(width: 4),
              Text(likes.toString()),
              const SizedBox(width: 14),
              const Icon(Icons.comment, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 4),
              Text(comments.toString()),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'featured') {
                    _toggleFeatured(id, featured);
                  } else if (value == 'hidden') {
                    _toggleHidden(id, hidden);
                  } else if (value == 'delete') {
                    _confirmDelete(id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'featured',
                    child: Text(
                      featured ? 'Remove Featured' : 'Mark Featured',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hidden',
                    child: Text(
                      hidden ? 'Unhide Post' : 'Hide Post',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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