import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
class _C {
  static const green1 = Color(0xFF1B5E20);
  static const green2 = Color(0xFF2E7D32);
  static const green3 = Color(0xFF43A047);
  static const green4 = Color(0xFF66BB6A);
  static const green5 = Color(0xFFA5D6A7);
  static const green6 = Color(0xFFE8F5E9);
  static const bg = Color(0xFFF1F8F1);
  static const card = Colors.white;

  static const transport = {
    'Car': 0.21,
    'Bus': 0.08,
    'Bike': 0.0,
    'Train': 0.05,
    'Walking': 0.0,
  };

  static const food = {
    'Vegetarian': 2.0,
    'Vegan': 1.5,
    'Mixed': 3.5,
    'Meat Heavy': 5.0,
  };

  static const electricFactor = 0.4;
}

// ─────────────────────────────────────────────
//  ENTRY WIDGET
// ─────────────────────────────────────────────
class CarbonTrackerScreen extends StatefulWidget {
  final VoidCallback? onBackTap;

  const CarbonTrackerScreen({super.key, this.onBackTap});

  @override
  State<CarbonTrackerScreen> createState() => _CarbonTrackerScreenState();
}

class _CarbonTrackerScreenState extends State<CarbonTrackerScreen>
    with SingleTickerProviderStateMixin {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo';
  final _db = FirebaseFirestore.instance;

  // Form state
  String _transport = 'Car';
  String _food = 'Vegetarian';
  final _distCtrl = TextEditingController(text: '25');
  final _elecCtrl = TextEditingController(text: '12.5');

  // Result state
  double? _calcCO2;
  String _ecoRating = '';
  bool _calculating = false;

  late final AnimationController _resultAnimCtrl;
  late final Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultAnimCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _distCtrl.dispose();
    _elecCtrl.dispose();
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  // ── Calculation ──
  Future<void> _calculate() async {
    final dist = double.tryParse(_distCtrl.text) ?? 0;
    final elec = double.tryParse(_elecCtrl.text) ?? 0;

    final transportCO2 = (_C.transport[_transport] ?? 0) * dist;
    final electricCO2 = elec * _C.electricFactor;
    final foodCO2 = _C.food[_food] ?? 0;
    final total = transportCO2 + electricCO2 + foodCO2;

    final rating = total < 5
        ? 'Great'
        : total < 10
        ? 'Good'
        : total < 15
        ? 'Average'
        : 'High';

    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final dayKey = DateFormat('EEE').format(now).toLowerCase(); // mon, tue …

    // Save carbon entry
    await _db.collection('users').doc(_uid).collection('carbonData').add({
      'date': Timestamp.fromDate(now),
      'transportType': _transport,
      'distance': dist,
      'electricityUsage': elec,
      'foodType': _food,
      'totalCO2': total,
      'ecoRating': rating,
      'reductionPercent': _reductionPercent(total),
    });

    // Update weekly stats
    await _db
        .collection('users')
        .doc(_uid)
        .collection('weeklyStats')
        .doc('current')
        .set({dayKey: FieldValue.increment(total)}, SetOptions(merge: true));

    // Update summary
    await _db.collection('users').doc(_uid).set({
      'todayCO2': FieldValue.increment(total),
      'weekCO2': FieldValue.increment(total),
      'ecoRating': rating,
    }, SetOptions(merge: true));

    setState(() {
      _calcCO2 = total;
      _ecoRating = rating;
      _calculating = false;
    });
    _resultAnimCtrl.forward(from: 0);
  }

  double _reductionPercent(double co2) {
    // Naive: compare against "average" of 15 kg/day
    final pct = ((15 - co2) / 15 * 100).clamp(0, 100);
    return pct.toDouble();
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildActivitiesCard(),
              const SizedBox(height: 16),
              _buildResultSection(),
              const SizedBox(height: 16),
              _buildEcoTip(),
              const SizedBox(height: 16),
              _buildWeeklyChart(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Stack(
      children: [
        // BG image
        SizedBox(
          height: 90,
          width: double.infinity,
          child: Image.asset(
            'assets/images/carbon_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD8F3DC), Color(0xFFF0F7F0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        // Overlay
        Container(
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_C.bg.withOpacity(0.5), _C.bg],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (widget.onBackTap != null) {
                        widget.onBackTap!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'Carbon Footprint Tracker',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _C.green1,
                        ),
                      ),
                      Text(
                        'Track your daily environmental impact',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _C.green3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _CircleBtn(icon: Icons.history_rounded, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Summary Card ──
  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(_uid).snapshots(),
        builder: (ctx, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};
          final today = (d['todayCO2'] as num?)?.toDouble() ?? 0.0;
          final week = (d['weekCO2'] as num?)?.toDouble() ?? 0.0;
          final rating = d['ecoRating'] as String? ?? 'Good';
          final redPct = _reductionPercent(today);

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Carbon Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.green1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCol(
                        label: "Today's CO₂",
                        value: '${today.toStringAsFixed(1)} kg',
                        sub: '',
                        chip: rating,
                      ),
                    ),
                    _vDivider(),
                    Expanded(
                      child: _SummaryCol(
                        label: 'This Week',
                        value: '${week.toStringAsFixed(1)} kg',
                        sub: 'Total CO₂',
                      ),
                    ),
                    _vDivider(),
                    Expanded(
                      child: Stack(
                        children: [
                          _SummaryCol(
                            label: 'Reduction',
                            value: '${redPct.toStringAsFixed(0)}%',
                            sub: '↓ vs last week',
                            subColor: _C.green3,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Image.asset(
                              'assets/images/leaf_icon.png',
                              width: 40,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco,
                                color: Color(0xFFB7E4C7),
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 50,
    color: _C.green6,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  // ── Activities Card ──
  Widget _buildActivitiesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Your Activities',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.green1,
              ),
            ),
            const SizedBox(height: 16),

            // Transport
            _ActivityRow(
              icon: Icons.directions_car_outlined,
              label: 'Transport',
              sub: 'Select transport type',
              child: _EcoDropdown(
                value: _transport,
                items: _C.transport.keys.toList(),
                onChanged: (v) => setState(() => _transport = v!),
              ),
            ),
            _divider(),

            // Distance
            _ActivityRow(
              icon: Icons.straighten_outlined,
              label: 'Distance Travelled',
              sub: 'Enter total distance',
              child: _EcoInput(controller: _distCtrl, suffix: 'km'),
            ),
            _divider(),

            // Electricity
            _ActivityRow(
              icon: Icons.bolt_outlined,
              label: 'Electricity Usage',
              sub: 'Total electricity used',
              child: _EcoInput(controller: _elecCtrl, suffix: 'kWh'),
            ),
            _divider(),

            // Food
            _ActivityRow(
              icon: Icons.restaurant_outlined,
              label: 'Food Consumption',
              sub: 'Select your diet type',
              child: _EcoDropdown(
                value: _food,
                items: _C.food.keys.toList(),
                onChanged: (v) => setState(() => _food = v!),
              ),
            ),
            const SizedBox(height: 20),

            // Calculate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _calculating ? null : _calculate,
                icon: _calculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Image.asset(
                        'assets/images/eco_leaf.jpg',
                        width: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                label: Text(
                  'Calculate Carbon Footprint',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.green2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    color: _C.green6,
    margin: const EdgeInsets.symmetric(vertical: 10),
  );

  // ── Result Section ──
  Widget _buildResultSection() {
    if (_calcCO2 == null) return const SizedBox.shrink();

    final co2 = _calcCO2!;
    final rating = _ecoRating;
    final pct = _reductionPercent(co2);

    // Eco rating gauge value 0..1
    final gaugeVal = rating == 'Great'
        ? 0.85
        : rating == 'Good'
        ? 0.65
        : rating == 'Average'
        ? 0.45
        : 0.25;

    return AnimatedBuilder(
      animation: _resultAnim,
      builder: (_, __) => Opacity(
        opacity: _resultAnim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _resultAnim.value)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Result',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.green1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Left: illustration + values
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Co2Badge(),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Carbon Footprint',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: _C.green3,
                                      ),
                                    ),
                                    Text(
                                      '${co2.toStringAsFixed(1)} kg CO₂',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: _C.green1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _ImpactChip(rating: rating),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Great job! You're better than\n${pct.toStringAsFixed(0)}% of EcoSphere users.",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: _C.green3,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right: gauge
                      _EcoGauge(value: gaugeVal, label: rating),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Eco Tip ──
  Widget _buildEcoTip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('ecoTips').limit(1).snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          final tip = docs.isNotEmpty
              ? (docs.first.data() as Map<String, dynamic>)
              : {
                  'text':
                      'Switch to public transport or carpool to reduce your carbon footprint by up to 30%.',
                  'reductionPotential': 30,
                };

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor(),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.green6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/eco_leaf.png',
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.eco, color: Color(0xFF40916C)),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.green1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF555555),
                          ),
                          children: [
                            TextSpan(text: tip['text'] as String? ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF40916C)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Weekly Chart ──
  Widget _buildWeeklyChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _db
            .collection('users')
            .doc(_uid)
            .collection('weeklyStats')
            .doc('current')
            .snapshots(),
        builder: (ctx, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};

          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

          // Default demo values when no data
          final defaultVals = [70.4, 65.2, 80.6, 75.1, 90.3, 78.6, 85.4];

          final values = List.generate(7, (i) {
            final v = (d[keys[i]] as num?)?.toDouble();
            return v ?? defaultVals[i];
          });

          final maxVal = values.reduce((a, b) => a > b ? a : b);
          final todayIdx = DateTime.now().weekday - 1; // 0=Mon

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Weekly Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.green1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _C.green6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'kg CO₂',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _C.green2,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: _C.green2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxVal * 1.25).ceilToDouble(),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.green,
                          getTooltipItem: (group, gi, rod, ri) =>
                              BarTooltipItem(
                                '${rod.toY.toStringAsFixed(1)}',
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final i = val.toInt();
                              if (i < 0 || i >= days.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[i],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: i == todayIdx
                                        ? _C.green2
                                        : const Color(0xFF999999),
                                    fontWeight: i == todayIdx
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFFAAAAAA),
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final i = val.toInt();
                              if (i < 0 || i >= values.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  values[i].toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    color: const Color(0xFF888888),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 25,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: _C.green6,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (i) {
                        final isToday = i == todayIdx;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isToday
                                    ? [_C.green2, _C.green4]
                                    : [_C.green5, _C.green6],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 600),
                    swapAnimationCurve: Curves.easeOut,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: _C.card,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ─────────────────────────────────────────────
//  SMALL WIDGETS
// ─────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: _C.green2, size: 18),
    ),
  );
}

class _SummaryCol extends StatelessWidget {
  const _SummaryCol({
    required this.label,
    required this.value,
    required this.sub,
    this.chip,
    this.subColor,
  });
  final String label;
  final String value;
  final String sub;
  final String? chip;
  final Color? subColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _C.green1,
          ),
        ),
        const SizedBox(height: 4),
        if (chip != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _C.green6,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco, color: _C.green3, size: 10),
                const SizedBox(width: 3),
                Text(
                  chip!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.green3,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            sub,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: subColor ?? const Color(0xFF888888),
            ),
          ),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.child,
  });
  final IconData icon;
  final String label;
  final String sub;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _C.green6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _C.green3, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.green1,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
      child,
    ],
  );
}

class _EcoDropdown extends StatelessWidget {
  const _EcoDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: _C.bg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _C.green6, width: 1.5),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 12, color: _C.green1),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down, color: _C.green3, size: 18),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    ),
  );
}

