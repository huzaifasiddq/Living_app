import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/Screens/LoginScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$hint is required';
        }

        if (hint == 'Email Address' && !value.contains('@')) {
          return 'Enter valid email';
        }

        if (hint == 'Password' && value.length < 6) {
          return 'Password must be at least 6 characters';
        }

        if (hint == 'Confirm Password' &&
            value != _passwordController.text.trim()) {
          return 'Password does not match';
        }

        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF52B788)),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF52B788),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF52B788), width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton(String imageUrl) {
    return Container(
      width: 58,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Center(
        child: Image.network(
          imageUrl,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: const Color(0xFF52B788).withOpacity(0.25)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: size.height * 0.04),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: size.width * 0.23,
                            height: size.width * 0.23,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Sustainable\nLiving Guide',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: size.width * 0.09,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF102B1F),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Small steps today, a better tomorrow for all.',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.032,
                              color: const Color(0xFF355E3B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: 18,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.06,
                          vertical: size.height * 0.03,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B4332),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Container(
                                width: 28,
                                height: 2,
                                color: const Color(0xFF52B788),
                              ),

                              SizedBox(height: size.height * 0.025),

                              _buildTextField(
                                controller: _nameController,
                                hint: 'Full Name',
                                icon: Icons.person_outline,
                              ),

                              const SizedBox(height: 14),

                              _buildTextField(
                                controller: _emailController,
                                hint: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 14),

                              _buildTextField(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                obscure: _obscurePassword,
                                onToggle: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),

                              const SizedBox(height: 14),

                              _buildTextField(
                                controller: _confirmPasswordController,
                                hint: 'Confirm Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                obscure: _obscureConfirmPassword,
                                onToggle: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),

                              SizedBox(height: size.height * 0.025),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E9B31),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          'Create Account',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'or continue with',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Center(
                                child: _socialButton(
                                  'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF2D6A4F),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }
}
