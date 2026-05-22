// profile_screen.dart
// EcoSphere - Premium Eco Lifestyle App
// Single-file Flutter profile screen with Firebase integration

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────

class UserProfile {
  final String fullName;
  final String username;
  final String location;
  final String profileImageUrl;
  final String ecoLevel;
  final String badgeTitle;
  final double sustainabilityScore;
  final double improvementPercent;
  final double carbonFootprint;
  final double wasteReduced;
  final double wasteProgress;
  final int ecoPoints;
  final String rankText;

  const UserProfile({
    required this.fullName,
    required this.username,
    required this.location,
    required this.profileImageUrl,
    required this.ecoLevel,
    required this.badgeTitle,
    required this.sustainabilityScore,
    required this.improvementPercent,
    required this.carbonFootprint,
    required this.wasteReduced,
    required this.wasteProgress,
    required this.ecoPoints,
    required this.rankText,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        fullName: map['fullName'] ?? 'Eco User',
        username: map['username'] ?? '@ecosphere',
        location: map['location'] ?? 'Earth',
        profileImageUrl: map['profileImageUrl'] ?? '',
        ecoLevel: map['ecoLevel'] ?? 'Level 1',
        badgeTitle: map['badgeTitle'] ?? 'Eco Warrior',
        sustainabilityScore: (map['sustainabilityScore'] ?? 0).toDouble(),
        improvementPercent: (map['improvementPercent'] ?? 0).toDouble(),
        carbonFootprint: (map['carbonFootprint'] ?? 0).toDouble(),
        wasteReduced: (map['wasteReduced'] ?? 0).toDouble(),
        wasteProgress: (map['wasteProgress'] ?? 0.0).toDouble(),
        ecoPoints: (map['ecoPoints'] ?? 0).toInt(),
        rankText: map['rankText'] ?? 'Top 10%',
      );
}

class Challenge {
  final String title;
  final String subtitle;
  final String status;
  final String icon;

  const Challenge({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
  });

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        title: map['title'] ?? '',
        subtitle: map['subtitle'] ?? '',
        status: map['status'] ?? 'completed',
        icon: map['icon'] ?? '🌿',
      );
}

class Achievement {
  final String title;
  final String subtitle;
  final String image;

