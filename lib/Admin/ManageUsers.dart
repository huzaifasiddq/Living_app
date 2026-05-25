import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteUser(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted from Firestore')),
    );
  }

  Future<void> _updateUserStatus(String docId, bool blocked) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'blocked': blocked,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(blocked ? 'User blocked' : 'User unblocked'),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text(
          'This will delete user data from Firestore only.',
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
              _deleteUser(docId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data();

      final name = (data['fullName'] ?? data['name'] ?? '').toString();
      final email = (data['email'] ?? '').toString();
      final role = (data['role'] ?? '').toString();

      final query = searchText.toLowerCase();

      return name.toLowerCase().contains(query) ||
          email.toLowerCase().contains(query) ||
          role.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          'Manage Users',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('email')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final users = _filterUsers(docs);

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data();

                    final name =
                        data['fullName'] ?? data['name'] ?? 'Unknown User';
                    final email = data['email'] ?? 'No Email';
                    final role = data['role'] ?? 'user';
                    final blocked = data['blocked'] == true;
                    final image = data['profileImage'] ?? data['photoUrl'];

                    return _userCard(
                      docId: doc.id,
                      name: name.toString(),
                      email: email.toString(),
                      role: role.toString(),
                      blocked: blocked,
                      image: image?.toString(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => searchText = value);
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
          hintText: 'Search users by name, email or role',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _userCard({
    required String docId,
    required String name,
    required String email,
    required String role,
    required bool blocked,
    required String? image,
  }) {
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage:
                image != null && image.isNotEmpty ? NetworkImage(image) : null,
            child: image == null || image.isEmpty
                ? const Icon(Icons.person, color: Color(0xFF2E7D32))
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge(
                      isAdmin ? 'Admin' : 'User',
                      isAdmin ? Colors.deepPurple : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    _badge(
                      blocked ? 'Blocked' : 'Active',
                      blocked ? Colors.red : Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                _updateUserStatus(docId, true);
              } else if (value == 'unblock') {
                _updateUserStatus(docId, false);
              } else if (value == 'delete') {
                _confirmDelete(docId);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: blocked ? 'unblock' : 'block',
                child: Text(blocked ? 'Unblock' : 'Block'),
              ),
              if (!isAdmin)
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}