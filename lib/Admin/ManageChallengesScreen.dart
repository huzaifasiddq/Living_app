import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageChallengesScreen extends StatefulWidget {
  const ManageChallengesScreen({super.key});

  @override
  State<ManageChallengesScreen> createState() => _ManageChallengesScreenState();
}

class _ManageChallengesScreenState extends State<ManageChallengesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteChallenge(String id) async {
    await FirebaseFirestore.instance.collection('challenges').doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Challenge deleted')),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challenge?'),
        content: const Text('Are you sure you want to delete this challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteChallenge(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterChallenges(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();

      return title.contains(query) || category.contains(query);
    }).toList();
  }

  void _openAddChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditChallengeScreen(),
      ),
    );
  }

  void _openEditChallenge(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditChallengeScreen(
          challengeId: id,
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
          'Manage Challenges',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _openAddChallenge,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('challenges')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final challenges =
                    _filterChallenges(snapshot.data?.docs ?? []);

                if (challenges.isEmpty) {
                  return Center(
                    child: Text(
                      'No challenges found',
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
                  itemCount: challenges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = challenges[index];
                    final data = doc.data();

                    return _challengeCard(
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
          hintText: 'Search challenges',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _challengeCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] ?? 'No Title';
    final category = data['category'] ?? 'Eco Challenge';
    final duration = data['duration'] ?? '';
    final points = data['points'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF2E7D32),
              size: 32,
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
                Row(
                  children: [
                    if (duration.toString().isNotEmpty)
                      Text(
                        duration.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (duration.toString().isNotEmpty &&
                        points.toString().isNotEmpty)
                      const Text('  •  '),
                    if (points.toString().isNotEmpty)
                      Text(
                        '$points points',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditChallenge(id, data);
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
class AddEditChallengeScreen extends StatefulWidget {
  final String? challengeId;
  final Map<String, dynamic>? existingData;

  const AddEditChallengeScreen({
    super.key,
    this.challengeId,
    this.existingData,
  });

  @override
  State<AddEditChallengeScreen> createState() =>
      _AddEditChallengeScreenState();
}

class _AddEditChallengeScreenState extends State<AddEditChallengeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  bool get isEdit => widget.challengeId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;

    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _durationController.text = data['duration'] ?? '';
      _pointsController.text = data['points']?.toString() ?? '';
      _descriptionController.text = data['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _pointsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final challengeData = {
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'duration': _durationController.text.trim(),
        'points': _pointsController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(widget.challengeId)
            .update(challengeData);
      } else {
        await FirebaseFirestore.instance.collection('challenges').add({
          ...challengeData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Challenge updated' : 'Challenge added'),
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
          isEdit ? 'Edit Challenge' : 'Add Challenge',
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
              _challengeIcon(),

              const SizedBox(height: 18),

              _inputField(
                controller: _titleController,
                label: 'Challenge Title',
                icon: Icons.emoji_events,
                validator: 'Please enter challenge title',
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
                controller: _durationController,
                label: 'Duration e.g. 7 Days',
                icon: Icons.calendar_month,
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _pointsController,
                label: 'Reward Points',
                icon: Icons.star,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 5,
                validator: 'Please enter description',
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Update Challenge' : 'Add Challenge',
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

  Widget _challengeIcon() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: Icon(
          Icons.emoji_events,
          size: 70,
          color: Color(0xFF2E7D32),
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
    TextInputType keyboardType = TextInputType.text,
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