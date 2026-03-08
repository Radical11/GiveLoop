import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart'; // Adjust path

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      name: _nameCtrl.text,
      email: _usernameCtrl.text,
      password: _passwordCtrl.text,
    );

    if (success) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration failed. Check if email is valid and unique.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE4D7FF), Color(0xFF9F7BFF)],
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Join the GiveLoop community and start donating.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Full name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDecoration('Jane Doe'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('example@gmail.com'),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1234),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: _inputDecoration('••••••••'),
                        validator: (v) {
                          if (v == null || v.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C3C7A),
                            elevation: 12,
                            shadowColor: Colors.black.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/signin',
                          ),
                          child: const Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              children: [
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4C3C7A),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
