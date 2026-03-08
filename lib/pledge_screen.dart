import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ngo_model.dart';
import '../api_service.dart';
import '../services/auth_provider.dart';
import '../providers/needs_provider.dart';
import '../providers/donation_streak_provider.dart';

class PledgeScreen extends StatefulWidget {
  final Ngo ngo;

  const PledgeScreen({super.key, required this.ngo});

  @override
  State<PledgeScreen> createState() => _PledgeScreenState();
}

class _PledgeScreenState extends State<PledgeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  String _selectedCategory = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.ngo.category;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _submitPledge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final api = ApiService();
      await api.pledge(
        needId: widget.ngo.id,
        category: _selectedCategory,
        quantity: int.parse(_qtyCtrl.text),
      );

      if (!mounted) return;
      final needsProvider = Provider.of<NeedsProvider>(context, listen: false);
      await needsProvider.fetchNeeds();
      await Provider.of<DonationStreakProvider>(
        context,
        listen: false,
      ).recordDonation();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pledge created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create pledge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final ngo = widget.ngo;
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

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
                  _buildHeader(context, ngo.title),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNgoSummary(ngo),
                            const SizedBox(height: 16),
                            const Text(
                              'What would you like to pledge?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F1234),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryChips(),
                            const SizedBox(height: 16),
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F1234),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('e.g. 5'),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter a quantity';
                                }
                                final n = int.tryParse(v);
                                if (n == null || n <= 0) {
                                  return 'Enter a valid positive number';
                                }
                                if (n > ngo.qtyNeeded) {
                                  return 'Cannot pledge more than needed (${ngo.qtyNeeded})';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Impact summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F1234),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'You are helping ${ngo.charityName} with urgent need for ${ngo.title.toLowerCase()}.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1F1234),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Needed: ${ngo.qtyNeeded}  ·  Already pledged: ${ngo.qtyPledged}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (!isLoggedIn || _isSubmitting)
                                    ? null
                                    : _submitPledge,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4C3C7A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        isLoggedIn
                                            ? 'Confirm Pledge'
                                            : 'Sign in to Pledge',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!isLoggedIn)
                              Center(
                                child: Text(
                                  'You need to be signed in to pledge.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
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

  Widget _buildHeader(BuildContext context, String title) {
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
              'Pledge · $title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1234),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildNgoSummary(Ngo ngo) {
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
              height: 160,
              width: double.infinity,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(ngo.category),
                    size: 56,
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
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      ngo.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4C3C7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                const SizedBox(height: 4),
                Text(
                  ngo.charityName,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = <String>[
      widget.ngo.category,
      'clothes',
      'food',
      'medicine',
      'toys',
      'electronics',
    ].toSet().toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return ChoiceChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (_) {
            setState(() => _selectedCategory = cat);
          },
          selectedColor: const Color(0xFF4C3C7A),
          backgroundColor: const Color(0xFFF2E9FF),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B3B80),
          ),
        );
      }).toList(),
    );
  }
}
