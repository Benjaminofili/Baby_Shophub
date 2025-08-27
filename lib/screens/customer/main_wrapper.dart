// Updated lib/screens/main_wrapper.dart
import 'package:flutter/material.dart';
import '../../components/bottom_nav_bar.dart';
import 'Home.dart';
import 'categories.dart';
import 'favorites.dart';
import 'shopping.dart'; // Import the shopping cart
import 'profile.dart'; // Import profile page

class MainWrapperPage extends StatefulWidget {
  final int initialIndex;

  const MainWrapperPage({super.key, this.initialIndex = 0});

  @override
  State<MainWrapperPage> createState() => _MainWrapperPageState();
}

class _MainWrapperPageState extends State<MainWrapperPage> {
  late int _selectedIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          const HomePageContent(), // Home page content
          const CategoriesPage(), // Categories page
          const FavoritesPage(), // Favorites page
          CartPageContent(), // Cart page content with your shopping cart
          const ProfilePage(), // Profile page
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Home Page Content (without bottom nav)
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageDemo();
  }
}

// Cart Page Content using your ShoppingCart widget
class CartPageContent extends StatelessWidget {
  const CartPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ShoppingCart(); // Use your existing shopping cart widget
  }
}
