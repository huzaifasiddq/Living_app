import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/Admin/AdminDashboard.dart';
import 'package:my_app/MainScreen.dart';

import 'package:my_app/Screens/SignupScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(
          0.2,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    _fadeController.forward();

    Future.delayed(
      const Duration(milliseconds: 200),
      () {
        _slideController.forward();
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _fadeController.dispose();
    _slideController.dispose();

    super.dispose();
  }

  // ───────────────── LOGIN FUNCTION ─────────────────

  void _handleLogin() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter email and password'),
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final role = userDoc.data()?['role'] ?? 'user';

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminDashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    String message = 'Login failed';

    if (e.code == 'user-not-found') {
      message = 'No user found with this email';
    } else if (e.code == 'wrong-password') {
      message = 'Incorrect password';
    } else if (e.code == 'invalid-email') {
      message = 'Invalid email address';
    } else if (e.code == 'invalid-credential') {
      message = 'Invalid email or password';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong'),
      ),
    );
  }

  if (mounted) {
    setState(() => _isLoading = false);
  }
}

  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B5E20).withOpacity(0.18),
                    const Color(0xFF33691E).withOpacity(0.28),
                    const Color(0xFF1A237E).withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ───────── TOP SECTION ─────────

                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: size.height * 0.055,
                            bottom: size.height * 0.025,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.20),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Text(
                                'EcoSphere',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Live Green, Live Better 🌿',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color:
                                      Colors.white.withOpacity(0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ───────── LOGIN CARD ─────────

                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _cardFadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              28,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 30,
                                  sigmaY: 30,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(28),
                                    color: Colors.white
                                        .withOpacity(0.22),
                                    border: Border.all(
                                      color: Colors.white
                                          .withOpacity(0.38),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      24,
                                      28,
                                      24,
                                      24,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome Back',
                                          style:
                                              GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: const Color(
                                                0xFF1B3A1F),
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          'Login to continue your green journey',
                                          style:
                                              GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(
                                                    0xFF3A5C3F)
                                                .withOpacity(0.85),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // EMAIL

                                        _GlassInputField(
                                          controller:
                                              _emailController,
                                          hint: 'Email Address',
                                          prefixIcon:
                                              Icons.email_outlined,
                                          keyboardType:
                                              TextInputType
                                                  .emailAddress,
                                        ),

                                        const SizedBox(height: 14),

                                        // PASSWORD

                                        _GlassInputField(
                                          controller:
                                              _passwordController,
                                          hint: 'Password',
                                          prefixIcon: Icons
                                              .lock_outline_rounded,
                                          obscureText:
                                              _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color:
                                                  const Color(
                                                      0xFF5A8A5E),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Align(
                                          alignment:
                                              Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {},
                                            child: Text(
                                              'Forgot Password?',
                                              style:
                                                  GoogleFonts
                                                      .poppins(
                                                fontSize: 12.5,
                                                color:
                                                    const Color(
                                                        0xFF0B3D0D),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // LOGIN BUTTON

                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: DecoratedBox(
                                            decoration:
                                                BoxDecoration(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          14),
                                              gradient:
                                                  const LinearGradient(
                                                colors: [
                                                  Color(
                                                      0xFF2E7D32),
                                                  Color(
                                                      0xFF43A047),
                                                  Color(
                                                      0xFF388E3C),
                                                ],
                                              ),
                                            ),
                                            child: ElevatedButton(
                                              onPressed:
                                                  _isLoading
                                                      ? null
                                                      : _handleLogin,
                                              style:
                                                  ElevatedButton
                                                      .styleFrom(
                                                backgroundColor:
                                                    Colors
                                                        .transparent,
                                                shadowColor:
                                                    Colors
                                                        .transparent,
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color:
                                                            Colors
                                                                .white,
                                                        strokeWidth:
                                                            2.5,
                                                      ),
                                                    )
                                                  : Text(
                                                      'Login',
                                                      style:
                                                          GoogleFonts
                                                              .poppins(
                                                        fontSize:
                                                            16,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        color: Colors
                                                            .white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 22),

                                        // DIVIDER

                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.white
                                                    .withOpacity(
                                                        0.30),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 12,
                                              ),
                                              child: Text(
                                                'Continue with Google',
                                                style:
                                                    GoogleFonts
                                                        .poppins(
                                                  fontSize: 12,
                                                  color: Colors
                                                      .white
                                                      .withOpacity(
                                                          0.80),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.white
                                                    .withOpacity(
                                                        0.30),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20),

                                        // GOOGLE BUTTON ONLY

                                        Center(
                                          child:
                                              _SocialLoginButton(
                                            onTap: () {},
                                            child:
                                                Image.network(
                                              'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.contain,
                                              loadingBuilder:
                                                  (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress ==
                                                    null) {
                                                  return child;
                                                }

                                                return const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth:
                                                        2,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (
                                                _,
                                                __,
                                                ___,
                                              ) {
                                                return const Icon(
                                                  Icons
                                                      .g_mobiledata_rounded,
                                                  size: 28,
                                                  color: Color(
                                                      0xFFEA4335),
                                                );
                                              },
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // SIGNUP

                                        Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center,
                                            children: [
                                              Text(
                                                "Don't have an account? ",
                                                style:
                                                    GoogleFonts
                                                        .poppins(
                                                  fontSize: 13,
                                                  color: Colors
                                                      .white
                                                      .withOpacity(
                                                          0.85),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) =>
                                                              const SignupScreen(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Sign Up',
                                                  style:
                                                      GoogleFonts
                                                          .poppins(
                                                    fontSize:
                                                        13,
                                                    color:
                                                        const Color(
                                                            0xFFACF15D),
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── INPUT FIELD ─────────────────

class _GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _GlassInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6,
          sigmaY: 6,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1B3A1F),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5A8A5E)
                    .withOpacity(0.80),
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: const Color(0xFF5A8A5E),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────── GOOGLE BUTTON ─────────────────

class _SocialLoginButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4,
            sigmaY: 4,
          ),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.70),
                width: 1.2,
              ),
            ),
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}