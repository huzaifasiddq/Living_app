import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/Admin/ManageChallengesScreen.dart';
import 'package:my_app/Admin/ManageProductsScreen.dart';
import 'package:my_app/Admin/ManageRecipesScreen.dart';

// TODO: Jab ye pages bana lo to in imports ko uncomment kar dena.
// import 'package:my_app/Screens/Admin/ManageProductsScreen.dart';
// import 'package:my_app/Screens/Admin/ManageRecipesScreen.dart';
// import 'package:my_app/Screens/Admin/ManageChallengesScreen.dart';
// import 'package:my_app/Screens/Admin/ManageEducationalContentScreen.dart';
// import 'package:my_app/Screens/Admin/ManageCommunityPostsScreen.dart';
// import 'package:my_app/Screens/Admin/ReportsAnalyticsScreen.dart';
// import 'package:my_app/Screens/Admin/EcoTipsManagerScreen.dart';
// import 'package:my_app/Screens/Admin/FeedbackQueriesScreen.dart';
// import 'package:my_app/Screens/Admin/AdminProfileScreen.dart';

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EcoSphereApp());
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
class EcoSphereApp extends StatelessWidget {
  const EcoSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSphere Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1F0F),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AdminDashboardScreen(),
      routes: {
        AdminRoutes.users: (_) => const ManageUsersScreen(),
        AdminRoutes.products: (_) => const ManageProductsScreen(),
        AdminRoutes.recipes: (_) => const ManageRecipesScreen(),
        AdminRoutes.challenges: (_) => const ManageChallengesScreen(),
        AdminRoutes.content: (_) => const PlaceholderScreen(title: 'Content Manager'),
        AdminRoutes.community: (_) => const PlaceholderScreen(title: 'Community Posts'),
        AdminRoutes.reports: (_) => const PlaceholderScreen(title: 'Reports & Analytics'),
        AdminRoutes.ecoTips: (_) => const PlaceholderScreen(title: 'Eco Tips Manager'),
        AdminRoutes.feedback: (_) => const PlaceholderScreen(title: 'Feedback & Queries'),
        AdminRoutes.profile: (_) => const PlaceholderScreen(title: 'Admin Profile'),
      },
    );
  }
}

// ─────────────────────────────────────────────
// COLOUR PALETTE
// ─────────────────────────────────────────────
class EcoColors {
  static const bg = Color(0xFF0A1A0C);
  static const card = Color(0xFF132316);
  static const cardBorder = Color(0xFF1E3D22);
  static const primary = Color(0xFF2E7D32);
  static const accent = Color(0xFF4CAF50);
  static const accentLight = Color(0xFF81C784);
  static const iconBg = Color(0xFF1B3A1E);
  static const textPrimary = Color(0xFFE8F5E9);
  static const textSecondary = Color(0xFF9CCC65);
  static const chartLine = Color(0xFF66BB6A);
  static const positive = Color(0xFF4CAF50);
  static const neutral = Color(0xFFFFC107);
  static const negative = Color(0xFFF44336);
  static const glassWhite = Color(0x14FFFFFF);
  static const glassBorder = Color(0x22FFFFFF);
}

// ─────────────────────────────────────────────
// ADMIN ROUTES
// ─────────────────────────────────────────────
class AdminRoutes {
  static const users = '/user-management';
  static const products = '/product-management';
  static const recipes = '/recipe-management';
  static const challenges = '/challenge-management';
  static const content = '/content-manager';
  static const community = '/community-posts';
  static const reports = '/reports-analytics';
  static const ecoTips = '/eco-tips-manager';
  static const feedback = '/feedback-queries';
  static const profile = '/admin-profile';
}

// ─────────────────────────────────────────────
// FIRESTORE SERVICE
// ─────────────────────────────────────────────
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Stream<DocumentSnapshot> statsStream() =>
      _db.collection('adminDashboard').doc('stats').snapshots();

  static Stream<QuerySnapshot> activeUsersStream() => _db
      .collection('adminDashboard')
      .doc('activeUsersChart')
      .collection('points')
      .orderBy('day')
      .snapshots();

  static Stream<QuerySnapshot> managementCardsStream() => _db
      .collection('adminDashboard')
      .doc('managementCards')
      .collection('cards')
      .orderBy('order')
      .snapshots();

  static Stream<QuerySnapshot> recentActivityStream() => _db
      .collection('adminDashboard')
      .doc('recentActivity')
      .collection('items')
      .orderBy('time', descending: true)
      .limit(5)
      .snapshots();

  static Stream<DocumentSnapshot> feedbackStream() =>
      _db.collection('adminDashboard').doc('feedbackOverview').snapshots();
}

