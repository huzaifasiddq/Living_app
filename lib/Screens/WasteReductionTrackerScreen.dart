import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF2E7D32);
const kPrimaryLight = Color(0xFF4CAF50);
const kPrimaryLighter = Color(0xFF81C784);
const kBgWhite = Color(0xFFF5F9F5);
const kCardWhite = Colors.white;
const kTextDark = Color(0xFF1B2D1C);
const kTextGrey = Color(0xFF7A9B7B);

// Waste weight factors (kg per unit)
const Map<String, double> kWeightFactors = {
  'plasticBottles': 0.02,
  'paper': 0.05,
  'aluminumCans': 0.03,
  'compost': 0.08,
  'reusableItems': 0.01,
};

// ─── Main Screen ─────────────────────────────────────────────────────────────
class WasteReductionTrackerScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const WasteReductionTrackerScreen({super.key, this.onBackTap});

  @override
  State<WasteReductionTrackerScreen> createState() =>
      _WasteReductionTrackerScreenState();
}

class _WasteReductionTrackerScreenState
    extends State<WasteReductionTrackerScreen>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Form quantities
  final Map<String, double> _quantities = {
    'plasticBottles': 12,
    'paper': 8,
    'aluminumCans': 6,
    'compost': 2.5,
    'reusableItems': 5,
  };

  final Map<String, String> _units = {
    'plasticBottles': 'pcs',
    'paper': 'kg',
    'aluminumCans': 'pcs',
    'compost': 'kg',
    'reusableItems': 'items',
  };

  bool _isSaving = false;
  bool _savedSuccess = false;

  late AnimationController _saveAnimCtrl;
  late AnimationController _summaryAnimCtrl;
  late Animation<double> _summaryAnim;

  String get _uid => _auth.currentUser?.uid ?? 'demo';

  @override
  void initState() {
    super.initState();
    _saveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _summaryAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _summaryAnim = CurvedAnimation(
      parent: _summaryAnimCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _saveAnimCtrl.dispose();
    _summaryAnimCtrl.dispose();
    super.dispose();
  }

  // ── Calculation helpers ──────────────────────────────────────────────────
  double _calcWasteSaved() {
    double total = 0;
    _quantities.forEach((key, qty) {
      total += qty * (kWeightFactors[key] ?? 0);
    });
    return double.parse(total.toStringAsFixed(2));
  }

  double _calcRecyclePercent() {
    final plastic = _quantities['plasticBottles']! * 0.02;
    final paper = _quantities['paper']! * 0.05;
    final metal = _quantities['aluminumCans']! * 0.03;
    final organic = _quantities['compost']! * 0.08;
    final total =
        plastic +
        paper +
        metal +
        organic +
        _quantities['reusableItems']! * 0.01;
    if (total == 0) return 0;
    final recycled = plastic + paper + metal + organic;
    return (recycled / total * 100).clamp(0, 100);
  }

  Map<String, double> _calcCategoryPercents() {
    final plastic = _quantities['plasticBottles']! * 0.02;
    final paper = _quantities['paper']! * 0.05;
    final metal = _quantities['aluminumCans']! * 0.03;
    final organic = _quantities['compost']! * 0.08;
    final total = plastic + paper + metal + organic + 0.001;
    return {
      'Plastic': double.parse((plastic / total * 100).toStringAsFixed(0)),
      'Paper': double.parse((paper / total * 100).toStringAsFixed(0)),
      'Metal': double.parse((metal / total * 100).toStringAsFixed(0)),
      'Organic': double.parse((organic / total * 100).toStringAsFixed(0)),
    };
  }

  // ── Firestore save ───────────────────────────────────────────────────────
  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final wasteSaved = _calcWasteSaved();
      final recyclePercent = _calcRecyclePercent();
      final now = DateTime.now();
      final dayKey = [
        'mon',
        'tue',
        'wed',
        'thu',
        'fri',
        'sat',
        'sun',
      ][now.weekday - 1];

      // Save waste record
      await _db.collection('users').doc(_uid).collection('wasteRecords').add({
        'date': Timestamp.now(),
        'plasticBottles': _quantities['plasticBottles'],
        'paper': _quantities['paper'],
        'aluminumCans': _quantities['aluminumCans'],
        'compost': _quantities['compost'],
        'reusableItems': _quantities['reusableItems'],
        'wasteSaved': wasteSaved,
        'recyclePercent': recyclePercent,
      });

      // Update weekly stats
      await _db
          .collection('users')
          .doc(_uid)
          .collection('weeklyWasteStats')
          .doc('current')
          .set({dayKey: wasteSaved}, SetOptions(merge: true));

      setState(() {
        _isSaving = false;
        _savedSuccess = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _savedSuccess = false);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgWhite,
      body: Stack(
        children: [
          // Background
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildAddWasteRecord(),
                  const SizedBox(height: 20),
                  _buildActivityAndWeekly(),
                  const SizedBox(height: 20),
                  _buildEcoTips(),
                  const SizedBox(height: 20),
                  _buildAchievements(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ───────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Color(0xFFF5F9F5)],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _glassButton(
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: kPrimary,
            ),
            onTap: () {
              if (widget.onBackTap != null) {
                widget.onBackTap!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Waste Reduction Tracker',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                Text(
                  'Reduce waste, save the planet 🌿',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _glassButton(
            child: const Icon(Icons.history_rounded, size: 20, color: kPrimary),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback onTap}) {
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
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  // ── Summary Card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(_uid)
          .collection('wasteRecords')
          .orderBy('date', descending: true)
          .limit(14)
          .snapshots(),
      builder: (context, snap) {
        double recycled = 128;
        double plastic = 2.45;
        double wasteSaved = 8.6;

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final docs = snap.data!.docs;
          recycled = docs.fold<double>(
            0,
            (s, d) => s + (d['plasticBottles'] ?? 0) + (d['paper'] ?? 0),
          );
          plastic = docs.fold<double>(
            0,
            (s, d) =>
                s +
                ((d['plasticBottles'] ?? 0) as num) * 0.02 +
                ((d['paper'] ?? 0) as num) * 0.05,
          );
          wasteSaved = docs.fold<double>(
            0,
            (s, d) => s + ((d['wasteSaved'] ?? 0) as num),
          );
          recycled = recycled.clamp(0, 9999);
          plastic = double.parse(plastic.toStringAsFixed(2));
          wasteSaved = double.parse(wasteSaved.toStringAsFixed(1));
        }

        return AnimatedBuilder(
          animation: _summaryAnim,
          builder: (_, __) => Opacity(
            opacity: _summaryAnim.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _summaryAnim.value)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Waste Summary',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _summaryItem(
                                    icon: Icons.recycling_rounded,
                                    label: 'Recycled Items',
                                    value: '${recycled.toInt()}',
                                    unit: 'items',
                                    percent: '+24%',
                                  ),
                                  _summaryDivider(),
                                  _summaryItem(
                                    icon: Icons.water_drop_outlined,
                                    label: 'Plastic Reduced',
                                    value: '${plastic}',
                                    unit: 'kg',
                                    percent: '+18%',
                                  ),
                                  _summaryDivider(),
                                  _summaryItem(
                                    icon: Icons.eco_rounded,
                                    label: 'Waste Saved',
                                    value: '${wasteSaved}',
                                    unit: 'kg',
                                    percent: '+21%',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 60, color: Colors.white.withOpacity(0.2));

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String percent,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                color: Color(0xFFA5D6A7),
                size: 12,
              ),
              Text(
                percent,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFA5D6A7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Add Waste Record ─────────────────────────────────────────────────────
  Widget _buildAddWasteRecord() {
    final items = [
      {
        'key': 'plasticBottles',
        'icon': Icons.sports_bar_outlined,
        'color': const Color(0xFF43A047),
        'title': 'Plastic Bottles',
        'subtitle': 'Recycled plastic bottles',
        'units': ['pcs', 'kg'],
      },
      {
        'key': 'paper',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF66BB6A),
        'title': 'Paper',
        'subtitle': 'Recycled paper or cardboard',
        'units': ['kg', 'pcs'],
      },
      {
        'key': 'aluminumCans',
        'icon': Icons.wine_bar_outlined,
        'color': const Color(0xFF81C784),
        'title': 'Aluminium Cans',
        'subtitle': 'Recycled aluminium cans',
        'units': ['pcs', 'kg'],
      },
      {
        'key': 'compost',
        'icon': Icons.eco_rounded,
        'color': const Color(0xFF4CAF50),
        'title': 'Compost',
        'subtitle': 'Organic waste composted',
        'units': ['kg', 'pcs'],
      },
      {
        'key': 'reusableItems',
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFF388E3C),
        'title': 'Reusable Items Used',
        'subtitle': 'Used reusable items',
        'units': ['items', 'pcs'],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: kCardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Add Your Waste Record',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
            ),
            ...items.map((item) => _wasteRow(item)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _buildSaveButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wasteRow(Map item) {
    final key = item['key'] as String;
    final units = item['units'] as List<String>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: item['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                Text(
                  item['subtitle'] as String,
                  style: GoogleFonts.poppins(fontSize: 10, color: kTextGrey),
                ),
              ],
            ),
          ),
          // Minus
          _counterBtn(
            icon: Icons.remove,
            onTap: () => setState(() {
              final step = key == 'compost' ? 0.5 : 1.0;
              _quantities[key] = (_quantities[key]! - step).clamp(0, 9999);
            }),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            child: Text(
              _quantities[key]! % 1 == 0
                  ? _quantities[key]!.toInt().toString()
                  : _quantities[key]!.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Plus
          _counterBtn(
            icon: Icons.add,
            onTap: () => setState(() {
              final step = key == 'compost' ? 0.5 : 1.0;
              _quantities[key] = _quantities[key]! + step;
            }),
          ),
          const SizedBox(width: 8),
          // Unit dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kBgWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _units[key],
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: kTextGrey,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: kTextDark,
                  fontWeight: FontWeight.w500,
                ),
                items: units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _units[key] = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: kBgWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCDCDC)),
        ),
        child: Icon(icon, size: 16, color: kTextDark),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveRecord,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _savedSuccess
                ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                : [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _savedSuccess
                          ? Icons.check_circle_rounded
                          : Icons.eco_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _savedSuccess ? 'Saved!' : 'Save Waste Record',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Activity + Weekly ────────────────────────────────────────────────────
  Widget _buildActivityAndWeekly() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRecyclingActivity()),
          const SizedBox(width: 12),
          Expanded(child: _buildWeeklyChart()),
        ],
      ),
    );
  }

  Widget _buildRecyclingActivity() {
    final percents = _calcCategoryPercents();
    final recyclePercent = _calcRecyclePercent();

    final colors = [
      kPrimary,
      const Color(0xFF81C784),
      const Color(0xFFBDBDBD),
      const Color(0xFFA5D6A7),
    ];
    final labels = ['Plastic', 'Paper', 'Metal', 'Organic'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recycling Activity',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: [
                      PieChartSectionData(
                        value: percents['Plastic'],
                        color: kPrimary,
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: percents['Paper'],
                        color: const Color(0xFF81C784),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: percents['Metal'],
                        color: const Color(0xFFBDBDBD),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: percents['Organic'],
                        color: const Color(0xFFA5D6A7),
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${recyclePercent.toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    Text(
                      'Recycled',
                      style: GoogleFonts.poppins(fontSize: 8, color: kTextGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    labels[i],
                    style: GoogleFonts.poppins(fontSize: 9, color: kTextGrey),
                  ),
                  const Spacer(),
                  Text(
                    '${percents[labels[i]]?.toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: kTextDark,
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

  Widget _buildWeeklyChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(_uid)
          .collection('weeklyWasteStats')
          .snapshots(),
      builder: (context, snap) {
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        Map<String, double> vals = {for (var k in keys) k: 0};

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final d = snap.data!.docs.first.data() as Map<String, dynamic>;
          for (var k in keys) {
            vals[k] = (d[k] ?? 0).toDouble();
          }
        } else {
          // Demo data
          vals = {
            'mon': 4.2,
            'tue': 3.8,
            'wed': 5.1,
            'thu': 4.5,
            'fri': 3.9,
            'sat': 6.2,
            'sun': 8.6,
          };
        }

        final todayIdx = DateTime.now().weekday - 1;
        final maxVal = vals.values.reduce((a, b) => a > b ? a : b);
        final totalWaste = vals['sun'] ?? 8.6;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Waste Saved',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${totalWaste.toStringAsFixed(1)} kg',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            color: kPrimaryLight,
                            size: 10,
                          ),
                          Text(
                            '21%',
                            style: GoogleFonts.poppins(
                              color: kPrimaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'vs last week',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: kTextGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.3,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) => Text(
                            days[val.toInt()],
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: val.toInt() == todayIdx
                                  ? kPrimary
                                  : kTextGrey,
                              fontWeight: val.toInt() == todayIdx
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) {
                      final isToday = i == todayIdx;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: vals[keys[i]]!,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [kPrimary, kPrimaryLight]
                                  : [
                                      kPrimaryLighter.withOpacity(0.4),
                                      kPrimaryLighter.withOpacity(0.7),
                                    ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Eco Tips ─────────────────────────────────────────────────────────────
  Widget _buildEcoTips() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('ecoTips').limit(1).snapshots(),
      builder: (context, snap) {
        String tipText =
            'Use cloth bags instead of plastic bags. It can reduce plastic waste by up to 30%.';
        String reductionPercent = '30%';

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final d = snap.data!.docs.first.data() as Map<String, dynamic>;
          tipText = d['text'] ?? tipText;
          reductionPercent = '${d['reductionPercent'] ?? 30}%';
        }

        // Highlight percentage
        final parts = tipText.split(reductionPercent);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: kPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eco Tips For You',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: kTextGrey,
                          ),
                          children: parts.length == 2
                              ? [
                                  TextSpan(text: parts[0]),
                                  TextSpan(
                                    text: reductionPercent,
                                    style: GoogleFonts.poppins(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextSpan(text: parts[1]),
                                ]
                              : [TextSpan(text: tipText)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: kTextGrey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Achievements ─────────────────────────────────────────────────────────
  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Achievements',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All >',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('users')
                .doc(_uid)
                .collection('achievements')
                .snapshots(),
            builder: (context, snap) {
              // Default achievements
              final defaults = [
                {
                  'title': 'Recycler',
                  'progress': '10 Records',
                  'unlocked': true,
                  'icon': Icons.recycling_rounded,
                },
                {
                  'title': 'Eco Starter',
                  'progress': '1 Week Streak',
                  'unlocked': true,
                  'icon': Icons.eco_rounded,
                },
                {
                  'title': 'Plastic Saver',
                  'progress': '2.5 kg Saved',
                  'unlocked': true,
                  'icon': Icons.water_drop_rounded,
                },
                {
                  'title': 'Green Habit',
                  'progress': '5 Actions',
                  'unlocked': false,
                  'icon': Icons.local_florist_rounded,
                },
                {
                  'title': 'Planet Helper',
                  'progress': '7 Days Active',
                  'unlocked': false,
                  'icon': Icons.public_rounded,
                },
              ];

              List<Map> achievements = defaults;
              if (snap.hasData && snap.data!.docs.isNotEmpty) {
                achievements = snap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return {
                    'title': data['title'] ?? '',
                    'progress': data['progress'] ?? '',
                    'unlocked': data['unlocked'] ?? false,
                    'icon': Icons.emoji_events_rounded,
                  };
                }).toList();
              }

              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _achievementBadge(achievements[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _achievementBadge(Map item) {
    final unlocked = item['unlocked'] as bool;
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: unlocked
                    ? [kPrimary, kPrimaryLight]
                    : [const Color(0xFFBDBDBD), const Color(0xFFE0E0E0)],
              ),
              shape: BoxShape.circle,
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              item['icon'] as IconData,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['title'] as String,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item['progress'] as String,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 8, color: kTextGrey),
          ),
        ],
      ),
    );
  }
}
