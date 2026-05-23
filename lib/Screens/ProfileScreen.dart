import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  CLOUDINARY CONFIG
//  Cloudinary Dashboard se apna cloud name aur unsigned upload preset yahan lagao.
// ─────────────────────────────────────────────
const String kCloudinaryCloudName = 'dsufgen5z';
const String kCloudinaryUploadPreset = 'ecoaphere';
const String kCloudinaryFolder = 'eco_profile_images';

// ─────────────────────────────────────────────
//  ECO PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        return _EcoProfileView(uid: uid, data: data);
      },
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN VIEW
// ─────────────────────────────────────────────
class _EcoProfileView extends StatelessWidget {
  const _EcoProfileView({required this.uid, required this.data});

  final String uid;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _HeaderSection(uid: uid, data: data),
              const SizedBox(height: 20),

              // ── Sustainability Score ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SustainabilityCard(data: data),
              ),
              const SizedBox(height: 20),

              // ── Impact ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ImpactSection(data: data),
              ),
              const SizedBox(height: 20),

              // ── Waste Reduction Progress ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _WasteReductionCard(data: data),
              ),
              const SizedBox(height: 20),

              // ── Challenges ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ChallengesSection(uid: uid),
              ),
              const SizedBox(height: 20),

              // ── Achievements ──
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _AchievementsSection(uid: uid),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HEADER SECTION
// ─────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.uid, required this.data});

  final String uid;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final profileImage = data['profileImage'] as String?;
    final fullName = data['fullName'] as String? ?? 'Eco User';
    final email = data['email'] as String? ?? '';
    final ecoTitle = data['ecoTitle'] as String? ?? 'Eco Warrior';

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ClipRRect(
              child: Image.asset(
                'assets/images/profile_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D6A4F), Color(0xFF52B788), Color(0xFF95D5B2)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Frosted overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(color: Colors.black.withOpacity(0.08)),
            ),
          ),

          // Decorative leaf circles
          Positioned(top: -30, right: -30, child: _LeafCircle(size: 120, opacity: 0.15)),
          Positioned(bottom: -20, left: -20, child: _LeafCircle(size: 90, opacity: 0.12)),

          // Back button
          Positioned(
            top: 12,
            left: 12,
            child: _GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),

          // Settings button
          Positioned(
            top: 12,
            right: 12,
            child: _GlassButton(
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
          ),

          // Profile content
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
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
                        child: profileImage != null && profileImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profileImage,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const _AvatarPlaceholder(),
                                errorWidget: (_, __, ___) => const _AvatarPlaceholder(),
                              )
                            : const _AvatarPlaceholder(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF40916C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  fullName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 2),

                // Email + Edit Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _openEditProfile(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Edit Profile',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Eco Warrior badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF40916C).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        ecoTitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

  void _openEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(uid: uid, data: data),
    );
  }
}

// ─────────────────────────────────────────────
//  GLASS BUTTON
// ─────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LEAF CIRCLE DECOR
// ─────────────────────────────────────────────
class _LeafCircle extends StatelessWidget {
  const _LeafCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(opacity), width: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AVATAR PLACEHOLDER
// ─────────────────────────────────────────────
class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF74C69D),
      child: Image.asset(
        'assets/images/default_profile.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUSTAINABILITY CARD
// ─────────────────────────────────────────────
class _SustainabilityCard extends StatelessWidget {
  const _SustainabilityCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final score = (data['sustainabilityScore'] as num?)?.toInt() ?? 2450;
    final progress = (data['scoreProgress'] as num?)?.toDouble() ?? 0.85;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D6A4F), Color(0xFF40916C), Color(0xFF52B788)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40916C).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/profile_bg.jpg'),
          fit: BoxFit.cover,
          opacity: 0.08,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: 90,
            top: -20,
            child: _LeafCircle(size: 80, opacity: 0.1),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sustainability Score',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline, color: Colors.white.withOpacity(0.7), size: 14),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${score.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.trending_up, color: Color(0xFF95D5B2), size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You're in the top 15%\nKeep up the great work!",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Circular indicator
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/leaf_icon.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.eco, color: Colors.white, size: 28),
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
}

