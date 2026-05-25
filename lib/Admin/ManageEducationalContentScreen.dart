import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageEducationalContentScreen extends StatefulWidget {
  const ManageEducationalContentScreen({super.key});

  @override
  State<ManageEducationalContentScreen> createState() =>
      _ManageEducationalContentScreenState();
}

class _ManageEducationalContentScreenState
    extends State<ManageEducationalContentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteContent(String id) async {
    await FirebaseFirestore.instance
        .collection('educational_content')
        .doc(id)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content deleted')),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Content?'),
        content: const Text('Are you sure you want to delete this content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteContent(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final type = (data['type'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          type.contains(query);
    }).toList();
  }

  void _openAddContent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditEducationalContentScreen(),
      ),
    );
  }

  void _openEditContent(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditEducationalContentScreen(
          contentId: id,
          existingData: data,
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
          'Educational Content',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _openAddContent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('educational_content')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final contents = _filterContent(snapshot.data?.docs ?? []);

                if (contents.isEmpty) {
                  return Center(
                    child: Text(
                      'No content found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  physics: const BouncingScrollPhysics(),
                  itemCount: contents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = contents[index];
                    final data = doc.data();

                    return _contentCard(
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
          hintText: 'Search content',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _contentCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] ?? 'No Title';
    final category = data['category'] ?? 'Environment';
    final type = data['type'] ?? 'Article';
    final imageUrl = data['imageUrl'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl.toString().isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFE8F5E9),
                    child: const Icon(
                      Icons.article,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  category.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  type.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditContent(id, data);
              } else if (value == 'delete') {
                _confirmDelete(id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class AddEditEducationalContentScreen extends StatefulWidget {
  final String? contentId;
  final Map<String, dynamic>? existingData;

  const AddEditEducationalContentScreen({
    super.key,
    this.contentId,
    this.existingData,
  });

  @override
  State<AddEditEducationalContentScreen> createState() =>
      _AddEditEducationalContentScreenState();
}

class _AddEditEducationalContentScreenState
    extends State<AddEditEducationalContentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _typeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  bool get isEdit => widget.contentId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;

    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _typeController.text = data['type'] ?? '';
      _imageUrlController.text = data['imageUrl'] ?? '';
      _videoUrlController.text = data['videoUrl'] ?? '';
      _descriptionController.text = data['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _typeController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contentData = {
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'type': _typeController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'videoUrl': _videoUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('educational_content')
            .doc(widget.contentId)
            .update(contentData);
      } else {
        await FirebaseFirestore.instance.collection('educational_content').add({
          ...contentData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Content updated' : 'Content added'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Content' : 'Add Content',
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
              _imagePreview(),

              const SizedBox(height: 18),

              _inputField(
                controller: _titleController,
                label: 'Content Title',
                icon: Icons.article,
                validator: 'Please enter content title',
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _categoryController,
                label: 'Category',
                icon: Icons.category,
                validator: 'Please enter category',
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _typeController,
                label: 'Type e.g. Article / Video / Infographic',
                icon: Icons.type_specimen,
                validator: 'Please enter content type',
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _imageUrlController,
                label: 'Image URL',
                icon: Icons.image,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _videoUrlController,
                label: 'Video URL Optional',
                icon: Icons.video_library,
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 6,
                validator: 'Please enter description',
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Update Content' : 'Add Content',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Widget _imagePreview() {
    final imageUrl = _imageUrlController.text.trim();

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _emptyImage(),
              )
            : _emptyImage(),
      ),
    );
  }

  Widget _emptyImage() {
    return const Center(
      child: Icon(
        Icons.article_outlined,
        size: 58,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
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
}