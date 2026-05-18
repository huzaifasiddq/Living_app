import 'package:flutter/material.dart';

void main() {
  runApp(const SustainableLivingApp());
}

class SustainableLivingApp extends StatelessWidget {
  const SustainableLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sustainable Living Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        fontFamily: 'Georgia',
      ),
      home: const SignupScreen(),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── TOP HERO SECTION ──────────────────────────────────────
              _HeroSection(),

              // ── WHITE CARD FORM SECTION ───────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Heading
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Decorative leaf divider
                      _LeafDivider(),

                      const SizedBox(height: 28),

                      // Full Name
                      _EcoTextField(
                        controller: _fullNameController,
                        hint: 'Full Name',
                        prefixIcon: Icons.person_outline,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _EcoTextField(
                        controller: _emailController,
                        hint: 'Email Address',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _EcoTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF66BB6A),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      _EcoTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF66BB6A),
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Create Account Button
                      _GradientButton(
                        label: 'Create Account',
                        onPressed: () {
                          // Handle account creation
                        },
                      ),

                      const SizedBox(height: 24),

                      // "or continue with" divider
                      _OrDivider(),

                      const SizedBox(height: 20),

                      // Social Login Row
                      _SocialLoginRow(),

                      const SizedBox(height: 28),

                      // Footer
                      _SignInFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB8E6A0), // light mint green
            Color(0xFF81C784), // medium green
            Color(0xFF66BB6A), // deeper green → blends into card
          ],
        ),
      ),
      child: Column(
        children: [
          // Glowing globe ambience
          Stack(
            alignment: Alignment.center,
            children: [
              // Soft glow ring
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              // App icon card
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: _GlobeLeafIcon(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Sustainable\nLiving Guide',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            'Small steps today, a better\ntomorrow for all.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: const Color(0xFF2E7D32).withOpacity(0.85),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOBE + LEAF ICON (drawn with widgets, no external assets needed)
// ─────────────────────────────────────────────────────────────────────────────
class _GlobeLeafIcon extends StatelessWidget {
  const _GlobeLeafIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Globe circle
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF29B6F6), Color(0xFF0277BD)],
            ),
          ),
        ),
        // Leaf overlay
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF43A047),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco,
              size: 13,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEAF DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _LeafDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 1,
          color: const Color(0xFFAED581).withOpacity(0.6),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.eco,
            size: 16,
            color: Color(0xFF66BB6A),
          ),
        ),
        Container(
          width: 40,
          height: 1,
          color: const Color(0xFFAED581).withOpacity(0.6),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ECO TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _EcoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _EcoTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF2E2E2E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14.5,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF66BB6A),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FBF9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFA5D6A7).withOpacity(0.6),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF43A047),
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.eco, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Create Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OR DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
            endIndent: 12,
          ),
        ),
        Text(
          'or continue with',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
            indent: 12,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL LOGIN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _SocialLoginRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SocialButton(label: 'G', color: const Color(0xFFEA4335))),
        const SizedBox(width: 12),
        Expanded(child: _SocialButton(label: '', icon: Icons.apple, color: Colors.black)),
        const SizedBox(width: 12),
        Expanded(child: _SocialButton(label: 'f', color: const Color(0xFF1877F2))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _SocialButton({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
        backgroundColor: Colors.white,
      ),
      child: icon != null
          ? Icon(icon, color: color, size: 22)
          : Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN IN FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _SignInFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to Sign In
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'Already have an account? ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          children: const [
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}