// ─────────────────────────────────────────────
//  IMPACT SECTION
// ─────────────────────────────────────────────
class _ImpactSection extends StatelessWidget {
  const _ImpactSection({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final carbon = (data['carbonFootprint'] as num?)?.toDouble() ?? 24.6;
    final waste = (data['wasteReduced'] as num?)?.toDouble() ?? 18.2;
    final water = (data['waterSaved'] as num?)?.toDouble() ?? 1250.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Impact',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ImpactCard(
                iconAsset: 'assets/images/co2_icon.png',
                iconFallback: Icons.cloud_outlined,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2D6A4F),
                label: 'Carbon Footprint',
                value: '${carbon}kg',
                change: '18% vs last month',
                isPositive: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ImpactCard(
                iconAsset: 'assets/images/recycle_icon.png',
                iconFallback: Icons.recycling,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2D6A4F),
                label: 'Waste Reduced',
                value: '${waste}kg',
                change: '15% vs last month',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ImpactCard(
                iconAsset: 'assets/images/water_icon.png',
                iconFallback: Icons.water_drop_outlined,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                label: 'Water Saved',
                value: '${water.toInt()}L',
                change: '22% vs last month',
                isPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.iconAsset,
    required this.iconFallback,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  final String iconAsset;
  final IconData iconFallback;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String change;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                iconAsset,
                errorBuilder: (_, __, ___) => Icon(iconFallback, color: iconColor, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPositive ? const Color(0xFF2D6A4F) : Colors.red,
                size: 10,
              ),
              Expanded(
                child: Text(
                  change,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: isPositive ? const Color(0xFF2D6A4F) : Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
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
//  WASTE REDUCTION CARD
// ─────────────────────────────────────────────
class _WasteReductionCard extends StatelessWidget {
  const _WasteReductionCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final progress = (data['wasteProgress'] as num?)?.toDouble() ?? 0.75;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Waste Reduction Progress',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B4332),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF40916C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF40916C), size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFFE8F5E9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF40916C)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D6A4F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great Progress!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                    Text(
                      "You're making a real difference.",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress track
          _MilestoneTrack(progress: progress),
        ],
      ),
    );
  }
}

class _MilestoneTrack extends StatelessWidget {
  const _MilestoneTrack({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final milestones = [
      ('25%', 'Starter', 0.25),
      ('50%', 'Champion', 0.50),
      ('75%', 'Hero', 0.75),
      ('100%', 'Eco Legend', 1.0),
    ];

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 6,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: const Color(0xFF40916C),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Dot markers
                ...milestones.map((m) {
                  final frac = m.$3;
                  final reached = progress >= frac;
                  return Positioned(
                    left: constraints.maxWidth * frac - 7,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: reached ? const Color(0xFF40916C) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: reached ? const Color(0xFF40916C) : const Color(0xFFB7E4C7),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: milestones.map((m) {
            final reached = progress >= m.$3;
            return Text(
              m.$2,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: reached ? FontWeight.w700 : FontWeight.w400,
                color: reached ? const Color(0xFF2D6A4F) : const Color(0xFFAAAAAA),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  CHALLENGES SECTION
// ─────────────────────────────────────────────
class _ChallengesSection extends StatelessWidget {
  const _ChallengesSection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('challenges')
          .snapshots(),
      builder: (context, snapshot) {
        final challenges = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completed Challenges',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B4332),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF40916C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF40916C), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (challenges.isEmpty)
                _defaultChallenges()
              else
                ...challenges.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _ChallengeItem(
                    title: d['title'] ?? '',
                    subtitle: d['subtitle'] ?? '',
                    status: d['status'] ?? 'active',
                    progress: (d['progress'] as num?)?.toDouble() ?? 0.0,
                    icon: Icons.eco,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _defaultChallenges() {
    return Column(
      children: const [
        _ChallengeItem(
          title: 'Plastic Free July',
          subtitle: 'Avoid single-use plastics',
          status: 'completed',
          progress: 1.0,
          icon: Icons.shopping_bag_outlined,
        ),
        _ChallengeItem(
          title: 'Waste Less Challenge',
          subtitle: 'Reduce household waste',
          status: 'completed',
          progress: 1.0,
          icon: Icons.delete_outline,
        ),
        _ChallengeItem(
          title: 'Plant 5 Trees',
          subtitle: 'Make our planet greener',
          status: 'active',
          progress: 0.8,
          icon: Icons.park_outlined,
        ),
      ],
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  const _ChallengeItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.progress,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String status;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF40916C), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF888888)),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Row(
              children: [
                Text(
                  'Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF40916C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF40916C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ],
            )
          else
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: const Color(0xFFE8F5E9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF40916C)),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    '${(progress * 5).toInt()}/5',
                    style: GoogleFonts.poppins(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D6A4F),
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
  const _AchievementsSection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final achievements = docs.isNotEmpty
            ? docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return _AchievementData(
                  title: d['title'] ?? '',
                  image: d['image'] ?? '',
                  unlocked: d['unlocked'] as bool? ?? false,
                );
              }).toList()
            : _defaultAchievements;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B4332),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF40916C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF40916C), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _AchievementBadge(achievement: achievements[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_AchievementData> get _defaultAchievements => [
        _AchievementData(title: 'Eco Starter', image: 'assets/images/leaf_icon.png', unlocked: true),
        _AchievementData(title: 'Tree Planter', image: 'assets/images/tree_badge.png', unlocked: true),
        _AchievementData(title: 'Waste Reducer', image: 'assets/images/recycle_badge.png', unlocked: true),
        _AchievementData(title: 'Water Saver', image: 'assets/images/water_badge.png', unlocked: true),
        _AchievementData(title: 'Climate Hero', image: 'assets/images/climate_badge.png', unlocked: false),
      ];
}

class _AchievementData {
  const _AchievementData({required this.title, required this.image, required this.unlocked});

  final String title;
  final String image;
  final bool unlocked;
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});

  final _AchievementData achievement;

  @override
  Widget build(BuildContext context) {
    final isUrl = achievement.image.startsWith('http');

    return Opacity(
      opacity: achievement.unlocked ? 1.0 : 0.4,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFB7E4C7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF40916C).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isUrl
                  ? CachedNetworkImage(
                      imageUrl: achievement.image,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.eco, color: Color(0xFF40916C), size: 28),
                    )
                  : Image.asset(
                      achievement.image,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.eco, color: Color(0xFF40916C), size: 28),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B4332),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EDIT PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.uid, required this.data});

  final String uid;
  final Map<String, dynamic> data;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bioCtrl;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['fullName'] ?? '');
    _emailCtrl = TextEditingController(text: widget.data['email'] ?? '');
    _titleCtrl = TextEditingController(text: widget.data['ecoTitle'] ?? 'Eco Warrior');
    _bioCtrl = TextEditingController(text: widget.data['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<String> _uploadImageToCloudinary(XFile image) async {
    if (kCloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
        kCloudinaryUploadPreset == 'YOUR_UNSIGNED_UPLOAD_PRESET') {
      throw Exception('Cloudinary cloud name aur unsigned upload preset set karo.');
    }

    final bytes = await image.readAsBytes();

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = kCloudinaryUploadPreset
      ..fields['folder'] = kCloudinaryFolder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name.isNotEmpty ? image.name : 'profile_${widget.uid}.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary ne image URL return nahi kiya.');
    }

    return secureUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? imageUrl;

      if (_pickedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_pickedImage!);
      }

      final updates = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'ecoTitle': _titleCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      };
      if (imageUrl != null) updates['profileImage'] = imageUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(updates, SetOptions(merge: true));

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9FFF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, size: 18, color: Color(0xFF40916C)),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF40916C), width: 2.5),
                                ),
                                child: ClipOval(
                                  child: _pickedImageBytes != null
                                      ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                                      : (widget.data['profileImage'] != null &&
                                              widget.data['profileImage'].toString().isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: widget.data['profileImage'],
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => const _AvatarPlaceholder(),
                                              errorWidget: (_, __, ___) => const _AvatarPlaceholder(),
                                            )
                                          : const _AvatarPlaceholder()),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF40916C),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _EcoTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        _EcoTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v?.contains('@') ?? false) ? null : 'Invalid email',
                        ),
                        const SizedBox(height: 14),

                        _EcoTextField(
                          controller: _titleCtrl,
                          label: 'Eco Title',
                          icon: Icons.eco_outlined,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        _EcoTextField(
                          controller: _bioCtrl,
                          label: 'Bio / Location',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 28),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D6A4F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
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
                                    'Save Changes',
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
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  ECO TEXT FIELD
// ─────────────────────────────────────────────
class _EcoTextField extends StatelessWidget {
  const _EcoTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1B4332)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF888888), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF40916C), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF40916C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}