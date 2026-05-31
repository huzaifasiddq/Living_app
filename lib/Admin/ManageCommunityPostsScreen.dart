import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

// Cloudinary settings
const String kCloudinaryCloudName = 'YOUR_CLOUD_NAME';
const String kCloudinaryUploadPreset = 'YOUR_UNSIGNED_UPLOAD_PRESET';

const Color _kGreen = Color(0xFF2E7D32);
const Color _kGreenDark = Color(0xFF1B5E20);
const Color _kGreenSurface = Color(0xFFE8F5E9);
const Color _kBg = Color(0xFFF1F8F1);

class ManageCommunityPostsScreen extends StatefulWidget {
  const ManageCommunityPostsScreen({super.key});

  @override
  State<ManageCommunityPostsScreen> createState() =>
      _ManageCommunityPostsScreenState();
}

class _ManageCommunityPostsScreenState
    extends State<ManageCommunityPostsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _db.collection('communityPosts').doc(postId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $e')),
      );
    }
  }

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Post?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this community post?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deletePost(postId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
      final description =
          (data['description'] ?? data['content'] ?? '').toString().toLowerCase();
      final userName = (data['userName'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          description.contains(query) ||
          userName.contains(query) ||
          category.contains(query);
    }).toList();
  }

  void _openAddPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminCreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: Text(
          'Manage Community Posts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openAddPostSheet,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Post',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPostSheet,
        backgroundColor: _kGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Post',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _adminSummary(),
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('communityPosts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Something went wrong',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  );
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    return _AdminPostCard(
                      id: doc.id,
                      data: doc.data(),
                      onDelete: () => _confirmDelete(doc.id),
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

  Widget _adminSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('communityPosts').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGreenDark, _kGreen]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(Icons.forum_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Community Control',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'View, add and delete community posts',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$count Posts',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _searchBox() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchText = value),
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: _kGreen),
          hintText: 'Search by title, user, category...',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }
}

