import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterProducts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.trim().isEmpty) return docs;

    final query = searchText.toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final description =
          (data['description'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  void _openProductDetail(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(data: data),
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
          'Eco Products',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _searchBox(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final products = _filterProducts(snapshot.data?.docs ?? []);

                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'No products available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 245,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final data = products[index].data();
                    return _productCard(data);
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
          hintText: 'Search eco products',
          hintStyle: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'No Title';
    final category = data['category'] ?? 'Eco Product';
    final price = data['price'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openProductDetail(data),
      child: Container(
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: imageUrl.toString().isNotEmpty
                  ? Image.network(
                      imageUrl.toString(),
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emptyImage(),
                    )
                  : _emptyImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    category.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price.toString().isNotEmpty
                              ? 'Rs. $price'
                              : 'Eco Friendly',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      width: double.infinity,
      height: 130,
      color: const Color(0xFFE8F5E9),
      child: const Icon(
        Icons.shopping_bag,
        color: Color(0xFF2E7D32),
        size: 42,
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProductDetailScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'No Title';
    final category = data['category'] ?? 'Eco Product';
    final price = data['price'] ?? '';
    final description = data['description'] ?? 'No description available';
    final imageUrl = data['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          title.toString(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.toString().isNotEmpty
                ? Image.network(
                    imageUrl.toString(),
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _detailEmptyImage(),
                  )
                : _detailEmptyImage(),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                    Text(
                      title.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      price.toString().isNotEmpty
                          ? 'Rs. $price'
                          : 'Eco Friendly Product',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      description.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailEmptyImage() {
    return Container(
      width: double.infinity,
      height: 280,
      color: const Color(0xFFE8F5E9),
      child: const Icon(
        Icons.shopping_bag,
        color: Color(0xFF2E7D32),
        size: 70,
      ),
    );
  }
}