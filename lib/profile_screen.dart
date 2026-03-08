import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'login_screen.dart';
import 'providers/donation_streak_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFB0F0),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (!authProvider.isLoggedIn) {
              return _buildGuestView(context);
            }
            return _buildProfileView(context, authProvider);
          },
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_off, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign in to see your profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1234),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C3C7A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, AuthProvider authProvider) {
    final username = authProvider.username ?? 'User';

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF2D1B6B),
                    size: 22,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.settings,
                    color: Color(0xFF2D1B6B),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 50),
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Community Helper',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFF4C3C7A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mumbai, Maharashtra',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatPill('⭐', '750', 'Impact Points'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatPill('🪙', '320', 'Coins')),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatPill('🎁', '18', 'Donations'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFBFB0F0),
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFF2E9FF),
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4C3C7A),
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: -4,
                        right: -4,
                        child: Text('⭐', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<DonationStreakProvider>(
              builder: (context, streakProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Donation Streak ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F1234),
                            ),
                          ),
                          Text('🔥', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${streakProvider.currentStreakWeeks} Week Streak',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D1B6B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        streakProvider.currentStreakWeeks > 0
                            ? 'Keep donating to maintain your streak!'
                            : 'Make a donation to start your streak!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      _buildHeatmap(streakProvider), // ✅ Pass provider
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStreakPill(
                            '📅',
                            'This month: ${streakProvider.thisMonthCount} Donations',
                          ),
                          const SizedBox(width: 8),
                          _buildStreakPill(
                            '🔥',
                            'Longest streak: ${streakProvider.longestStreakWeeks} weeks',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Recent Donations Card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Donations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1234),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDonationItem(
                    Icons.checkroom,
                    'Clothes',
                    'Sahayata NGO',
                    '3 items · 2 days ago',
                  ),
                  const SizedBox(height: 12),
                  _buildDonationItem(
                    Icons.lunch_dining,
                    'Food',
                    'Mother Teresa NGO',
                    '10 items · 1 week ago',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Open Community Button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B2D6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Open Community',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatPill(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1234),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF555555)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(DonationStreakProvider streakProvider) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    Color cellColor(int level) {
      switch (level) {
        case 1:
          return const Color(0xFFD4C9F5);
        case 2:
          return const Color(0xFF9B8FD4);
        case 3:
          return const Color(0xFF6A5BAF);
        case 4:
          return const Color(0xFF2D1B6B);
        default:
          return const Color(0xFFE8E4F5);
      }
    }

    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        Row(
          children: [
            const SizedBox(width: 24),
            ...months.map(
              (m) => Expanded(
                child: Text(
                  m,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: now.month - 1 == months.indexOf(m)
                        ? FontWeight
                              .bold // Highlight current month
                        : FontWeight.normal,
                    color: now.month - 1 == months.indexOf(m)
                        ? const Color(0xFF2D1B6B)
                        : const Color(0xFF555555),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // W1–W5 rows × 12 months — ✅ REAL DATA from provider
        ...List.generate(5, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    'W${weekIndex + 1}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                ...List.generate(12, (monthIndex) {
                  // ✅ Auto-calculates level from real donation timestamps
                  final level = streakProvider.getActivityLevel(
                    monthIndex,
                    weekIndex,
                  );
                  final isCurrentCell =
                      monthIndex == now.month - 1 &&
                      weekIndex == ((now.day - 1) / 7).floor();
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 16,
                      decoration: BoxDecoration(
                        color: cellColor(level),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrentCell
                            ? Border.all(
                                color: const Color(0xFF2D1B6B),
                                width: 1.5,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Less',
              style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
            const SizedBox(width: 4),
            ...List.generate(
              5,
              (i) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: cellColor(i),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'More',
              style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakPill(String emoji, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F1234),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationItem(
    IconData icon,
    String category,
    String ngo,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7B6FBF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$category  →  ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      TextSpan(
                        text: ngo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