class _AdminPostCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _AdminPostCard({
    required this.id,
    required this.data,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Community Post').toString();
    final description =
        (data['description'] ?? data['content'] ?? '').toString();
    final userName = (data['userName'] ?? 'Unknown User').toString();
    final userImage = (data['userImage'] ?? '').toString();
    final category = (data['category'] ?? 'Community').toString();
    final likes = data['likesCount'] ?? data['likes'] ?? 0;
    final comments = data['commentsCount'] ?? data['comments'] ?? 0;
    final createdAt = data['createdAt'];
    final imageUrls = _extractImages(data);

    String timeText = 'Unknown time';
    if (createdAt is Timestamp) {
      timeText = timeago.format(createdAt.toDate());
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(userImage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kGreenDark,
                      ),
                    ),
                    Text(
                      '$category • $timeText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Post',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kGreenDark,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.8,
                color: Colors.grey[700],
                height: 1.45,
              ),
            ),
          ],
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImageCollage(imageUrls: imageUrls),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.favorite, likes.toString(), Colors.red),
              const SizedBox(width: 14),
              _meta(Icons.comment, comments.toString(), _kGreen),
              const Spacer(),
              Text(
                'Post ID: ${id.substring(0, id.length > 6 ? 6 : id.length)}',
                style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<String> _extractImages(Map<String, dynamic> data) {
    final images = data['images'];
    if (images is List) {
      return images.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final image = data['image'] ?? data['imageUrl'];
    if (image != null && image.toString().isNotEmpty) {
      return [image.toString()];
    }

    return [];
  }

  Widget _avatar(String url) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kGreen, width: 2),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? Container(
                color: _kGreenSurface,
                child: const Icon(Icons.person, color: _kGreen),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: _kGreenSurface,
                  child: const Icon(Icons.person, color: _kGreen),
                ),
              ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _ImageCollage extends StatelessWidget {
  final List<String> imageUrls;
  const _ImageCollage({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.take(4).toList();

    if (urls.length == 1) {
      return _image(urls[0], height: 170);
    }

    if (urls.length == 2) {
      return SizedBox(
        height: 150,
        child: Row(
          children: [
            Expanded(child: _image(urls[0])),
            const SizedBox(width: 6),
            Expanded(child: _image(urls[1])),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(flex: 2, child: _image(urls[0])),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _image(urls[1])),
                const SizedBox(height: 6),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _image(urls[2]),
                      if (imageUrls.length > 3)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '+${imageUrls.length - 3}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(String url, {double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        height: height ?? double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: _kGreenSurface),
        errorWidget: (_, __, ___) => Container(
          color: _kGreenSurface,
          child: const Icon(Icons.image_outlined, color: _kGreen),
        ),
      ),
    );
  }
}

class _AdminCreatePostSheet extends StatefulWidget {
  const _AdminCreatePostSheet();

  @override
  State<_AdminCreatePostSheet> createState() => _AdminCreatePostSheetState();
}

class _AdminCreatePostSheetState extends State<_AdminCreatePostSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  final List<XFile> _pickedImages = [];
  bool _loading = false;
  String _category = 'Admin Post';

  final List<String> _categories = const [
    'Admin Post',
    'Announcement',
    'Eco Tips',
    'Sustainability',
    'Green Living',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;
    setState(() {
      _pickedImages.addAll(files);
    });
  }

  Future<String> _uploadToCloudinary(XFile file) async {
    if (kCloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
        kCloudinaryUploadPreset == 'YOUR_UNSIGNED_UPLOAD_PRESET') {
      throw Exception('Cloudinary cloud name/upload preset set nahi kiya gaya.');
    }

    final Uint8List bytes = await file.readAsBytes();
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = kCloudinaryUploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    return decoded['secure_url'].toString();
  }

  Future<Map<String, dynamic>> _getAdminData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'uid': 'admin',
        'name': 'Admin',
        'image': '',
      };
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    return {
      'uid': user.uid,
      'name': userData['fullName'] ?? user.displayName ?? 'Admin',
      'image': userData['profileImage'] ?? user.photoURL ?? '',
    };
  }

  Future<void> _submitPost() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title required')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final admin = await _getAdminData();
      final imageUrls = <String>[];

      for (final image in _pickedImages) {
        final url = await _uploadToCloudinary(image);
        imageUrls.add(url);
      }

      await _db.collection('communityPosts').add({
        'userId': admin['uid'],
        'userName': admin['name'],
        'userImage': admin['image'],
        'postedByRole': 'admin',
        'badge': 'Admin',
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'content': _descriptionCtrl.text.trim(),
        'images': imageUrls,
        'image': imageUrls.isNotEmpty ? imageUrls.first : '',
        'likes': 0,
        'likesCount': 0,
        'likedBy': [],
        'comments': 0,
        'commentsCount': 0,
        'shares': 0,
        'points': 0,
        'category': _category,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post add error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Add Community Post',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kGreenDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Title'),
                      _input(_titleCtrl, 'Enter post title', maxLines: 1),
                      const SizedBox(height: 14),
                      _label('Description'),
                      _input(_descriptionCtrl, 'Enter post description', maxLines: 4),
                      const SizedBox(height: 14),
                      _label('Category'),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: _categories
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                        decoration: _fieldDecoration(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _label('Images')),
                          TextButton.icon(
                            onPressed: _loading ? null : _pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Pick Images'),
                          ),
                        ],
                      ),
                      if (_pickedImages.isEmpty)
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _kGreenSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image_outlined, color: _kGreen, size: 34),
                              const SizedBox(height: 6),
                              Text(
                                'No images selected',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: FutureBuilder<Uint8List>(
                                      future: _pickedImages[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Container(
                                            width: 95,
                                            height: 95,
                                            color: _kGreenSurface,
                                          );
                                        }
                                        return Image.memory(
                                          snapshot.data!,
                                          width: 95,
                                          height: 95,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: _loading
                                          ? null
                                          : () {
                                              setState(() {
                                                _pickedImages.removeAt(index);
                                              });
                                            },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Publish Post',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kGreenDark,
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: _fieldDecoration(hint: hint),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey),
      filled: true,
      fillColor: _kGreenSurface.withOpacity(0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kGreen, width: 1.4),
      ),
    );
  }
}