class _EcoInput extends StatelessWidget {
  const _EcoInput({required this.controller, required this.suffix});
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 90,
    height: 36,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _C.green1,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        suffixText: suffix,
        suffixStyle: GoogleFonts.poppins(fontSize: 11, color: _C.green3),
        filled: true,
        fillColor: _C.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.green6, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.green6, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.green3, width: 1.5),
        ),
      ),
    ),
  );
}

class _Co2Badge extends StatelessWidget {
  const _Co2Badge();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD8F3DC), Color(0xFF95D5B2)],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/co2_icon.png',
          width: 48,
          errorBuilder: (_, __, ___) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CO₂',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _C.green2,
                ),
              ),
              const Icon(Icons.arrow_downward, color: _C.green3, size: 14),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.rating});
  final String rating;

  Color get _color {
    switch (rating) {
      case 'Great':
        return _C.green3;
      case 'Good':
        return const Color(0xFF52B788);
      case 'Average':
        return const Color(0xFFF9C74F);
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.eco, color: _color, size: 12),
        const SizedBox(width: 4),
        Text(
          '${rating} Impact',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ],
    ),
  );
}

// ── Eco Gauge (half-circle arc meter) ──
class _EcoGauge extends StatelessWidget {
  const _EcoGauge({required this.value, required this.label});
  final double value; // 0..1
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 80,
        height: 50,
        child: CustomPaint(
          painter: _GaugePainter(value: value),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Image.asset(
                'assets/images/result_leaf.png',
                width: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco, color: _C.green3, size: 22),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Eco Rating',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: const Color(0xFF888888),
        ),
      ),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _C.green2,
        ),
      ),
    ],
  );
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value});
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.9;
    final r = size.width * 0.48;

    // Background arc
    final bgPaint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.14,
      3.14,
      false,
      bgPaint,
    );

    // Value arc
    final valPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.14,
      3.14 * value,
      false,
      valPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}
