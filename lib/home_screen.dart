import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/needs_provider.dart';
import '../services/auth_provider.dart';
import 'details_screen.dart';
import '../models/ngo_model.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'clothes':
      return Icons.checkroom;
    case 'food':
      return Icons.restaurant;
    case 'medicine':
    case 'health':
      return Icons.health_and_safety;
    case 'books':
      return Icons.menu_book;
    case 'toys':
      return Icons.toys;
    case 'electronics':
      return Icons.devices;
    default:
      return Icons.category;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final needsProvider = Provider.of<NeedsProvider>(context, listen: false);
      needsProvider.fetchNeeds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        drawer: _buildDrawer(),
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
                      child: Consumer<NeedsProvider>(
                        builder: (context, needsProvider, child) {
                          if (needsProvider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!needsProvider.isLoading &&
                              needsProvider.needs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Color(0xFF1F1234),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to load NGOs or no data available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1234),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please check your connection or try again.',
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => needsProvider.fetchNeeds(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final allNeeds = needsProvider.needs;

                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: true,
                          );

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Morning, ${authProvider.isLoggedIn ? (authProvider.username ?? 'User') : 'Guest'}!',
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
                                  child: allNeeds.isEmpty
                                      ? const Center(
                                          child: Text('No urgent needs yet.'),
                                        )
                                      : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: allNeeds.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 16),
                                          itemBuilder: (context, index) {
                                            final ngo = allNeeds[index];
                                            return _NgoCard(ngo: ngo);
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
                                _buildCategoriesRow(allNeeds),
                                const SizedBox(height: 16),
                                _buildNearbyNgos(allNeeds),
                              ],
                            ),
                          );
                        },
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
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          backgroundColor: const Color(0xFF1F1234),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4C3C7A), Color(0xFF9F7BFF)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF4C3C7A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      authProvider.isLoggedIn
                          ? (authProvider.username ?? 'User')
                          : 'Guest',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'DonateHub v1.0',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu, color: Color(0xFF1F1234)),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Notifications')),
                    ),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1F1234),
                ),
              ),
              IconButton(
                onPressed: authProvider.isLoggedIn
                    ? () {
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    : null,
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      authProvider.isLoggedIn
                          ? Icons.logout
                          : Icons.person_outline,
                      color: Color(0xFF1F1234),
                    ),
                    if (authProvider.isLoggedIn &&
                        authProvider.username != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          authProvider.username![0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.leaderboard, size: 18),
        label: const Text('View Leaderboard'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C3C7A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow(List<Ngo> allNeeds) {
    final categories = [
      'All',
      ...allNeeds.map((ngo) => ngo.category).toSet().toList(),
    ]..sort();

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          final category = categories[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4C3C7A)
                    : const Color(0xFFF2E9FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 24,
                    color: selected ? Colors.white : const Color(0xFF4B3B80),
                  ),
                  if (category != 'All') ...[
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF4B3B80),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyNgos(List<Ngo> allNeeds) {
    final categories = [
      'All',
      ...allNeeds.map((ngo) => ngo.category).toSet().toList(),
    ];
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedCategoryName = _selectedCategory == 0
        ? 'All'
        : categories[_selectedCategory];

    final filteredNgos = selectedCategoryName == 'All'
        ? allNeeds
        : allNeeds
              .where(
                (ngo) =>
                    ngo.category.toLowerCase() ==
                    selectedCategoryName.toLowerCase(),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NGOs Near You',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1234),
              ),
            ),
            Text(
              '${filteredNgos.length} NGOs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        filteredNgos.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No NGOs found for this category',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredNgos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _NgoCard(ngo: filteredNgos[index]);
                },
              ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'clothes' => Icons.checkroom,
      'food' => Icons.restaurant,
      'medicine' || 'health' => Icons.health_and_safety,
      'books' => Icons.menu_book,
      'toys' => Icons.toys,
      'electronics' => Icons.devices,
      _ => Icons.category,
    };
  }
}

class _NgoCard extends StatelessWidget {
  final Ngo ngo;

  const _NgoCard({required this.ngo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsScreen(ngo: ngo)),
      ),
      child: Container(
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: ngo.image.isNotEmpty && ngo.image.startsWith('http')
                    ? Image.network(
                        ngo.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(ngo.category),
                            size: 48,
                            color: const Color(0xFF4C3C7A),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ngo.category.toUpperCase(),
                            style: const TextStyle(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ngo.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1234),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ngo.about.length > 60
                        ? '${ngo.about.substring(0, 60)}...'
                        : ngo.about,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ngo.distance,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
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
                          ngo.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4B3B80),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: ngo.qtyPledged / ngo.qtyNeeded,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4C3C7A),
                    ),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ngo.qtyPledged}/${ngo.qtyNeeded} pledged',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
