import 'package:flutter/material.dart';
import 'pledge_screen.dart';
import 'models/ngo_model.dart';

class DetailsScreen extends StatelessWidget {
  final Ngo ngo;
  const DetailsScreen({super.key, required this.ngo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE4D7FF), Color(0xFF9F7BFF)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainCard(),
                          const SizedBox(height: 16),
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ngo.about,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Current Needs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: const [
                              _NeedChip(label: 'Clothes'),
                              _NeedChip(label: 'Medicine'),
                              _NeedChip(label: 'Food'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildUrgentCard(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PledgeScreen(ngo: ngo),
                                  ),
                                );
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4C3C7A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Pledge Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: call backend to save NGO / favourite
                              },
                              icon: const Icon(
                                Icons.favorite_border,
                                size: 18,
                                color: Color(0xFF4C3C7A),
                              ),
                              label: const Text(
                                'Save NGO',
                                style: TextStyle(
                                  color: Color(0xFF4C3C7A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF1F1234),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              ngo.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.person_outline, size: 40),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              // ✅ Category placeholder like HomeScreen
              height: 180,
              width: double.infinity,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(ngo.category),
                    size: 48,
                    color: Color(0xFF4C3C7A),
                  ),
                  SizedBox(height: 8),
                  Text(
                    ngo.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4C3C7A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ngo.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1234),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ngo.distance,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${ngo.location}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Verified NGO',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2E9FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    ngo.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B3B80),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urgent Request',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ngo.urgentText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F1234),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'clothes' => Icons.checkroom,
      'food' => Icons.restaurant,
      'electronics' => Icons.devices,
      'toys' => Icons.toys,
      'books' => Icons.menu_book,
      _ => Icons.category,
    };
  }
}

class _NeedChip extends StatelessWidget {
  final String label;

  const _NeedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF4B3B80)),
      ),
    );
  }
}
