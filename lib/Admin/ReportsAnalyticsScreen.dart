import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsAnalyticsScreen extends StatelessWidget {
  const ReportsAnalyticsScreen({super.key});

  Stream<int> _countStream(String collection) {
    return FirebaseFirestore.instance.collection(collection).snapshots().map(
          (snapshot) => snapshot.docs.length,
        );
  }

  Stream<double> _carbonTotalStream() {
    return FirebaseFirestore.instance.collection('carbon_records').snapshots().map(
      (snapshot) {
        double total = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final value = data['carbonKg'] ?? data['co2'] ?? data['totalCarbon'] ?? 0;

          if (value is int) total += value.toDouble();
          if (value is double) total += value;
          if (value is String) total += double.tryParse(value) ?? 0;
        }

        return total;
      },
    );
  }

  Stream<double> _wasteTotalStream() {
    return FirebaseFirestore.instance.collection('waste_records').snapshots().map(
      (snapshot) {
        double total = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final value = data['wasteKg'] ?? data['savedKg'] ?? data['recycledKg'] ?? 0;

          if (value is int) total += value.toDouble();
          if (value is double) total += value;
          if (value is String) total += double.tryParse(value) ?? 0;
        }

        return total;
      },
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
          'Reports & Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _headerCard(),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _countCard(
                  title: 'Users',
                  collection: 'users',
                  icon: Icons.people,
                  color: Colors.green,
                ),
                _countCard(
                  title: 'Products',
                  collection: 'products',
                  icon: Icons.shopping_bag,
                  color: Colors.teal,
                ),
                _countCard(
                  title: 'Recipes',
                  collection: 'recipes',
                  icon: Icons.restaurant,
                  color: Colors.orange,
                ),
                _countCard(
                  title: 'Challenges',
                  collection: 'challenges',
                  icon: Icons.emoji_events,
                  color: Colors.blue,
                ),
                _countCard(
                  title: 'Education',
                  collection: 'educational_content',
                  icon: Icons.article,
                  color: Colors.purple,
                ),
                _countCard(
                  title: 'Community',
                  collection: 'community_posts',
                  icon: Icons.forum,
                  color: Colors.pink,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _impactReports(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.bar_chart,
              color: Color(0xFF2E7D32),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'EcoSphere Analytics Overview',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countCard({
    required String title,
    required String collection,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<int>(
      stream: _countStream(collection),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(15),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.14),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _impactReports() {
    return Column(
      children: [
        _carbonReportCard(),
        const SizedBox(height: 14),
        _wasteReportCard(),
      ],
    );
  }

  Widget _carbonReportCard() {
    return StreamBuilder<double>(
      stream: _carbonTotalStream(),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;

        return _wideReportCard(
          icon: Icons.cloud,
          title: 'Total Carbon Recorded',
          value: '${total.toStringAsFixed(2)} kg CO₂',
          subtitle: 'Total carbon footprint logs submitted by users',
          color: Colors.green,
        );
      },
    );
  }

  Widget _wasteReportCard() {
    return StreamBuilder<double>(
      stream: _wasteTotalStream(),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;

        return _wideReportCard(
          icon: Icons.recycling,
          title: 'Total Waste Diverted',
          value: '${total.toStringAsFixed(2)} kg',
          subtitle: 'Total recycled or saved waste submitted by users',
          color: Colors.teal,
        );
      },
    );
  }

  Widget _wideReportCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: Colors.grey[500],
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