  const Achievement({
    required this.title,
    required this.subtitle,
    required this.image,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
        title: map['title'] ?? '',
        subtitle: map['subtitle'] ?? '',
        image: map['image'] ?? '',
      );
}

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────

class EcoTheme {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF43A047);
  static const Color primaryLighter = Color(0xFF66BB6A);
  static const Color accent = Color(0xFF00C853);
  static const Color accentSoft = Color(0xFFB9F6CA);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF1F8E9);
  static const Color textDark = Color(0xFF1B2E1C);
  static const Color textMedium = Color(0xFF4A6741);
  static const Color textLight = Color(0xFF7A9B78);
  static const Color cardShadow = Color(0x1A2E7D32);
  static const Color glassBg = Color(0xCCFFFFFF);

  static LinearGradient headerGradient = const LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient scoreGradient = const LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle poppins({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textDark,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

// ─────────────────────────────────────────────
//  MAIN PROFILE SCREEN
// ─────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  int _navIndex = 4;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _userStream =>
      FirebaseFirestore.instance.collection('users').doc(_uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _challengesStream =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('completedChallenges')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _achievementsStream =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('achievements')
          .snapshots();

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: EcoTheme.poppins(weight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: EcoTheme.poppins(color: EcoTheme.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: EcoTheme.poppins(color: EcoTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EcoTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: EcoTheme.poppins(
                    color: Colors.white, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
  }

  void _openEditProfile(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        profile: profile,
        uid: _uid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: EcoTheme.background,
        extendBody: true,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userStream,
          builder: (ctx, userSnap) {
            final profile = userSnap.hasData && userSnap.data!.exists
                ? UserProfile.fromMap(userSnap.data!.data()!)
                : null;

            return FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── HEADER ──
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      profile: profile,
                      onEditTap: profile != null
                          ? () => _openEditProfile(profile)
                          : null,
                    ),
                  ),

                  // ── MAIN CONTENT ──
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 0),
                      decoration: const BoxDecoration(
                        color: EcoTheme.background,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Sustainability Score
                          _SectionPadding(
                            child: _SustainabilityCard(profile: profile),
                          ),

                          const SizedBox(height: 16),

                          // Stats Row
                          _SectionPadding(
                            child: _StatsRow(profile: profile),
                          ),

                          const SizedBox(height: 20),

                          // Completed Challenges
                          _SectionPadding(
                            child: _SectionHeader(title: 'Completed Challenges'),
                          ),
                          const SizedBox(height: 12),
                          _ChallengesSection(stream: _challengesStream),

                          const SizedBox(height: 20),

                          // Achievements
                          _SectionPadding(
                            child: _SectionHeader(title: 'Achievements'),
                          ),
                          const SizedBox(height: 12),
                          _AchievementsSection(stream: _achievementsStream),

                          const SizedBox(height: 20),

                          // Points & Rank
                          if (profile != null)
                            _SectionPadding(
                              child: _PointsRankCard(profile: profile),
                            ),

                          const SizedBox(height: 20),

                          // Logout
                          _SectionPadding(
                            child: _LogoutButton(onTap: _logout),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _EcoBottomNav(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onEditTap;

  const _ProfileHeader({required this.profile, this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background image + gradient overlay
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(gradient: EcoTheme.headerGradient),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/profile_bg.jpg',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
                // Decorative circles
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: 40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EcoSphere',
                        style: EcoTheme.poppins(
                          size: 22,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.white, size: 22),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Avatar
                  _ProfileAvatar(imageUrl: profile?.profileImageUrl ?? ''),

                  const SizedBox(height: 10),

                  // Name
                  Text(
                    profile?.fullName ?? '—',
                    style: EcoTheme.poppins(
                      size: 20,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile?.username ?? '',
                    style: EcoTheme.poppins(
                      size: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        profile?.location ?? '',
                        style: EcoTheme.poppins(
                          size: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Badge row – overlapping the curve
        Positioned(
          bottom: -28,
          left: 20,
          right: 20,
          child: _BadgeRow(profile: profile, onEditTap: onEditTap),
        ),
      ],
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height + 20, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  const _ProfileAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _avatarPlaceholder(),
                errorWidget: (_, __, ___) => _avatarPlaceholder(),
              )
            : _avatarPlaceholder(),
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        color: EcoTheme.primaryLight,
        child: const Icon(Icons.person, color: Colors.white, size: 44),
      );
}

class _BadgeRow extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onEditTap;

  const _BadgeRow({required this.profile, this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: EcoTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge image
          Image.asset(
            'assets/images/badge_eco_warrior.png',
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EcoTheme.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, color: EcoTheme.primary, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.badgeTitle ?? 'Eco Warrior',
                  style: EcoTheme.poppins(
                    size: 13,
                    weight: FontWeight.w600,
                    color: EcoTheme.primary,
                  ),
                ),
                Text(
                  profile?.ecoLevel ?? 'Level 1',
                  style: EcoTheme.poppins(size: 11, color: EcoTheme.textLight),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: EcoTheme.scoreGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Edit Profile',
                style: EcoTheme.poppins(
                  size: 12,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUSTAINABILITY SCORE CARD
// ─────────────────────────────────────────────

class _SustainabilityCard extends StatelessWidget {
  final UserProfile? profile;
  const _SustainabilityCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final score = profile?.sustainabilityScore ?? 0;
    final improvement = profile?.improvementPercent ?? 0;
    final progress = (score / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EcoTheme.scoreGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: EcoTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sustainability Score',
                  style: EcoTheme.poppins(
                    size: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: EcoTheme.poppins(
                        size: 48,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        '/100',
                        style: EcoTheme.poppins(
                          size: 16,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${improvement.toStringAsFixed(1)}% this month',
                        style: EcoTheme.poppins(
                          size: 11,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CircularScoreIndicator(progress: progress, score: score),
        ],
      ),
    );
  }
}

class _CircularScoreIndicator extends StatelessWidget {
  final double progress;
  final double score;
  const _CircularScoreIndicator(
      {required this.progress, required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: EcoTheme.poppins(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                'Score',
                style: EcoTheme.poppins(
                  size: 10,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATS ROW
// ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserProfile? profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.cloud_outlined,
            iconColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            label: 'Carbon Footprint',
            value:
                '${profile?.carbonFootprint.toStringAsFixed(1) ?? "—"} kg',
            progress: ((profile?.carbonFootprint ?? 0) / 100).clamp(0.0, 1.0),
            progressColor: const Color(0xFF0288D1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.recycling,
            iconColor: EcoTheme.primary,
            bgColor: EcoTheme.accentSoft,
            label: 'Waste Reduced',
            value:
                '${profile?.wasteReduced.toStringAsFixed(1) ?? "—"} kg',
            progress: (profile?.wasteProgress ?? 0).clamp(0.0, 1.0),
            progressColor: EcoTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  final double progress;
  final Color progressColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: EcoTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: EcoTheme.poppins(
              size: 11,
              color: EcoTheme.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: EcoTheme.poppins(
              size: 18,
              weight: FontWeight.w700,
              color: EcoTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHALLENGES SECTION
// ─────────────────────────────────────────────

class _ChallengesSection extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  const _ChallengesSection({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: EcoTheme.primary, strokeWidth: 2),
            ),
          );
        }
        final challenges = snap.data!.docs
            .map((d) => Challenge.fromMap(d.data()))
            .toList();

        if (challenges.isEmpty) {
          return _EmptyState(message: 'No completed challenges yet.');
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: challenges.map((c) => _ChallengeItem(c)).toList(),
          ),
        );
      },
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeItem(this.challenge);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: EcoTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EcoTheme.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              challenge.icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: EcoTheme.poppins(
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                Text(
                  challenge.subtitle,
                  style: EcoTheme.poppins(
                    size: 11,
                    color: EcoTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EcoTheme.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: EcoTheme.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  challenge.status,
                  style: EcoTheme.poppins(
                    size: 10,
                    weight: FontWeight.w600,
                    color: EcoTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACHIEVEMENTS SECTION
// ─────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  const _AchievementsSection({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: EcoTheme.primary, strokeWidth: 2),
            ),
          );
        }
        final achievements = snap.data!.docs
            .map((d) => Achievement.fromMap(d.data()))
            .toList();

        if (achievements.isEmpty) {
          return _EmptyState(message: 'No achievements yet.');
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _AchievementItem(achievements[i]),
          ),
        );
      },
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final Achievement achievement;
  const _AchievementItem(this.achievement);

  static const Map<String, String> _assetMap = {
    'tree_planter': 'assets/images/tree_planter.png',
    'recycling_pro': 'assets/images/recycling_pro.png',
    'water_saver': 'assets/images/water_saver.png',
    'energy_saver': 'assets/images/energy_saver.png',
    'eco_leader': 'assets/images/eco_leader.png',
  };

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetMap[achievement.image] ?? '';

    return Container(
      width: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: EcoTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          assetPath.isNotEmpty
              ? Image.asset(
                  assetPath,
                  width: 44,
                  height: 44,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events,
                    color: EcoTheme.primaryLight,
                    size: 36,
                  ),
                )
              : const Icon(Icons.emoji_events,
                  color: EcoTheme.primaryLight, size: 36),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            style: EcoTheme.poppins(
              size: 9,
              weight: FontWeight.w600,
              color: EcoTheme.textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  POINTS & RANK CARD
// ─────────────────────────────────────────────

class _PointsRankCard extends StatelessWidget {
  final UserProfile profile;
  const _PointsRankCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: EcoTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PointItem(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFA726),
              iconBg: const Color(0xFFFFF3E0),
              label: 'Eco Points',
              value: '${profile.ecoPoints}',
            ),
          ),
          Container(
              width: 1, height: 50, color: EcoTheme.background),
          Expanded(
            child: _PointItem(
              icon: Icons.leaderboard_rounded,
              iconColor: EcoTheme.primary,
              iconBg: EcoTheme.accentSoft,
              label: 'Ranking',
              value: profile.rankText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _PointItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: EcoTheme.poppins(
            size: 18,
            weight: FontWeight.w700,
            color: EcoTheme.textDark,
          ),
        ),
        Text(
          label,
          style: EcoTheme.poppins(size: 11, color: EcoTheme.textLight),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: EcoTheme.poppins(
                size: 14,
                weight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAVIGATION
// ─────────────────────────────────────────────

class _EcoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _EcoBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
              icon: Icons.home_outlined,
              filledIcon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              current: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.explore_outlined,
              filledIcon: Icons.explore_rounded,
              label: 'Explore',
              index: 1,
              current: currentIndex,
              onTap: onTap),
          // Center Plus button
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: EcoTheme.scoreGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: EcoTheme.primary.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          _NavItem(
              icon: Icons.people_outline_rounded,
              filledIcon: Icons.people_rounded,
              label: 'Community',
              index: 3,
              current: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.person_outline_rounded,
              filledIcon: Icons.person_rounded,
              label: 'Profile',
              index: 4,
              current: currentIndex,
              onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData filledIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? filledIcon : icon,
                key: ValueKey(active),
                color: active ? EcoTheme.primary : EcoTheme.textLight,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: EcoTheme.poppins(
                size: 10,
                weight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? EcoTheme.primary : EcoTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────

class _SectionPadding extends StatelessWidget {
  final Widget child;
  const _SectionPadding({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: EcoTheme.scoreGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: EcoTheme.poppins(
              size: 16,
              weight: FontWeight.w700,
              color: EcoTheme.textDark,
            ),
          ),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: EcoTheme.poppins(size: 13, color: EcoTheme.textLight),
        ),
      );
}

// ─────────────────────────────────────────────
//  EDIT PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  final String uid;

  const _EditProfileSheet({required this.profile, required this.uid});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _locationCtrl;

  File? _pickedImage;
  bool _isSaving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.fullName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _locationCtrl = TextEditingController(text: widget.profile.location);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null) {
      setState(() => _pickedImage = File(xFile.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref('profile_images/${widget.uid}.jpg');
      await ref.putFile(_pickedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String? imageUrl = await _uploadImage();
      final data = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        if (imageUrl != null) 'profileImageUrl': imageUrl,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e',
                style: EcoTheme.poppins(color: Colors.white, size: 13)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Edit Profile',
              style: EcoTheme.poppins(
                size: 20,
                weight: FontWeight.w700,
                color: EcoTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: EcoTheme.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: _pickedImage != null
                            ? Image.file(_pickedImage!, fit: BoxFit.cover)
                            : (widget.profile.profileImageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.profile.profileImageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _avatarFallback(),
                                  )
                                : _avatarFallback()),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: EcoTheme.scoreGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _InputField(
              controller: _nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            _InputField(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 14),
            _InputField(
              controller: _locationCtrl,
              label: 'Location',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: EcoTheme.scoreGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: EcoTheme.poppins(
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: EcoTheme.primaryLight,
        child: const Icon(Icons.person, color: Colors.white, size: 44),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoTheme.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: EcoTheme.poppins(size: 14, color: EcoTheme.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              EcoTheme.poppins(size: 13, color: EcoTheme.textLight),
          prefixIcon: Icon(icon, color: EcoTheme.textLight, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: EcoTheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: EcoTheme.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}