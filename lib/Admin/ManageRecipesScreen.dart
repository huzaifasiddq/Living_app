import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageRecipesScreen extends StatefulWidget {
  const ManageRecipesScreen({super.key});

  @override
  State<ManageRecipesScreen> createState() => _ManageRecipesScreenState();
}

class _ManageRecipesScreenState extends State<ManageRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteRecipe(String id) async {
    await FirebaseFirestore.instance.collection('recipes').doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe deleted')),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteRecipe(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterRecipes(
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

  void _openAddRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditRecipeScreen(),
      ),
    );
  }

  void _openEditRecipe(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditRecipeScreen(
          recipeId: id,
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
          'Manage Recipes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _openAddRecipe,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final recipes = _filterRecipes(snapshot.data?.docs ?? []);

                if (recipes.isEmpty) {
                  return Center(
                    child: Text(
                      'No recipes found',
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
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = recipes[index];
                    final data = doc.data();

                    return _recipeCard(
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
          hintText: 'Search recipes',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _recipeCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] ?? 'No Title';
    final category = data['category'] ?? 'Eco Recipe';
    final imageUrl = data['imageUrl'] ?? '';
    final duration = data['duration'] ?? '';

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
                      Icons.restaurant,
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
                if (duration.toString().isNotEmpty)
                  Text(
                    duration.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditRecipe(id, data);
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
class AddEditRecipeScreen extends StatefulWidget {
  final String? recipeId;
  final Map<String, dynamic>? existingData;

  const AddEditRecipeScreen({
    super.key,
    this.recipeId,
    this.existingData,
  });

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();

  bool _isLoading = false;

  bool get isEdit => widget.recipeId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;

    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _durationController.text = data['duration'] ?? '';
      _imageUrlController.text = data['imageUrl'] ?? '';
      _ingredientsController.text = data['ingredients'] ?? '';
      _stepsController.text = data['steps'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final recipeData = {
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'duration': _durationController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'ingredients': _ingredientsController.text.trim(),
        'steps': _stepsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipeId)
            .update(recipeData);
      } else {
        await FirebaseFirestore.instance.collection('recipes').add({
          ...recipeData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Recipe updated' : 'Recipe added'),
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
          isEdit ? 'Edit Recipe' : 'Add Recipe',
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
                label: 'Recipe Title',
                icon: Icons.restaurant,
                validator: 'Please enter recipe title',
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
                label: 'Duration e.g. 20 min',
                icon: Icons.timer,
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
                controller: _ingredientsController,
                label: 'Ingredients',
                icon: Icons.list_alt,
                maxLines: 4,
                validator: 'Please enter ingredients',
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: _stepsController,
                label: 'Cooking Steps',
                icon: Icons.description,
                maxLines: 5,
                validator: 'Please enter cooking steps',
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Update Recipe' : 'Add Recipe',
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
        Icons.image_outlined,
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