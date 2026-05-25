import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/Screens/ProductScreen.dart';




class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String bgImage = 'assets/images/home_bg.jpg';

  static const String defaultProfile =
      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

  static const List<_ExploreItem> exploreItems = [
    _ExploreItem(
      'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=600&q=80',
      'Eco Products',
      '120+ Items',
    ),
    _ExploreItem(
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80',
      'Sustainable\nRecipes',
      '80+ Recipes',
    ),
    _ExploreItem(
      'https://images.unsplash.com/photo-1527525443983-6e60c75fff46?auto=format&fit=crop&w=600&q=80',
      'Green\nChallenges',
      '12 Active',
    ),
    _ExploreItem(
      'https://images.unsplash.com/photo-1491438590914-bc09fcaaf77a?auto=format&fit=crop&w=600&q=80',
      'Community\nForum',
      '4.8K Members',
    ),
  ];

  Stream<DocumentSnapshot<Map<String, dynamic>>>? get _userStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _toInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final stream = _userStream;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final userName = data['fullName'] ?? data['name'] ?? 'User';
          final photoUrl =
              data['profileImage'] ?? data['profileImageUrl'] ?? data['photoURL'];

          final carbonFootprint = _toDouble(data['carbonFootprint'], 2.45);
          final carbonProgress = _toDouble(data['carbonProgress'], 0.72);
          final carbonChange = _toInt(data['carbonChange'], 18);

          final wasteDiverted = _toDouble(data['wasteDiverted'], 0.68);
          final wasteProgress = _toDouble(data['wasteProgress'], 0.45);
          final wasteChange = _toInt(data['wasteChange'], 12);

          final dailyGoalProgress = _toDouble(data['dailyGoalProgress'], 0.75);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _headerUI(userName: userName, photoUrl: photoUrl),
                _buildMainCard(
                  context: context,
                  carbonFootprint: carbonFootprint,
                  carbonProgress: carbonProgress,
                  carbonChange: carbonChange,
                  wasteDiverted: wasteDiverted,
                  wasteProgress: wasteProgress,
                  wasteChange: wasteChange,
                  dailyGoalProgress: dailyGoalProgress,
                ),
                const SizedBox(height: 115),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerUI({required String userName, required String? photoUrl}) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bgImage, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0B3D1E).withOpacity(0.78),
                  const Color(0xFF2E7D32).withOpacity(0.45),
                  const Color(0xFF66BB6A).withOpacity(0.18),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(photoUrl: photoUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greetingText(),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userName,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text('🌿'),
                              ],
                            ),
                            Text(
                              'Small steps, big impact.',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        _miniStat('🌱', 'Eco Score', '840'),
                        _divider(),
                        _miniStat('⭐', 'Points', '1.2K'),
                        _divider(),
                        _miniStat('🔥', 'Streak', '12 Days'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard({
    required BuildContext context,
    required double carbonFootprint,
    required double carbonProgress,
    required int carbonChange,
    required double wasteDiverted,
    required double wasteProgress,
    required int wasteChange,
    required double dailyGoalProgress,
  }) {
    return Transform.translate(
      offset: const Offset(0, -95),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5FAF5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          child: Column(
            children: [
              _buildImpactSection(
                carbonFootprint: carbonFootprint,
                carbonProgress: carbonProgress,
                carbonChange: carbonChange,
                wasteDiverted: wasteDiverted,
                wasteProgress: wasteProgress,
                wasteChange: wasteChange,
              ),
              const SizedBox(height: 18),
              _buildDailyGoalSection(dailyGoalProgress),
              const SizedBox(height: 20),
              _buildExploreSection(context),
              const SizedBox(height: 18),
              _buildEcoTipCard(),
              const SizedBox(height: 18),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Explore',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF43A047),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF43A047),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: exploreItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _buildExploreCard(context, exploreItems[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExploreCard(
    BuildContext context,
    _ExploreItem item,
    int index,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductScreen()),
          );
        }
      },
      child: Container(
        width: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(color: const Color(0xFF2E7D32));
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.68)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.25),
    );
  }

  Widget _miniStat(String emoji, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.75),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title) {
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactSection({
    required double carbonFootprint,
    required double carbonProgress,
    required int carbonChange,
    required double wasteDiverted,
    required double wasteProgress,
    required int wasteChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('🌿', 'Your Impact Today'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: '🏭',
                label: 'Carbon Footprint',
                value: '${carbonFootprint.toStringAsFixed(2)} kg',
                unit: 'CO₂ today',
                progress: carbonProgress.clamp(0.0, 1.0),
                change: '↓ $carbonChange% vs yesterday',
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: '♻️',
                label: 'Waste Diverted',
                value: '${wasteDiverted.toStringAsFixed(2)} kg',
                unit: 'From landfill',
                progress: wasteProgress.clamp(0.0, 1.0),
                change: '↑ $wasteChange% vs yesterday',
                color: const Color(0xFF00897B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required String label,
    required String value,
    required String unit,
    required double progress,
    required String change,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20))),
                    Text(unit,
                        style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500])),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(
                  painter: CircularProgressPainter(
                    progress: progress,
                    color: color,
                    backgroundColor: color.withOpacity(0.12),
                    icon: icon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(change,
              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _buildDailyGoalSection(double progress) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon('🎯'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily Goal Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGoalItem('🌿', 'Low Carbon', true),
              _buildGoalItem('🛍️', 'No Plastic', true),
              _buildGoalItem('💧', 'Save Water', true),
              _buildGoalItem('⚡', 'Energy', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionIcon(String emoji) {
    return Container(
      width: 27,
      height: 27,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 13))),
    );
  }

  Widget _buildGoalItem(String emoji, String label, bool completed) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: completed ? const Color(0xFF2E7D32) : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "🌱 Use a reusable water bottle.\nSmall choice, big change.",
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          color: Colors.white,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Text(
        '🌳 You planted a tree\n2 hours ago',
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1B5E20),
          height: 1.4,
        ),
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2E7D32).withOpacity(0.08),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;

  const _ProfileAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: ClipOval(
        child: Image.network(
          hasPhoto ? photoUrl! : HomeScreen.defaultProfile,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFE8F5E9),
              child: const Icon(Icons.person, color: Color(0xFF2E7D32)),
            );
          },
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final String icon;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(fontSize: size.width * 0.38),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ExploreItem {
  final String imageUrl;
  final String title;
  final String subtitle;

  const _ExploreItem(this.imageUrl, this.title, this.subtitle);
}