import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_app/Screens/HomeScreen.dart';
import 'package:my_app/Screens/ProfileScreen.dart';
// import 'package:my_app/Screens/TrackerScreen.dart';
// import 'package:my_app/Screens/CommunityScreen.dart';
// import 'package:my_app/Screens/RecipeScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<_NavItem> _navItems = const [
    _NavItem(
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItem(
      label: 'Track',
      activeIcon: Icons.bar_chart_rounded,
      inactiveIcon: Icons.bar_chart_outlined,
    ),
    _NavItem(
      label: 'Community',
      activeIcon: Icons.group_rounded,
      inactiveIcon: Icons.group_outlined,
    ),
    _NavItem(
      label: 'Recipe',
      activeIcon: Icons.eco_rounded,
      inactiveIcon: Icons.eco_outlined,
    ),
    _NavItem(
      label: 'Profile',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  final List<Widget> _pages = const [
    HomeScreen(),
    PlaceholderPage(title: 'Track'),
    PlaceholderPage(title: 'Community'),
    PlaceholderPage(title: 'Recipe'),
    ProfileScreen(),
  ];

  final List<Color> _pageBgColors = const [
    Color(0xFFF0FAE8),
    Color(0xFFEAF4FF),
    Color(0xFFFFF8EE),
    Color(0xFFEEFFF5),
    Color(0xFFF8EEFF),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBgColors[_selectedIndex],
      extendBody: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        color: _pageBgColors[_selectedIndex],
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _FloatingNavBar(
          selectedIndex: _selectedIndex,
          navItems: _navItems,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.navItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7BC043).withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            navItems.length,
            (i) => Flexible(
              child: _NavBarItem(
                item: navItems[i],
                isSelected: selectedIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapDown(_) => _controller.forward();

  void _tapUp(_) {
    _controller.reverse();
    widget.onTap();
  }

  void _tapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: widget.isSelected
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 7)
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: widget.isSelected
              ? BoxDecoration(
                  color: const Color(0xFFEEF8E8),
                  borderRadius: BorderRadius.circular(28),
                )
              : const BoxDecoration(color: Colors.transparent),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isSelected
                      ? widget.item.activeIcon
                      : widget.item.inactiveIcon,
                  size: widget.isSelected ? 19 : 18,
                  color: widget.isSelected
                      ? const Color(0xFF7BC043)
                      : const Color(0xFFADB5BD),
                ),

                if (widget.isSelected) ...[
                  const SizedBox(width: 3),

                  Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7BC043),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
