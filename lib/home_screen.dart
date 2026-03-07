import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;

  final List<Map<String, String>> _urgentNgos = [
    {
      'title': 'Mother Mary NGO',
      'subtitle': 'Funds for helping medical support of old age people',
      'distance': '1.3 km away',
      'tag': 'Medical',
      'image': 'assets/images/ngo1.png',
    },
    {
      'title': 'Sahayata NGO',
      'subtitle':
          'Urgent need of health care and clothes for viral flu combat.',
      'distance': '3.5 km away',
      'tag': 'Health',
      'image': 'assets/images/ngo2.png',
    },
  ];

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
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Morning, User!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSearchBox(),
                          const SizedBox(height: 12),
                          _buildLeaderboardButton(),
                          const SizedBox(height: 18),
                          const Text(
                            'NGOs With Urgent Need',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 260,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _urgentNgos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final ngo = _urgentNgos[index];
                                return _NgoCard(
                                  title: ngo['title']!,
                                  subtitle: ngo['subtitle']!,
                                  distance: ngo['distance']!,
                                  tag: ngo['tag']!,
                                  imageAsset: ngo['image']!,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'NGOs Near You',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCategoriesRow(),
                          const SizedBox(height: 16),
                          _NgoCard(
                            title: 'Mother Teressa NGO',
                            subtitle:
                                'Needs other supplies through Cancer Charity women.',
                            distance: '1.3 km away',
                            tag: 'Toys',
                            imageAsset: 'assets/images/ngo3.png',
                          ),
                          const SizedBox(height: 24),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Color(0xFF1F1234)),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: const Color(0xFF1F1234),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'What do you want to donate?',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLeaderboardButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          // TODO: navigate to leaderboard screen
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C3C7A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'View Leaderboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    final labels = ['Toys', 'Financial', 'Clothes', 'Health'];
    final icons = [
      Icons.toys,
      Icons.attach_money,
      Icons.checkroom,
      Icons.health_and_safety,
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = index);
              // TODO: filter NGOs using backend data
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4C3C7A)
                    : const Color(0xFFF2E9FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    icons[index],
                    size: 24,
                    color: selected ? Colors.white : const Color(0xFF4B3B80),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : const Color(0xFF4B3B80),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NgoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String distance;
  final String tag;
  final String imageAsset;

  const _NgoCard({
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.tag,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.asset(
              imageAsset,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F1234),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      distance,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2E9FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4B3B80),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: open NGO details screen
                    },
                    child: const Text('View details'),
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
