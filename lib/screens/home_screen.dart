import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'chat_list_screen.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Enhancement 1/3: greeting comes from the persisted user, so it survives
  // an app restart without another login.
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService().getUser();
    if (!mounted) return;
    setState(() {
      _displayName = user.firstName.isNotEmpty ? user.firstName : user.username;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: _selectedIndex == 1
              ? const CustomText(
                  text: 'Cart',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                )
              : _selectedIndex == 2
              ? const CustomText(
                  text: 'Profile',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                )
              : CustomText(
                  text: _displayName.isEmpty ? 'Home' : _displayName,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
          children: const <Widget>[
            ProductScreen(),
            CartScreen(showAppBar: false),
            // Enhancement 3: the profile tab renders the saved user.
            ProfileScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton.small(
          tooltip: 'Open chats',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            );
          },
          child: const Icon(Icons.chat_bubble_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 18.w),
            height: 66.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () => _onTappedBar(0),
                  icon: Icon(
                    Icons.storefront_rounded,
                    color: _selectedIndex == 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Cart',
                  onPressed: () => _onTappedBar(1),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(48.r, 48.r),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.shopping_cart_rounded),
                ),
                IconButton(
                  onPressed: () => _onTappedBar(2),
                  icon: Icon(
                    Icons.person_rounded,
                    color: _selectedIndex == 2
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
