import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/Screens/SignupScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const EatcnobityApp());
}

class EatcnobityApp extends StatelessWidget {
  const EatcnobityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eatcnobity Dartome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SPLASH SCREEN
// ═══════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Whole screen fade-in ───────────────────────────────
  late final AnimationController _fadeInCtrl;
  late final Animation<double> _fadeInAnim;

  // ── Whole screen fade-out (exit) ───────────────────────
  late final AnimationController _exitCtrl;
  late final Animation<double> _exitAnim;

  // ── Title: slide down + fade ───────────────────────────
  late final AnimationController _titleCtrl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // ── Tagline: slide up + fade ───────────────────────────
  late final AnimationController _taglineCtrl;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  // ── Logo: scale + fade ─────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // ── Loading dots text ──────────────────────────────────
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();

    // Screen fade-in (0ms)
    _fadeInCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeInAnim =
        CurvedAnimation(parent: _fadeInCtrl, curve: Curves.easeIn);
    _fadeInCtrl.forward();

    // Title slide-down + fade (starts at 100ms)
    _titleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _titleFade =
        CurvedAnimation(parent: _titleCtrl, curve: Curves.easeIn);
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));
    Future.delayed(
        const Duration(milliseconds: 100), () { if (mounted) _titleCtrl.forward(); });

    // Tagline slide-up + fade (starts at 280ms)
    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _taglineFade =
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn);
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.50),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 280),
        () { if (mounted) _taglineCtrl.forward(); });

    // Logo scale + fade (starts at 350ms)
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoFade =
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.80, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    Future.delayed(const Duration(milliseconds: 350),
        () { if (mounted) _logoCtrl.forward(); });

    // Loading dots
    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();

    // Exit fade + navigate after 3s
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _exitAnim =
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;
      await _exitCtrl.forward();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const SignupScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeInCtrl.dispose();
    _titleCtrl.dispose();
    _taglineCtrl.dispose();
    _logoCtrl.dispose();
    _dotsCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitAnim,
      builder: (_, child) =>
          Opacity(opacity: 1.0 - _exitAnim.value, child: child!),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FadeTransition(
          opacity: _fadeInAnim,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Full-screen background image asset ───
              Image.asset(
                'assets/images/leaf_bg.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),

              // ── 2. Dark gradient overlay ─────────────────
              _buildGradientOverlay(),

              // ── 3. UI content ────────────────────────────
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  GRADIENT OVERLAY
  // ─────────────────────────────────────────────────────
  Widget _buildGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xD90D2016), // dark top — title readable
            Color(0x661A4A2E), // semi-transparent upper-mid
            Color(0x111A4A2E), // nearly clear center — image shows
            Color(0x771A4A2E), // semi-dark lower-mid
            Color(0xF00D2016), // very dark bottom — loader readable
          ],
          stops: [0.0, 0.20, 0.48, 0.72, 1.0],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  ALL UI CONTENT
  // ─────────────────────────────────────────────────────
  Widget _buildContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 44),

          // Title
          SlideTransition(
            position: _titleSlide,
            child: FadeTransition(
              opacity: _titleFade,
              child: _buildTitle(),
            ),
          ),

          const SizedBox(height: 10),

          // Tagline
          SlideTransition(
            position: _taglineSlide,
            child: FadeTransition(
              opacity: _taglineFade,
              child: _buildTagline(),
            ),
          ),

          const Spacer(),

          // Center logo from asset
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: _buildLogo(),
            ),
          ),

          const Spacer(),

          // Bottom loading indicator
          _buildLoader(),

          const SizedBox(height: 52),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  TITLE
  // ─────────────────────────────────────────────────────
  Widget _buildTitle() {
    const style = TextStyle(
      fontFamily: 'Georgia',
      fontSize: 44,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.18,
      letterSpacing: 0.3,
      shadows: [
        Shadow(
          color: Color(0xAA000000),
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
        Shadow(
          color: Color(0x4452B788),
          blurRadius: 36,
        ),
      ],
    );
    return Column(
      children: [
        Text('Eatcnobity', style: style, textAlign: TextAlign.center),
        Text('Dartome', style: style, textAlign: TextAlign.center),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  TAGLINE
  // ─────────────────────────────────────────────────────
  Widget _buildTagline() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dash(),
        const SizedBox(width: 10),
        Text(
          'Nurturing Your Sustainable Life',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            color: Colors.white.withOpacity(0.88),
            letterSpacing: 0.5,
            shadows: const [
              Shadow(color: Color(0x88000000), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _dash(),
      ],
    );
  }

  Widget _dash() => Container(
        width: 22,
        height: 1.0,
        color: Colors.white.withOpacity(0.50),
      );

  // ─────────────────────────────────────────────────────
  //  LOGO — local asset image only
  // ─────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52B788).withOpacity(0.40),
            blurRadius: 55,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  LOADING INDICATOR
  // ─────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF81C784),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _dotsCtrl,
          builder: (_, __) {
            final dotCount = (_dotsCtrl.value * 3).floor() + 1;
            return Text(
              'Loading${'.' * dotCount}',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13,
                letterSpacing: 2.2,
                color: Colors.white.withOpacity(0.60),
                shadows: const [
                  Shadow(color: Color(0x88000000), blurRadius: 6),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}


