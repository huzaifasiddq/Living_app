import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
//  CLOUDINARY CONFIG
// ─────────────────────────────────────────────
// Apna Cloudinary cloud name aur unsigned upload preset yahan lagao.
const String kCloudinaryCloudName = 'dsufgen5z';
const String kCloudinaryUploadPreset = 'ecoaphere';

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────
const _kGreen = Color(0xFF2E7D32);
const _kGreenDark = Color(0xFF1B5E20);
const _kGreenAccent = Color(0xFF66BB6A);
const _kGreenSurface = Color(0xFFE8F5E9);
const _kGreenChip = Color(0xFFDCEDC8);
const _kWhite = Colors.white;
const _kShadow = Color(0x204CAF50);

class CommunityForumScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const CommunityForumScreen({
    super.key,
    this.onBackTap,
  });

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot> get _statsStream =>
      _db.collection('communityStats').doc('stats').snapshots();

  Stream<QuerySnapshot> get _categoriesStream =>
      _db.collection('communityCategories').orderBy('title').snapshots();

  Stream<QuerySnapshot> get _featuredStream => _db
      .collection('featuredDiscussions')
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots();

  Stream<QuerySnapshot> get _postsStream {
    Query q = _db
        .collection('communityPosts')
        .orderBy('createdAt', descending: true)
        .limit(20);
    if (_selectedCategory != 'All') {
      q = q.where('category', isEqualTo: _selectedCategory);
    }
    return q.snapshots();
  }

  Stream<QuerySnapshot> get _trendingStream => _db
      .collection('communityPosts')
      .orderBy('likes', descending: true)
      .limit(5)
      .snapshots();

  Future<void> _toggleLike(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(_greenSnack('Please login first'));
      return;
    }

    final postRef = _db.collection('communityPosts').doc(postId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(postRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final alreadyLiked = likedBy.contains(uid);

      if (alreadyLiked) {
        likedBy.remove(uid);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(uid);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> _incrementShare(String postId) async {
    await _db.collection('communityPosts').doc(postId).update({
      'shares': FieldValue.increment(1),
    });
  }

  Future<void> _joinChallenge(String discussionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || discussionId.isEmpty) return;

    await _db
        .collection('featuredDiscussions')
        .doc(discussionId)
        .collection('participants')
        .doc(uid)
        .set({'joinedAt': FieldValue.serverTimestamp()});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(_greenSnack('🌱 You joined the challenge!'));
    }
  }

  SnackBar _greenSnack(String msg) => SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: _kWhite, fontWeight: FontWeight.w500),
        ),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildStatsCard(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildFeaturedBanner(),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                const SizedBox(height: 16),
                _buildPostFeed(),
                const SizedBox(height: 20),
                _buildTrendingSection(),
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
  return Stack(
    children: [
      SizedBox(
        height: 220,
        width: double.infinity,
        child: Image.asset(
          'assets/images/community_header.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _greenGradientBox(),
        ),
      ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kGreenDark.withOpacity(0.78),
                _kGreen.withOpacity(0.52),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: widget.onBackTap ?? () => Navigator.maybePop(context),
                    ),
                    _circleButton(
                      icon: Icons.notifications_outlined,
                      onTap: () {},
                      badge: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Community Forum',
                  style: GoogleFonts.poppins(
                    color: _kWhite,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect, Share & Inspire Sustainable Living',
                  style: GoogleFonts.poppins(
                    color: _kWhite.withOpacity(0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _greenGradientBox() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreenDark, _kGreen, _kGreenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap, bool badge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kWhite.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: _kWhite, size: 18),
              ),
            ),
          ),
          if (badge)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFFF5722), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _statsStream,
        builder: (context, snap) {
          final data = snap.hasData && snap.data!.exists ? snap.data!.data() as Map : <dynamic, dynamic>{};

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: _whiteCardDecoration(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(icon: Icons.people_alt_outlined, value: _formatNum(data['totalMembers'] ?? 12800), label: 'Total\nMembers'),
                _divider(),
                _statItem(icon: Icons.chat_bubble_outline_rounded, value: _formatNum(data['activeDiscussions'] ?? 856), label: 'Active\nDiscussions'),
                _divider(),
                _statItem(icon: Icons.eco_outlined, value: _formatNum(data['impactScore'] ?? 4782), label: 'Impact\nScore'),
                _divider(),
                _statItem(icon: Icons.article_outlined, value: _formatNum(data['postsToday'] ?? 320), label: 'Posts\nToday'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem({required IconData icon, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: _kGreenSurface, shape: BoxShape.circle),
          child: Icon(icon, color: _kGreen, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B2926))),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey.shade600, height: 1.3)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 50, color: Colors.grey.shade200);

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: _whiteCardDecoration(14),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                decoration: InputDecoration(
                  hintText: 'Search discussions, topics, members...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.tune_rounded, color: _kWhite, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(onApply: (filter) => setState(() => _selectedCategory = filter)),
    );
  }

  Widget _buildFeaturedBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _featuredStream,
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _featuredCard(
              docId: '',
              title: 'Green Future Challenge',
              description: 'Join our community challenge and make a real impact on Earth.',
              imageUrl: 'https://images.unsplash.com/photo-1520697222867-4b934af0ede5?auto=format&fit=crop&w=1000&q=80',
              points: 150,
            );
          }
          final doc = snap.data!.docs.first;
          final d = doc.data() as Map;
          return _featuredCard(
            docId: doc.id,
            title: d['title'] ?? 'Green Future Challenge',
            description: d['description'] ?? 'Join our community challenge and make a real impact on Earth.',
            imageUrl: d['image'] ?? 'https://images.unsplash.com/photo-1520697222867-4b934af0ede5?auto=format&fit=crop&w=1000&q=80',
            points: d['points'] ?? 150,
          );
        },
      ),
    );
  }

  Widget _featuredCard({required String docId, required String title, required String description, required String imageUrl, required int points}) {
    return Container(
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _kShadow, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 165,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: _kGreen),
              errorWidget: (_, __, ___) => _greenGradientBox(),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kGreenDark.withOpacity(0.88), Colors.black.withOpacity(0.18)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kGreenAccent, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: _kWhite, size: 12),
                      const SizedBox(width: 4),
                      Text('Featured Discussion', style: GoogleFonts.poppins(color: _kWhite, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(title, style: GoogleFonts.poppins(color: _kWhite, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: _kWhite.withOpacity(0.85), fontSize: 11)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _joinChallenge(docId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Join Challenge', style: GoogleFonts.poppins(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, color: _kGreen, size: 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 16,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _kWhite.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: _kWhite.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco_rounded, color: _kWhite, size: 14),
                  Text('+$points', style: GoogleFonts.poppins(color: _kWhite, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return StreamBuilder<QuerySnapshot>(
      stream: _categoriesStream,
      builder: (context, snap) {
        final List<Map<String, String>> cats = [{'title': 'All', 'icon': '🌿'}];
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map;
            cats.add({'title': d['title']?.toString() ?? '', 'icon': d['icon']?.toString() ?? '🌱'});
          }
        } else {
          cats.addAll([
            {'title': 'Recycling', 'icon': '♻️'},
            {'title': 'Sustainability', 'icon': '🌱'},
            {'title': 'Green Living', 'icon': '🏡'},
            {'title': 'Eco Tips', 'icon': '💡'},
          ]);
        }

        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = cats[i];
              final selected = _selectedCategory == c['title'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c['title']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : _kWhite,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: selected ? _kGreen.withOpacity(0.4) : _kShadow, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c['icon']!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(c['title']!, style: GoogleFonts.poppins(color: selected ? _kWhite : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: _postsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _kGreen)));
        }
        if (snap.hasError) return _errorWidget('Unable to load posts');
        if (!snap.hasData || snap.data!.docs.isEmpty) return _emptyWidget('No posts found');

        final docs = snap.data!.docs.where((d) {
          if (_searchQuery.isEmpty) return true;
          final data = d.data() as Map;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final desc = (data['description'] ?? '').toString().toLowerCase();
          final user = (data['userName'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || desc.contains(_searchQuery) || user.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return _emptyWidget('No matching posts found');

        final currentUserId = _auth.currentUser?.uid ?? '';
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _PostCard(
              postId: doc.id,
              data: d,
              currentUserId: currentUserId,
              onLike: () => _toggleLike(doc.id),
              onComment: () => _openComments(doc.id),
              onShare: () => _incrementShare(doc.id),
            );
          }).toList(),
        );
      },
    );
  }

  void _openComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: postId, db: _db, auth: _auth),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7043), size: 18),
                  const SizedBox(width: 6),
                  Text('Trending Discussions', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B2926))),
                ],
              ),
              Text('Top Likes', style: GoogleFonts.poppins(fontSize: 12, color: _kGreen, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _trendingStream,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: _kGreen)));
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) return _emptyWidget('No trending discussions');
            return SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _TrendingCard(data: d);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showCreatePostModal,
      backgroundColor: _kGreen,
      elevation: 8,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, color: _kWhite, size: 28),
    );
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(db: _db, auth: _auth),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stay connected. Stay green.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Text('🌿', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatNum(dynamic n) {
    final double v = (n is int ? n.toDouble() : (n is double ? n : 0.0));
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  BoxDecoration _whiteCardDecoration(double radius) {
    return BoxDecoration(
      color: _kWhite,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [BoxShadow(color: _kShadow, blurRadius: 20, offset: const Offset(0, 6))],
    );
  }

  Widget _errorWidget(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 36),
            const SizedBox(height: 8),
            Text(msg, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );

  Widget _emptyWidget(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(msg, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );
}

class _PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _PostCard({
    required this.postId,
    required this.data,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(_scaleCtrl);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _animateLike() async {
    await _scaleCtrl.forward();
    await _scaleCtrl.reverse();
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final ts = d['createdAt'];
    String timeStr = 'Just now';
    if (ts is Timestamp) timeStr = timeago.format(ts.toDate());

    final likedBy = List<String>.from(d['likedBy'] ?? []);
    final isLiked = likedBy.contains(widget.currentUserId);
    final imageUrls = _extractImages(d);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _kShadow, blurRadius: 18, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
              child: Row(
                children: [
                  _avatar(d['userImage'] ?? ''),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                d['userName'] ?? 'Anonymous',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1B2926)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if ((d['badge'] ?? '').toString().isNotEmpty) _badge(d['badge']),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(timeStr, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade400)),
                            const SizedBox(width: 4),
                            const Icon(Icons.history_rounded, size: 11, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                    onPressed: () => _showPostMenu(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (imageUrls.isNotEmpty) _ImageCollage(imageUrls: imageUrls),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d['title'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B2926)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🌿', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            if ((d['description'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  d['description'],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600, height: 1.5),
                ),
              ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: GestureDetector(
                      onTap: _animateLike,
                      child: Row(
                        children: [
                          Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? const Color(0xFFE53935) : Colors.grey, size: 19),
                          const SizedBox(width: 4),
                          Text('${d['likes'] ?? 0}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onComment,
                    child: _actionBtn(Icons.chat_bubble_outline_rounded, '${d['commentsCount'] ?? d['comments'] ?? 0}', Colors.blue.shade400),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onShare,
                    child: _actionBtn(Icons.share_outlined, '${d['shares'] ?? 0}', Colors.purple.shade300),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _kGreenSurface, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_outlined, color: _kGreen, size: 13),
                        const SizedBox(width: 4),
                        Text('+${d['points'] ?? 0} Points', style: GoogleFonts.poppins(fontSize: 10.5, color: _kGreen, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractImages(Map<String, dynamic> data) {
    if (data['imageUrls'] is List) {
      return List<String>.from(data['imageUrls']).where((e) => e.trim().isNotEmpty).toList();
    }
    final oldImage = (data['image'] ?? '').toString();
    return oldImage.isNotEmpty ? [oldImage] : [];
  }

  Widget _avatar(String url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _kGreenAccent, width: 2)),
      child: ClipOval(
        child: url.isEmpty
            ? Container(color: _kGreenSurface, child: const Icon(Icons.person, color: _kGreen))
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: _kGreenSurface),
                errorWidget: (_, __, ___) => Container(color: _kGreenSurface, child: const Icon(Icons.person, color: _kGreen)),
              ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _kGreenChip, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: _kGreen, size: 10),
          const SizedBox(width: 3),
          Text(text, style: GoogleFonts.poppins(fontSize: 9.5, color: _kGreenDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 17),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
    ]);
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(Icons.bookmark_border_rounded, 'Save Post', () => Navigator.pop(context)),
            _menuItem(Icons.share_outlined, 'Share Post', () => Navigator.pop(context)),
            _menuItem(Icons.flag_outlined, 'Report', () => Navigator.pop(context), color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = const Color(0xFF1B2926)}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ImageCollage extends StatelessWidget {
  final List<String> imageUrls;

  const _ImageCollage({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.length;

    if (count == 1) {
      return _imageBox(
        imageUrls[0],
        height: 210,
        width: double.infinity,
      );
    }

    if (count == 2) {
      return SizedBox(
        height: 210,
        child: Row(
          children: [
            Expanded(child: _imageBox(imageUrls[0])),
            const SizedBox(width: 2),
            Expanded(child: _imageBox(imageUrls[1])),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _imageBox(imageUrls[0]),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _imageBox(imageUrls[1])),
                  const SizedBox(height: 2),
                  Expanded(child: _imageBox(imageUrls[2])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 230,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _imageBox(imageUrls[0])),
                const SizedBox(width: 2),
                Expanded(child: _imageBox(imageUrls[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _imageBox(imageUrls[2])),
                const SizedBox(width: 2),
                Expanded(
                  child: _imageBox(
                    imageUrls[3],
                    overlayText: count > 4 ? '+${count - 4}' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageBox(
    String url, {
    double? height,
    double? width,
    String? overlayText,
  }) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: _kGreenSurface),
            errorWidget: (_, __, ___) => Container(
              color: _kGreenSurface,
              child: const Icon(
                Icons.image_outlined,
                color: _kGreenAccent,
                size: 40,
              ),
            ),
          ),

          if (overlayText != null)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Text(
                  overlayText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TrendingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final images = data['imageUrls'] is List ? List<String>.from(data['imageUrls']) : <String>[];
    final image = images.isNotEmpty ? images.first : (data['image'] ?? '').toString();

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _kShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: image,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(height: 80, color: _kGreenSurface),
              errorWidget: (_, __, ___) => Container(height: 80, color: _kGreenSurface, child: const Icon(Icons.image_outlined, color: _kGreenAccent)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1B2926), height: 1.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Color(0xFFE53935), size: 12),
                    const SizedBox(width: 3),
                    Text('${data['likes'] ?? 0} likes', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  const _CreatePostSheet({required this.db, required this.auth});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _category = 'Sustainability';
  bool _loading = false;
  List<XFile> _pickedImages = [];

  static const List<String> _categories = ['Recycling', 'Sustainability', 'Green Living', 'Eco Tips'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;
    setState(() => _pickedImages = images.take(8).toList());
  }

  Future<String> _uploadToCloudinary(XFile file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload');
    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = kCloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final jsonData = jsonDecode(body) as Map<String, dynamic>;
    return jsonData['secure_url'] as String;
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(_snack('Title aur description required hain'));
      return;
    }

    final user = widget.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(_snack('Please login first'));
      return;
    }

    setState(() => _loading = true);

    try {
      final userDoc = await widget.db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final imageUrls = <String>[];
      for (final image in _pickedImages) {
        imageUrls.add(await _uploadToCloudinary(image));
      }

      await widget.db.collection('communityPosts').add({
        'userId': user.uid,
        'userName': userData['fullName'] ?? user.displayName ?? 'Eco Member',
        'userImage': userData['profileImage'] ?? user.photoURL ?? '',
        'badge': userData['ecoTitle'] ?? 'Eco Contributor',
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrls': imageUrls,
        'image': imageUrls.isNotEmpty ? imageUrls.first : '',
        'likes': 0,
        'likedBy': <String>[],
        'commentsCount': 0,
        'shares': 0,
        'points': 10,
        'category': _category,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(_snack('Post create nahi hui: $e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  SnackBar _snack(String msg) => SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: _kWhite,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text('Create Post', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1B2926))),
                  ],
                ),
                const SizedBox(height: 16),
                _field(_titleCtrl, 'Post title...', maxLines: 1),
                const SizedBox(height: 10),
                _field(_descCtrl, 'Share your eco thoughts...', maxLines: 4),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _loading ? null : _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kGreenSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kGreen.withOpacity(0.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, color: _kGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedImages.isEmpty ? 'Pick images for collage' : '${_pickedImages.length} image selected',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kGreenDark),
                          ),
                        ),
                        const Icon(Icons.add_rounded, color: _kGreen),
                      ],
                    ),
                  ),
                ),
                if (_pickedImages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pickedImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => FutureBuilder<Widget>(
                        future: _previewImage(_pickedImages[i]),
                        builder: (_, snap) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: _kGreenSurface,
                            child: snap.data ?? const Center(child: Icon(Icons.image, color: _kGreen)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final sel = _category == c;
                    return ChoiceChip(
                      label: Text(c, style: GoogleFonts.poppins(fontSize: 11, color: sel ? _kWhite : Colors.grey.shade700, fontWeight: FontWeight.w500)),
                      selected: sel,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: _kGreen,
                      backgroundColor: _kGreenSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: _kWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: _kGreen.withOpacity(0.4),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _kWhite, strokeWidth: 2.5))
                        : Text('Share with Community', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Widget> _previewImage(XFile file) async {
    final bytes = await file.readAsBytes();
    return Image.memory(bytes, fit: BoxFit.cover, width: 70, height: 70);
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: _kGreenSurface, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  const _CommentsSheet({required this.postId, required this.db, required this.auth});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _currentUserData() async {
    final user = widget.auth.currentUser;
    if (user == null) return {};
    final doc = await widget.db.collection('users').doc(user.uid).get();
    return {
      'uid': user.uid,
      'name': doc.data()?['fullName'] ?? user.displayName ?? 'Eco Member',
      'image': doc.data()?['profileImage'] ?? user.photoURL ?? '',
    };
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = widget.auth.currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      final userData = await _currentUserData();
      final postRef = widget.db.collection('communityPosts').doc(widget.postId);

      await postRef.collection('comments').add({
        'userId': userData['uid'],
        'userName': userData['name'],
        'userImage': userData['image'],
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'repliesCount': 0,
      });
      await postRef.update({'commentsCount': FieldValue.increment(1)});
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsStream = widget.db
        .collection('communityPosts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      minChildSize: 0.45,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                child: Row(
                  children: [
                    Text('Comments', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: _kGreenDark)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: commentsStream,
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _kGreen));
                    if (snap.data!.docs.isEmpty) {
                      return Center(child: Text('No comments yet', style: GoogleFonts.poppins(color: Colors.grey)));
                    }
                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: snap.data!.docs.length,
                      itemBuilder: (_, i) {
                        final doc = snap.data!.docs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return _CommentTile(postId: widget.postId, commentId: doc.id, data: data, db: widget.db, auth: widget.auth);
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(left: 14, right: 14, bottom: MediaQuery.of(context).viewInsets.bottom + 10, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            filled: true,
                            fillColor: _kGreenSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: _kGreen,
                        child: IconButton(
                          onPressed: _sending ? null : _addComment,
                          icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
}

class _CommentTile extends StatefulWidget {
  final String postId;
  final String commentId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  const _CommentTile({required this.postId, required this.commentId, required this.data, required this.db, required this.auth});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final TextEditingController _replyCtrl = TextEditingController();
  bool _showReplyBox = false;
  bool _showReplies = true;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _currentUserData() async {
    final user = widget.auth.currentUser;
    if (user == null) return {};
    final doc = await widget.db.collection('users').doc(user.uid).get();
    return {
      'uid': user.uid,
      'name': doc.data()?['fullName'] ?? user.displayName ?? 'Eco Member',
      'image': doc.data()?['profileImage'] ?? user.photoURL ?? '',
    };
  }

  Future<void> _addReply() async {
    final text = _replyCtrl.text.trim();
    final user = widget.auth.currentUser;
    if (text.isEmpty || user == null) return;

    final commentRef = widget.db
        .collection('communityPosts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId);

    final userData = await _currentUserData();

    await commentRef.collection('replies').add({
      'userId': userData['uid'],
      'userName': userData['name'],
      'userImage': userData['image'],
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await commentRef.update({'repliesCount': FieldValue.increment(1)});
    _replyCtrl.clear();
    setState(() {
      _showReplyBox = false;
      _showReplies = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.data['createdAt'];
    final timeStr = ts is Timestamp ? timeago.format(ts.toDate()) : 'Just now';
    final repliesStream = widget.db
        .collection('communityPosts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _smallAvatar(widget.data['userImage'] ?? ''),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _kGreenSurface, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.data['userName'] ?? 'Eco Member', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreenDark)),
                          const SizedBox(height: 3),
                          Text(widget.data['text'] ?? '', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(timeStr, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => setState(() => _showReplyBox = !_showReplyBox),
                          child: Text('Reply', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _kGreen)),
                        ),
                        const SizedBox(width: 12),
                        if ((widget.data['repliesCount'] ?? 0) > 0)
                          GestureDetector(
                            onTap: () => setState(() => _showReplies = !_showReplies),
                            child: Text('${widget.data['repliesCount']} replies', style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600)),
                          ),
                      ],
                    ),
                    if (_showReplyBox) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyCtrl,
                              decoration: InputDecoration(
                                hintText: 'Write reply...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              ),
                            ),
                          ),
                          IconButton(onPressed: _addReply, icon: const Icon(Icons.send_rounded, color: _kGreen)),
                        ],
                      ),
                    ],
                    if (_showReplies)
                      StreamBuilder<QuerySnapshot>(
                        stream: repliesStream,
                        builder: (context, snap) {
                          if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, left: 8),
                            child: Column(
                              children: snap.data!.docs.map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                final rts = d['createdAt'];
                                final rTime = rts is Timestamp ? timeago.format(rts.toDate()) : 'Just now';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _smallAvatar(d['userImage'] ?? '', size: 27),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(d['userName'] ?? 'Eco Member', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kGreenDark)),
                                              Text(d['text'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800)),
                                              const SizedBox(height: 2),
                                              Text(rTime, style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey.shade500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
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

  Widget _smallAvatar(String url, {double size = 34}) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: _kGreenSurface,
        child: url.isEmpty
            ? const Icon(Icons.person, color: _kGreen, size: 18)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.person, color: _kGreen, size: 18),
              ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final ValueChanged<String> onApply;

  const _FilterSheet({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Category', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...['All', 'Recycling', 'Sustainability', 'Green Living', 'Eco Tips'].map(
            (c) => ListTile(
              title: Text(c, style: GoogleFonts.poppins(fontSize: 13)),
              leading: const Icon(Icons.eco_outlined, color: _kGreen),
              onTap: () {
                onApply(c);
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
