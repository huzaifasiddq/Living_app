import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CommunityScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const CommunityScreen({super.key, this.onBackTap});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final visibleDocs = docs
        .where((doc) => doc.data()['hidden'] != true)
        .toList();

    if (searchText.trim().isEmpty) return visibleDocs;

    final query = searchText.toLowerCase();

    return visibleDocs.where((doc) {
      final data = doc.data();

      final title = (data['title'] ?? '').toString().toLowerCase();
      final content = (data['content'] ?? '').toString().toLowerCase();
      final userName = (data['userName'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          content.contains(query) ||
          userName.contains(query);
    }).toList();
  }

  Future<void> _likePost({
    required String postId,
    required int currentLikes,
    required List likedBy,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    if (likedBy.contains(user.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already liked this post')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(postId)
        .update({
          'likes': currentLikes + 1,
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
  }

  void _openAddPost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCommunityPostScreen()),
    );
  }

  void _openComments(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (widget.onBackTap != null) {
              widget.onBackTap!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Community Forum',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _openAddPost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final posts = _filterPosts(snapshot.data?.docs ?? []);

                posts.sort((a, b) {
                  final aTime = a.data()['createdAt'];
                  final bTime = b.data()['createdAt'];

                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }
                  return 0;
                });

                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      'No community posts yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  physics: const BouncingScrollPhysics(),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final doc = posts[index];

                    return _postCard(postId: doc.id, data: doc.data());
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
        onChanged: (value) => setState(() => searchText = value),
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
          hintText: 'Search community posts',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _postCard({
    required String postId,
    required Map<String, dynamic> data,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    final title = data['title'] ?? 'Community Post';
    final content = data['content'] ?? '';
    final userName = data['userName'] ?? 'Eco User';
    final imageUrl = data['imageUrl'] ?? '';
    final likes = data['likes'] ?? 0;
    final comments = data['comments'] ?? 0;
    final likedBy = data['likedBy'] ?? [];
    final featured = data['featured'] == true;

    final isLiked = user != null && likedBy.contains(user.uid);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl.toString(),
                width: double.infinity,
                height: 165,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 165,
                  color: const Color(0xFFE8F5E9),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),

          if (imageUrl.toString().isNotEmpty) const SizedBox(height: 12),

          Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.person, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userName.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
              if (featured) _badge('Featured', Colors.orange),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            content.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.45,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              InkWell(
                onTap: () => _likePost(
                  postId: postId,
                  currentLikes: int.tryParse(likes.toString()) ?? 0,
                  likedBy: likedBy,
                ),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 19,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      likes.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _openComments(postId),
                child: Row(
                  children: [
                    const Icon(
                      Icons.comment,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      comments.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class AddCommunityPostScreen extends StatefulWidget {
  const AddCommunityPostScreen({super.key});

  @override
  State<AddCommunityPostScreen> createState() => _AddCommunityPostScreenState();
}

class _AddCommunityPostScreenState extends State<AddCommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _imageBytes;

  bool _isLoading = false;

  final String cloudName = 'dsufgen5z';
  final String uploadPreset = 'ecoaphere';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _pickedImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<String> _uploadToCloudinary() async {
    if (_pickedImage == null || _imageBytes == null) return '';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: _pickedImage!.name,
        ),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: _pickedImage!.name,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      return jsonData['secure_url'];
    }

    return '';
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 'Eco User';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    return data?['fullName'] ?? data?['name'] ?? user.email ?? 'Eco User';
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = await _getUserName();
      final imageUrl = await _uploadToCloudinary();

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user?.uid ?? '',
        'userName': userName,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl,
        'likes': 0,
        'likedBy': [],
        'comments': 0,
        'featured': false,
        'hidden': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post added successfully')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _imagePickerBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 185,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.25)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _imageBytes != null
              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate,
                      size: 58,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select post image',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator == null
            ? null
            : (value) {
                if (value == null || value.trim().isEmpty) {
                  return validator;
                }
                return null;
              },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
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
          'Add Community Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _imagePickerBox(),

              const SizedBox(height: 16),

              _inputField(
                controller: _titleController,
                label: 'Post Title',
                icon: Icons.title,
                validator: 'Please enter post title',
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _contentController,
                label: 'Post Content',
                icon: Icons.description,
                maxLines: 6,
                validator: 'Please enter post content',
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Publish Post',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 'Eco User';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    return data?['fullName'] ?? data?['name'] ?? user.email ?? 'Eco User';
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userName = await _getUserName();

    final postRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId);

    await postRef.collection('comments_list').add({
      'userId': user?.uid ?? '',
      'userName': userName,
      'comment': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await postRef.update({'comments': FieldValue.increment(1)});

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId)
        .collection('comments_list')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          'Comments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsRef.snapshots(),
              builder: (context, snapshot) {
                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = comments[index].data();

                    return Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${data['userName'] ?? 'Eco User'}\n${data['comment'] ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