// ─────────────────────────────────────────────
// MAIN DASHBOARD SCREEN
// ─────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String _selectedMonth = 'This Month';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: EcoColors.bg,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Background image with blur
          _buildBackground(),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0A1A0C),
                  Color(0xEE0D1F0F),
                  Color(0xFF0A1A0C),
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildAnalyticsOverview(),
                    const SizedBox(height: 20),
                    _buildManagementSection(),
                    const SizedBox(height: 20),
                    _buildBottomRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BACKGROUND ──
  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Image.asset(
            'assets/images/admin_bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2B10), Color(0xFF071208)],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  // ── DRAWER ──
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F2212),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _profileAvatar(radius: 40),
            const SizedBox(height: 12),
            Text('Admin',
                style: GoogleFonts.poppins(
                    color: EcoColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            Text('Super Admin',
                style: GoogleFonts.poppins(
                    color: EcoColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            const Divider(color: EcoColors.cardBorder),
            _drawerItem(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
            _drawerItem(Icons.people_rounded, 'User Management',
                () => _goTo(AdminRoutes.users)),
            _drawerItem(Icons.inventory_2_rounded, 'Product Management',
                () => _goTo(AdminRoutes.products)),
            _drawerItem(Icons.restaurant_menu_rounded, 'Recipe Management',
                () => _goTo(AdminRoutes.recipes)),
            _drawerItem(Icons.emoji_events_rounded, 'Challenge Management',
                () => _goTo(AdminRoutes.challenges)),
            _drawerItem(Icons.article_rounded, 'Content Manager',
                () => _goTo(AdminRoutes.content)),
            _drawerItem(Icons.forum_rounded, 'Community Posts',
                () => _goTo(AdminRoutes.community)),
            _drawerItem(Icons.bar_chart_rounded, 'Reports & Analytics',
                () => _goTo(AdminRoutes.reports)),
            _drawerItem(Icons.eco_rounded, 'Eco Tips Manager',
                () => _goTo(AdminRoutes.ecoTips)),
            _drawerItem(Icons.feedback_rounded, 'Feedback & Queries',
                () => _goTo(AdminRoutes.feedback)),
            _drawerItem(Icons.person_rounded, 'Admin Profile',
                () => _goTo(AdminRoutes.profile)),
            const Spacer(),
            _drawerItem(Icons.logout_rounded, 'Sign Out', () async {
              await FirebaseAuth.instance.signOut();
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: EcoColors.accentLight, size: 20),
      title: Text(label,
          style: GoogleFonts.poppins(
              color: EcoColors.textPrimary, fontSize: 13)),
      onTap: onTap,
    );
  }

  void _goTo(String routeName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu icon
          _glassIconBtn(
            Icons.menu_rounded,
            () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 12),
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.poppins(
                      color: EcoColors.textSecondary, fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      'Admin',
                      style: GoogleFonts.poppins(
                        color: EcoColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: EcoColors.accent, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's what's happening with EcoSphere today.",
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF7B9E7D), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification + Profile
          Column(
            children: [
              _glassIconBtn(Icons.notifications_outlined, () {}),
              const SizedBox(height: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _profileAvatar(radius: 22),
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [EcoColors.primary, EcoColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Super Admin',
                          style: GoogleFonts.poppins(
                              fontSize: 6,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EcoColors.glassWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EcoColors.glassBorder),
            ),
            child: Icon(icon, color: EcoColors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _profileAvatar({double radius = 22}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: EcoColors.iconBg,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl:
              'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/admin_profile.jpg?alt=media',
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorWidget: (_, __, ___) => Icon(
            Icons.person_rounded,
            color: EcoColors.accentLight,
            size: radius,
          ),
          placeholder: (_, __) => const CircularProgressIndicator(
            strokeWidth: 2,
            color: EcoColors.accent,
          ),
        ),
      ),
    );
  }

  // ── ANALYTICS OVERVIEW ──
  Widget _buildAnalyticsOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Month picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Analytics Overview',
                    style: GoogleFonts.poppins(
                        color: EcoColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                _monthDropdown(),
              ],
            ),
            const SizedBox(height: 14),
            // Stat cards
            StreamBuilder<DocumentSnapshot>(
              stream: FirestoreService.statsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LoadingWidget();
                }
                if (snap.hasError) return const _ErrorWidget();
                if (!snap.hasData || !snap.data!.exists) {
                  return const _EmptyWidget(message: 'No stats available');
                }
                final data = snap.data!.data() as Map<String, dynamic>;
                return _buildStatCards(data);
              },
            ),
            const SizedBox(height: 16),
            // Active users chart
            _buildActiveUsersChart(),
          ],
        ),
      ),
    );
  }

  Widget _monthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: EcoColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          dropdownColor: const Color(0xFF132316),
          style: GoogleFonts.poppins(
              color: EcoColors.textPrimary, fontSize: 11),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: EcoColors.accentLight, size: 16),
          isDense: true,
          items: ['This Month', 'Last Month', 'Last 3 Months', 'This Year']
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> data) {
    final cards = [
      {
        'label': 'Total Users',
        'value': _fmt(data['totalUsers']),
        'growth': _fmtDouble(data['totalUsersGrowth']),
        'icon': Icons.people_rounded,
      },
      {
        'label': 'Eco Products',
        'value': _fmt(data['ecoProducts']),
        'growth': _fmtDouble(data['ecoProductsGrowth']),
        'icon': Icons.eco_rounded,
      },
      {
        'label': 'Recipes',
        'value': _fmt(data['recipes']),
        'growth': _fmtDouble(data['recipesGrowth']),
        'icon': Icons.restaurant_menu_rounded,
      },
      {
        'label': 'Challenges',
        'value': _fmt(data['challenges']),
        'growth': _fmtDouble(data['challengesGrowth']),
        'icon': Icons.emoji_events_rounded,
      },
    ];

    return Row(
      children: cards
          .map((c) => Expanded(child: _statCard(c)))
          .toList(),
    );
  }

  Widget _statCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: EcoColors.glassWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EcoColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: EcoColors.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(c['icon'] as IconData,
                color: EcoColors.accent, size: 14),
          ),
          const SizedBox(height: 6),
          Text(c['value'] as String,
              style: GoogleFonts.poppins(
                  color: EcoColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(c['label'] as String,
              style: GoogleFonts.poppins(
                  color: EcoColors.textSecondary,
                  fontSize: 8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded,
                  color: EcoColors.accent, size: 10),
              const SizedBox(width: 2),
              Text('${c['growth']}%',
                  style: GoogleFonts.poppins(
                      color: EcoColors.accent, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.activeUsersStream(),
      builder: (ctx, snap) {
        List<FlSpot> spots = _fallbackSpots();
        double maxY = 15000;
        String currentVal = '8.6K';
        String growth = '+21.4%';

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          spots = snap.data!.docs.asMap().entries.map((e) {
            final d = e.value.data() as Map<String, dynamic>;
            return FlSpot(
              e.key.toDouble(),
              (d['value'] as num).toDouble(),
            );
          }).toList();
          final vals = spots.map((s) => s.y).toList();
          maxY = vals.reduce((a, b) => a > b ? a : b) * 1.2;
          currentVal = _fmt(snap.data!.docs.last['value']);
          // growth from Firestore if available
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Users',
                        style: GoogleFonts.poppins(
                            color: EcoColors.textSecondary, fontSize: 11)),
                    Row(
                      children: [
                        Text(currentVal,
                            style: GoogleFonts.poppins(
                                color: EcoColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 22)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EcoColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(growth,
                              style: GoogleFonts.poppins(
                                  color: EcoColors.accent, fontSize: 10)),
                        ),
                      ],
                    ),
                    Text('vs last month',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF5C7A5E), fontSize: 9)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxY / 3,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: EcoColors.glassBorder,
                      strokeWidth: 0.5,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: maxY / 3,
                        getTitlesWidget: (v, _) => Text(
                          _shortNum(v),
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF5C7A5E), fontSize: 8),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF5C7A5E), fontSize: 8),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: EcoColors.chartLine,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: EcoColors.chartLine,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            EcoColors.chartLine.withOpacity(0.3),
                            EcoColors.chartLine.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FlSpot> _fallbackSpots() {
    const vals = [
      2000, 3000, 4500, 3800, 5000, 6200, 5800, 7000,
      6500, 8000, 7500, 8600, 9000, 10000, 11500, 12000,
      11000, 12500, 13000, 12800, 13500, 14000, 13200, 14500, 15000,
    ];
    return vals.asMap().entries
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value.toDouble()))
        .toList();
  }

  // ── MANAGEMENT SECTION ──
  Widget _buildManagementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Management',
                    style: GoogleFonts.poppins(
                        color: EcoColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AdminRoutes.reports),
                  child: Row(
                    children: [
                      Text('View All',
                          style: GoogleFonts.poppins(
                              color: EcoColors.accent, fontSize: 11)),
                      const Icon(Icons.chevron_right_rounded,
                          color: EcoColors.accent, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.managementCardsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LoadingWidget();
                }
                if (snap.hasError) return const _ErrorWidget();

                List<Map<String, dynamic>> cards = _fallbackMgmtCards();
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  cards = snap.data!.docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .toList();
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (_, i) => _managementCard(cards[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _managementCard(Map<String, dynamic> data) {
    final iconData = _iconFromName(data['icon'] as String? ?? 'eco');
    final route = data['routeName'] as String? ?? '/';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EcoColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EcoColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: EcoColors.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: EcoColors.accent, size: 16),
                ),
                const Spacer(),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: EcoColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: EcoColors.accent, size: 14),
                ),
              ],
            ),
            const Spacer(),
            Text(
              data['title'] as String? ?? 'Management',
              style: GoogleFonts.poppins(
                  color: EcoColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data['subtitle'] as String? ?? '',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF5C7A5E), fontSize: 9),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM ROW ──
  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRecentActivity()),
          const SizedBox(width: 12),
          Expanded(child: _buildFeedbackOverview()),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity',
                  style: GoogleFonts.poppins(
                      color: EcoColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AdminRoutes.reports),
                child: Text('View All',
                    style: GoogleFonts.poppins(
                        color: EcoColors.accent, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.recentActivityStream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _LoadingWidget();
              }
              if (snap.hasError) return const _ErrorWidget();

              List<Map<String, dynamic>> items = _fallbackActivity();
              if (snap.hasData && snap.data!.docs.isNotEmpty) {
                items = snap.data!.docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();
              }

              return Column(
                children: items.map(_activityItem).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _activityItem(Map<String, dynamic> data) {
    final icon = _activityIcon(data['title'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: EcoColors.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: EcoColors.accent, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] as String? ?? '',
                    style: GoogleFonts.poppins(
                        color: EcoColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(data['subtitle'] as String? ?? '',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF5C7A5E), fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            _formatTime(data['time']),
            style:
                GoogleFonts.poppins(color: const Color(0xFF5C7A5E), fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOverview() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feedback Overview',
              style: GoogleFonts.poppins(
                  color: EcoColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 12),
          StreamBuilder<DocumentSnapshot>(
            stream: FirestoreService.feedbackStream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _LoadingWidget();
              }
              if (snap.hasError) return const _ErrorWidget();

              int total = 98;
              double pos = 0.66, neu = 0.20, neg = 0.14;

              if (snap.hasData && snap.data!.exists) {
                final d = snap.data!.data() as Map<String, dynamic>;
                total = (d['total'] as num?)?.toInt() ?? 98;
                pos = (d['positivePercent'] as num?)?.toDouble() ?? 66;
                neu = (d['neutralPercent'] as num?)?.toDouble() ?? 20;
                neg = (d['negativePercent'] as num?)?.toDouble() ?? 14;
                // Normalize if stored as percentages
                if (pos > 1) {
                  pos /= 100;
                  neu /= 100;
                  neg /= 100;
                }
              }

              return _feedbackContent(total, pos, neu, neg);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AdminRoutes.feedback),
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View All Feedback',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackContent(int total, double pos, double neu, double neg) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  sections: [
                    PieChartSectionData(
                        value: pos * 100,
                        color: EcoColors.positive,
                        radius: 22,
                        showTitle: false),
                    PieChartSectionData(
                        value: neu * 100,
                        color: EcoColors.neutral,
                        radius: 22,
                        showTitle: false),
                    PieChartSectionData(
                        value: neg * 100,
                        color: EcoColors.negative,
                        radius: 22,
                        showTitle: false),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: GoogleFonts.poppins(
                          color: EcoColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20)),
                  Text('Total',
                      style: GoogleFonts.poppins(
                          color: EcoColors.textSecondary, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _legendItem(EcoColors.positive, 'Positive',
            '${(pos * 100).toInt()} (${(pos * 100).toInt()}%)'),
        _legendItem(EcoColors.neutral, 'Neutral',
            '${(neu * 100).toInt()} (${(neu * 100).toInt()}%)'),
        _legendItem(EcoColors.negative, 'Negative',
            '${(neg * 100).toInt()} (${(neg * 100).toInt()}%)'),
      ],
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  color: EcoColors.textSecondary, fontSize: 9)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  color: EcoColors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── GLASS CARD ──
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x22132316),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EcoColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── HELPERS ──
  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = (v as num).toInt();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _fmtDouble(dynamic v) =>
      (v as num?)?.toStringAsFixed(1) ?? '0.0';

  String _shortNum(double v) {
    if (v >= 1000) return '${(v / 1000).toInt()}K';
    return v.toInt().toString();
  }

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return ts?.toString() ?? '';
  }

  IconData _iconFromName(String name) {
    const map = {
      'people': Icons.people_rounded,
      'product': Icons.inventory_2_rounded,
      'recipe': Icons.restaurant_menu_rounded,
      'challenge': Icons.emoji_events_rounded,
      'content': Icons.article_rounded,
      'analytics': Icons.bar_chart_rounded,
      'eco': Icons.eco_rounded,
      'feedback': Icons.feedback_rounded,
    };
    for (final k in map.keys) {
      if (name.toLowerCase().contains(k)) return map[k]!;
    }
    return Icons.dashboard_rounded;
  }

  IconData _activityIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('user')) return Icons.person_add_rounded;
    if (t.contains('product')) return Icons.add_shopping_cart_rounded;
    if (t.contains('challenge')) return Icons.emoji_events_rounded;
    if (t.contains('recipe')) return Icons.restaurant_menu_rounded;
    return Icons.notifications_rounded;
  }

  List<Map<String, dynamic>> _fallbackMgmtCards() => [
        {
          'title': 'User Management',
          'subtitle': 'Manage users and permissions',
          'icon': 'people',
          'routeName': AdminRoutes.users,
        },
        {
          'title': 'Product Management',
          'subtitle': 'Add, edit and manage products',
          'icon': 'product',
          'routeName': AdminRoutes.products,
        },
        {
          'title': 'Recipe Management',
          'subtitle': 'Manage healthy recipes',
          'icon': 'recipe',
          'routeName': AdminRoutes.recipes,
        },
        {
          'title': 'Challenge Management',
          'subtitle': 'Create and manage eco challenges',
          'icon': 'challenge',
          'routeName': AdminRoutes.challenges,
        },
        {
          'title': 'Content Manager',
          'subtitle': 'Manage educational content',
          'icon': 'content',
          'routeName': AdminRoutes.content,
        },
        {
          'title': 'Reports & Analytics',
          'subtitle': 'View reports and analytics',
          'icon': 'analytics',
          'routeName': AdminRoutes.reports,
        },
        {
          'title': 'Eco Tips Manager',
          'subtitle': 'Add and manage eco tips',
          'icon': 'eco',
          'routeName': AdminRoutes.ecoTips,
        },
        {
          'title': 'Feedback & Queries',
          'subtitle': 'View feedback and user queries',
          'icon': 'feedback',
          'routeName': AdminRoutes.feedback,
        },
      ];

  List<Map<String, dynamic>> _fallbackActivity() => [
        {
          'title': 'New user registered',
          'subtitle': 'John Doe joined EcoSphere',
          'time': '2m ago',
        },
        {
          'title': 'New product added',
          'subtitle': 'Bamboo Toothbrush added',
          'time': '15m ago',
        },
        {
          'title': 'New challenge created',
          'subtitle': 'Plastic Free July Challenge',
          'time': '1h ago',
        },
      ];
}


