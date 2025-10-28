// lib/widgets/responsive_layout.dart
import 'package:flutter/material.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:frontend/widgets/PrayerTimesWidget.dart';
import 'package:frontend/widgets/Qustions.dart';
import 'package:frontend/widgets/Welcomingpage.dart';
import 'HomePage.dart';
import 'LessonsPage.dart';
import 'ProfilePage.dart';
import 'package:provider/provider.dart';
import '../providers/NavigationProvider.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/Stories/Story.dart';
import 'NearbyMosquesPage.dart';
import 'package:frontend/widgets/chat/chat_list.dart';
import 'package:frontend/services/stream_chat_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ResponsiveLayout extends StatefulWidget {
  final String userRole;

  const ResponsiveLayout({Key? key, this.userRole = 'user'}) : super(key: key);

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      id: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      page: ChangeNotifierProvider(
        create: (_) => OnboardingProvider(),
        child: const OnboardingPage(),
      ),
    ),
    NavigationItem(
      id: 'onboarding',
      label: 'AI Chat',
      icon: Icons.chat,
      activeIcon: Icons.chat,
      page: HomePage(),
    ),
    NavigationItem(
      id: 'ask',
      label: 'Ask',
      icon: Icons.help_outline,
      activeIcon: Icons.help,
      page: Questions(initialTabIndex: 0),
    ),
    NavigationItem(
      id: 'hidayaStories',
      label: 'Hidaya Stories',
      icon: Icons.brightness_6_outlined,
      activeIcon: Icons.brightness_6,
      page: StoriesPage(),
    ),
    NavigationItem(
      id: 'lessons',
      label: 'Lessons',
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      page: LessonsPage(),
    ),
    NavigationItem(
      id: 'nearbyMosques',
      label: 'Nearby Mosques',
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on,
      page: NearbyMosquesPage(),
    ),
    NavigationItem(
      id: 'chat',
      label: 'Chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      page: _ChatPage(),
    ),
    NavigationItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      page: ProfilePage(),
    ),
  ];

  final List<AdminMenuItem> _adminMenuItems = [
    AdminMenuItem(
      id: 'dashboard',
      label: 'Admin Dashboard',
      icon: Icons.dashboard,
    ),
    AdminMenuItem(
      id: 'flagged',
      label: 'Review Flagged Answers',
      icon: Icons.flag,
    ),
    AdminMenuItem(
      id: 'promote',
      label: 'Promote Volunteers',
      icon: Icons.person_add,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    // Listen to NavigationProvider for main tab changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      navProvider.addListener(() {
        if (_selectedIndex != navProvider.mainTabIndex) {
          _onTabSelected(navProvider.mainTabIndex);
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _handleAdminAction(String actionId) async {
    switch (actionId) {
      case 'dashboard':
        print('Navigate to Admin Dashboard');
        break;
      case 'flagged':
        print('Review Flagged Answers');
        break;
      case 'promote':
        print('Promote Volunteers');
        break;
      case 'logout':
        await AuthUtils.logout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("ResponsiveLayout is being built!");
    final navProvider = Provider.of<NavigationProvider>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Scaffold(
            body: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children:
                      _navigationItems.asMap().entries.map((entry) {
                        final item = entry.value;
                        if (item.id == 'ask') {
                          return Questions(
                            initialTabIndex: navProvider.questionsTabIndex,
                          );
                        }
                        return item.page;
                      }).toList(),
                ),

                // Admin Floating Action Button
                if (widget.userRole == 'admin')
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: _buildAdminFAB(),
                  ),

                // Prayer Times Widget - Fixed at bottom right
                if (_navigationItems[_selectedIndex].id != "home")
                  const PrayerTimesWidget(),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigation(),
          );
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    final navProvider = Provider.of<NavigationProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.islamicGreen50,
                  AppColors.islamicCream,
                  AppColors.islamicGold50,
                ],
              ),
            ),
            child: Row(
              children: [
                // Side Navigation
                _buildSideNavigation(),

                // Main Content
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      children:
                          _navigationItems.asMap().entries.map((entry) {
                            final item = entry.value;
                            if (item.id == 'ask') {
                              return Questions(
                                initialTabIndex: navProvider.questionsTabIndex,
                              );
                            }
                            return item.page;
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Prayer Times Widget - Fixed at bottom right for desktop
          if (_navigationItems[_selectedIndex].id != "home")
            const PrayerTimesWidget(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.islamicWhite.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: AppColors.islamicGreen200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          child: Row(
            children:
                _navigationItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  NavigationItem item = entry.value;
                  bool isActive = _selectedIndex == index;

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onTabSelected(index),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: isActive ? 1.1 : 1.0,
                                    duration: Duration(milliseconds: 200),
                                    child: Icon(
                                      isActive ? item.activeIcon : item.icon,
                                      size: 24,
                                      color:
                                          isActive
                                              ? AppColors.islamicGreen700
                                              : AppColors.islamicGreen400,
                                    ),
                                  ),
                                  if (isActive)
                                    Positioned(
                                      bottom: -2,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.islamicGreen700,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isActive
                                          ? AppColors.islamicGreen800
                                          : AppColors.islamicGreen500,
                                ),
                                child: Text(item.label),
                              ),
                              if (isActive)
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  width: 48,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.islamicGreen600,
                                        AppColors.islamicGreen700,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.islamicWhite.withOpacity(0.95),
        border: Border(
          right: BorderSide(color: AppColors.islamicGreen200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.islamicGreen200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.islamicGreen600,
                        AppColors.islamicGreen700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.islamicGreen600.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(Icons.security, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hidaya',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.islamicGreen900,
                      ),
                    ),
                    Text(
                      'هداية - Guidance in Faith',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.islamicGreen700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  // Main Navigation
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        final isActive = _selectedIndex == index;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onTabSelected(index),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isActive
                                          ? AppColors.islamicGreen600
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow:
                                      isActive
                                          ? [
                                            BoxShadow(
                                              color: AppColors.islamicGreen600
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedScale(
                                      scale: isActive ? 1.1 : 1.0,
                                      duration: Duration(milliseconds: 200),
                                      child: Icon(
                                        isActive ? item.activeIcon : item.icon,
                                        size: 22,
                                        color:
                                            isActive
                                                ? AppColors.islamicWhite
                                                : AppColors.islamicGreen800,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isActive
                                                ? AppColors.islamicWhite
                                                : AppColors.islamicGreen800,
                                      ),
                                    ),
                                    if (isActive)
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                        );
                      },
                    ),
                  ),

                  // Admin Section
                  if (widget.userRole == 'admin') ...[
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      height: 1,
                      color: AppColors.islamicGreen200,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.islamicGreen800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._adminMenuItems
                        .map(
                          (item) => Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _handleAdminAction(item.id),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: AppColors.islamicGreen700,
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.islamicGreen700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ],
              ),
            ),
          ),

          // Logout Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.islamicGreen200, width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _handleAdminAction('logout'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red[600]),
                      SizedBox(width: 16),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
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

  Widget _buildAdminFAB() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.islamicWhite.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.islamicGreen200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showAdminBottomSheet(),
          child: Container(
            width: 40,
            height: 40,
            child: Icon(Icons.menu, color: AppColors.islamicGreen800, size: 20),
          ),
        ),
      ),
    );
  }

  void _showAdminBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: AppColors.islamicWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.islamicGreen200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.islamicGreen600,
                                AppColors.islamicGreen700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.islamicWhite,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.islamicGreen900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ..._adminMenuItems
                        .map(
                          (item) => ListTile(
                            leading: Icon(
                              item.icon,
                              color: AppColors.islamicGreen700,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.islamicGreen700,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _handleAdminAction(item.id);
                            },
                          ),
                        )
                        .toList(),
                    Divider(color: AppColors.islamicGreen200),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red[600]),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleAdminAction('logout');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

// Supporting Classes
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

class AdminMenuItem {
  final String id;
  final String label;
  final IconData icon;

  AdminMenuItem({required this.id, required this.label, required this.icon});
}

class _ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  StreamChatService? _chatService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final service = await StreamChatService.initialize(context);
      if (mounted) {
        setState(() {
          _chatService = service;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chatService == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Failed to load chat'),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _initializeChat, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RestorationScope(
      restorationId: 'main_chat',
      child: StreamChat(
        client: _chatService!.client,
        child: ChatListScreen(
          client: _chatService!.client,
          streamService: _chatService,
        ),
      ),
    );
  }
}
