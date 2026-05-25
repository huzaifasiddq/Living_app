import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EcoTipsManagerScreen extends StatefulWidget {
  const EcoTipsManagerScreen({super.key});

  @override
  State<EcoTipsManagerScreen> createState() => _EcoTipsManagerScreenState();
}

class _EcoTipsManagerScreenState extends State<EcoTipsManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteTip(String id) async {
    await FirebaseFirestore.instance.collection('eco_tips').doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eco tip deleted')),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Eco Tip?'),
        content: const Text('Are you sure you want to delete this eco tip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteTip(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(String id, bool active) async {
    await FirebaseFirestore.instance.collection('eco_tips').doc(id).update({
      'active': !active,
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterTips(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final tip = (data['tip'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();

      return tip.contains(query) || category.contains(query);
    }).toList();
  }

  void _openAddTip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditEcoTipScreen(),
      ),
    );
  }

  void _openEditTip(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditEcoTipScreen(
          tipId: id,
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
          'Eco Tips Manager',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _openAddTip,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('eco_tips')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final tips = _filterTips(snapshot.data?.docs ?? []);

                if (tips.isEmpty) {
                  return Center(
                    child: Text(
                      'No eco tips found',
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
                  itemCount: tips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = tips[index];
                    final data = doc.data();

                    return _tipCard(
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
          hintText: 'Search eco tips',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _tipCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final tip = data['tip'] ?? data['text'] ?? 'No tip';
    final category = data['category'] ?? 'Eco Tip';
    final points = data['points'] ?? 0;
    final active = data['active'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? Colors.transparent
              : Colors.grey.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Center(
              child: Text(
                '🌱',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _badge(category.toString(), Colors.green),
                    const SizedBox(width: 6),
                    _badge('$points Points', Colors.orange),
                    const SizedBox(width: 6),
                    _badge(
                      active ? 'Active' : 'Inactive',
                      active ? Colors.teal : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditTip(id, data);
              } else if (value == 'active') {
                _toggleActive(id, active);
              } else if (value == 'delete') {
                _confirmDelete(id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'active',
                child: Text(active ? 'Deactivate' : 'Activate'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
class AddEditEcoTipScreen extends StatefulWidget {
  final String? tipId;
  final Map<String, dynamic>? existingData;

  const AddEditEcoTipScreen({
    super.key,
    this.tipId,
    this.existingData,
  });

  @override
  State<AddEditEcoTipScreen> createState() => _AddEditEcoTipScreenState();
}

class _AddEditEcoTipScreenState extends State<AddEditEcoTipScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tipController = TextEditingController();
  final _categoryController = TextEditingController();
  final _pointsController = TextEditingController();

  bool _isLoading = false;
  bool _active = true;

  bool get isEdit => widget.tipId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;

    if (data != null) {
      _tipController.text = data['tip'] ?? data['text'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _pointsController.text = data['points']?.toString() ?? '25';
      _active = data['active'] ?? true;
    }
  }

  @override
  void dispose() {
    _tipController.dispose();
    _categoryController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _saveTip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tipData = {
        'tip': _tipController.text.trim(),
        'category': _categoryController.text.trim(),
        'points': int.tryParse(_pointsController.text.trim()) ?? 0,
        'active': _active,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection('eco_tips')
            .doc(widget.tipId)
            .update(tipData);
      } else {
        await FirebaseFirestore.instance.collection('eco_tips').add({
          ...tipData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Eco tip updated' : 'Eco tip added')),
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
          isEdit ? 'Edit Eco Tip' : 'Add Eco Tip',
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
              _tipHeader(),
              const SizedBox(height: 18),

              _inputField(
                controller: _tipController,
                label: 'Eco Tip',
                icon: Icons.eco,
                maxLines: 4,
                validator: 'Please enter eco tip',
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
                controller: _pointsController,
                label: 'Reward Points',
                icon: Icons.star,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile(
                  value: _active,
                  activeColor: const Color(0xFF2E7D32),
                  title: Text(
                    'Active Tip',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Show this tip in user app',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _active = value);
                  },
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Update Eco Tip' : 'Add Eco Tip',
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

  Widget _tipHeader() {
    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          '🌱\nEco Tip',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
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
                if (value == null || value.trim().isEmpty) return validator;
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