// ─────────────────────────────────────────────
// MANAGE USERS SCREEN
// ─────────────────────────────────────────────
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;
    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query) || role.contains(query);
    }).toList();
  }

  Future<void> _toggleBlock(String docId, bool blocked) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'blocked': !blocked,
    });
  }

  Future<void> _deleteUser(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EcoColors.card,
        title: Text('Delete User?', style: GoogleFonts.poppins(color: EcoColors.textPrimary)),
        content: Text(
          'This will delete user data from Firestore only.',
          style: GoogleFonts.poppins(color: EcoColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EcoColors.negative),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.bg,
      appBar: AppBar(
        backgroundColor: EcoColors.card,
        iconTheme: const IconThemeData(color: EcoColors.accentLight),
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(
            color: EcoColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('email').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingWidget();
                if (snapshot.hasError) return const _ErrorWidget();

                final users = _filterUsers(snapshot.data?.docs ?? []);
                if (users.isEmpty) return const _EmptyWidget(message: 'No users found');

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final doc = users[index];
                    final data = doc.data();

                    return _userCard(
                      docId: doc.id,
                      name: (data['fullName'] ?? data['name'] ?? 'Unknown User').toString(),
                      email: (data['email'] ?? 'No email').toString(),
                      role: (data['role'] ?? 'user').toString(),
                      blocked: data['blocked'] == true,
                      imageUrl: (data['profileImage'] ?? data['photoUrl'] ?? '').toString(),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: EcoColors.glassWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EcoColors.glassBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: EcoColors.textPrimary),
              onChanged: (value) => setState(() => searchText = value),
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: const Icon(Icons.search_rounded, color: EcoColors.accentLight),
                hintText: 'Search users by name, email or role',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF5C7A5E), fontSize: 12),
              ),
            ),
          ),
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
    required String imageUrl,
  }) {
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.glassWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EcoColors.glassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: EcoColors.iconBg,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: EcoColors.accentLight)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: EcoColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: const Color(0xFF5C7A5E), fontSize: 10),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _badge(isAdmin ? 'Admin' : 'User', isAdmin ? Colors.deepPurpleAccent : EcoColors.accent),
                    const SizedBox(width: 6),
                    _badge(blocked ? 'Blocked' : 'Active', blocked ? EcoColors.negative : EcoColors.positive),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: EcoColors.card,
            iconColor: EcoColors.accentLight,
            onSelected: (value) {
              if (value == 'block') _toggleBlock(docId, blocked);
              if (value == 'delete') _confirmDelete(docId);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'block',
                child: Text(blocked ? 'Unblock' : 'Block',
                    style: GoogleFonts.poppins(color: EcoColors.textPrimary)),
              ),
              if (!isAdmin)
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: GoogleFonts.poppins(color: EcoColors.negative)),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PLACEHOLDER SCREEN
// ─────────────────────────────────────────────
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.bg,
      appBar: AppBar(
        backgroundColor: EcoColors.card,
        title: Text(title,
            style: GoogleFonts.poppins(
                color: EcoColors.textPrimary, fontSize: 16)),
        iconTheme: const IconThemeData(color: EcoColors.accentLight),
      ),
      body: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
              color: EcoColors.textSecondary, fontSize: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATE WIDGETS
// ─────────────────────────────────────────────
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: EcoColors.accent,
          ),
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: EcoColors.negative, size: 16),
          const SizedBox(width: 6),
          Text('Failed to load data',
              style: GoogleFonts.poppins(
                  color: EcoColors.negative, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final String message;
  const _EmptyWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(message,
            style: GoogleFonts.poppins(
                color: EcoColors.textSecondary, fontSize: 11)),
      ),
    );
  }
}