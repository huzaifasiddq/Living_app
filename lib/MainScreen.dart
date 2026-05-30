import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/Admin/ManageCommunityPostsScreen.dart';
import 'package:my_app/Screens/CarbonTrackerScreen.dart';
import 'package:my_app/Screens/CommunityScreen.dart';
import 'package:my_app/Screens/HomeScreen.dart';
import 'package:my_app/Screens/ProfileScreen.dart';
import 'package:my_app/Screens/WasteReductionTrackerScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<_NavItem> _navItems = const [
    _NavItem(
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItem(
      label: 'Carbon',
      activeIcon: Icons.bar_chart_rounded,
      inactiveIcon: Icons.bar_chart_outlined,
    ),
    _NavItem(
      label: 'Waste',
      activeIcon: Icons.recycling_rounded,
      inactiveIcon: Icons.recycling_outlined,
    ),
    _NavItem(
      label: 'Community',
      activeIcon: Icons.group_rounded,
      inactiveIcon: Icons.group_outlined,
    ),
    _NavItem(
      label: 'Profile',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  late final List<Widget> _pages;

  final List<Color> _pageBgColors = const [
    Color(0xFFF0FAE8),
    Color(0xFFEAF4FF),
    Color(0xFFFFF8EE),
    Color(0xFFEEFFF5),
    Color(0xFFF8EEFF),
  ];

  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _selectedIndex);

    _pages = [
      HomeScreen(
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      CarbonTrackerScreen(onBackTap: () => _onTabTapped(0)),
      WasteReductionTrackerScreen(onBackTap: () => _onTabTapped(0)),
      CommunityScreen(onBackTap: () => _onTabTapped(0)),
      ProfileScreen(onBackTap: () => _onTabTapped(0)),
    ];
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

  void _openDrawerPage(int index) {
    Navigator.pop(context);
    _onTabTapped(index);
  }

  void _openRoute(String routeName) {
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBgColors[_selectedIndex],
      extendBody: true,
      drawer: AppDrawer(
        onPageSelected: _openDrawerPage,
        onRouteSelected: _openRoute,
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            color: _pageBgColors[_selectedIndex],
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),
        ],
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

class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onPageSelected;
  final ValueChanged<String> onRouteSelected;

  const AppDrawer({
    super.key,
    required this.onPageSelected,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF3FBF1),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF43A047),
                    Color(0xFF66BB6A),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF2E7D32),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'EcoSphere',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Sustainable Living Guide',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.white.withOpacity(0.88),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            _drawerItem(
              icon: Icons.home_rounded,
              title: 'Home',
              onTap: () => onPageSelected(0),
            ),
            _drawerItem(
              icon: Icons.co2_rounded,
              title: 'Carbon Footprint Tracker',
              onTap: () => onPageSelected(1),
            ),
            _drawerItem(
              icon: Icons.recycling_rounded,
              title: 'Waste Reduction Tracker',
              onTap: () => onPageSelected(2),
            ),
            _drawerItem(
              icon: Icons.groups_rounded,
              title: 'Community Forum',
              onTap: () => onPageSelected(3),
            ),
            _drawerItem(
              icon: Icons.person_rounded,
              title: 'Profile',
              onTap: () => onPageSelected(4),
            ),

            const Divider(height: 22),

            _drawerItem(
              icon: Icons.shopping_bag_rounded,
              title: 'Eco Products',
              onTap: () => onRouteSelected('/ecoProducts'),
              isRoute: true,
            ),
            _drawerItem(
              icon: Icons.restaurant_rounded,
              title: 'Sustainable Recipes',
              onTap: () => onRouteSelected('/recipes'),
              isRoute: true,
            ),
            _drawerItem(
              icon: Icons.emoji_events_rounded,
              title: 'Green Challenges',
              onTap: () => onRouteSelected('/challenges'),
              isRoute: true,
            ),
            _drawerItem(
              icon: Icons.menu_book_rounded,
              title: 'Educational Content',
              onTap: () => onRouteSelected('/education'),
              isRoute: true,
            ),
            _drawerItem(
              icon: Icons.flight_takeoff_rounded,
              title: 'Eco Travel',
              onTap: () => onRouteSelected('/ecoTravel'),
              isRoute: true,
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Small steps, big impact 🌿',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isRoute = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF2E7D32)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1B5E20),
        ),
      ),
      trailing: Icon(
        isRoute ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
        color: const Color(0xFF66BB6A),
        size: 17,
      ),
      onTap: onTap,
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
