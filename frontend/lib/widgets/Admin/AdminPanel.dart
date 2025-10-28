import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/Admin/AdminDashboard.dart';
import 'package:frontend/widgets/Admin/AdminQuestions.dart';
import 'package:frontend/widgets/Admin/AdminUsersPage.dart';
import 'package:frontend/widgets/Admin/AdminStoriesPage.dart';
import 'package:frontend/widgets/Admin/FlagsAdminPage.dart';
import 'package:frontend/widgets/NotificationCenter.dart';
import 'AddStoryPage.dart';
import 'package:frontend/widgets/Admin/AdminLessons/AdminLessonsPage.dart';
import 'package:frontend/widgets/Admin/AdminLessons/AddLessonPage.dart';

// Navigation Item Model
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String? route;
  final List<NavigationItem>? subItems;

  NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
    this.subItems,
  });
}

// Main Admin Panel Widget
class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentRoute = '/admin/dashboard';
  final Set<String> _expandedItems = {};

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/admin/dashboard',
    ),
    NavigationItem(
      id: 'users',
      label: 'Users',
      icon: Icons.people_outline,
      route: '/admin/users',
    ),
    NavigationItem(
      id: 'questions',
      label: 'Questions & Answers',
      icon: Icons.help_outline,
      route: '/admin/questions',
    ),
    /*  NavigationItem(
      id: 'lessons',
      label: 'Lessons',
      icon: Icons.menu_book_outlined,
      subItems: [
        NavigationItem(
          id: 'all-lessons',
          label: 'All Lessons',
          icon: Icons.book,
          route: '/admin/lessons',
        ),
        NavigationItem(
          id: 'add-lesson',
          label: 'Add Lesson',
          icon: Icons.add_box,
          route: '/admin/lessons/add',
        ),
        ),
      ],
    ), */
    NavigationItem(
      id: 'stories',
      label: 'Revert Stories',
      icon: Icons.brightness_6_outlined,
      subItems: [
        NavigationItem(
          id: 'all-stories',
          label: 'All Stories',
          icon: Icons.brightness_6_outlined,
          route: '/admin/stories',
        ),
        NavigationItem(
          id: 'add-story',
          label: 'Add New',
          icon: Icons.add,
          route: '/admin/stories/add',
        ),
      ],
    ),
    /* NavigationItem(
      id: 'mosques',
      label: 'Mosques',
      icon: Icons.location_city,
      route: '/admin/mosques',
    ), */
    NavigationItem(
      id: 'lessons',
      label: 'Lessons ',
      icon: Icons.book,
      subItems: [
        NavigationItem(
          id: 'all-lessons',
          label: 'All Lessons',
          icon: Icons.book,
          route: '/admin/lessons',
        ),
        NavigationItem(
          id: 'add-lesson',
          label: 'Add New',
          icon: Icons.add,
          route: '/admin/lessons/add',
        ),
      ],
    ),
    NavigationItem(
      id: 'flags',
      label: 'Flags / Reports',
      icon: Icons.flag_outlined,
      route: '/admin/flags',
    ),

    NavigationItem(
      id: 'notifications',
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      route: '/admin/notifications',
    ),
    /*  NavigationItem(
      id: 'ai-insights',
      label: 'AI Insights',
      icon: Icons.psychology_outlined,
      subItems: [
        NavigationItem(
          id: 'user-interests',
          label: 'User Interests',
          icon: Icons.interests,
          route: '/admin/ai-insights/interests',
        ),
        NavigationItem(
          id: 'related-content',
          label: 'Related Content',
          icon: Icons.link,
          route: '/admin/ai-insights/content',
        ),
        NavigationItem(
          id: 'user-matching',
          label: 'User Matching',
          icon: Icons.people_alt,
          route: '/admin/ai-insights/matching',
        ),
      ],
    ), */
    /* NavigationItem(
      id: 'analytics',
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      subItems: [
        NavigationItem(
          id: 'user-analytics',
          label: 'Users',
          icon: Icons.bar_chart,
          route: '/admin/analytics/users',
        ),
        NavigationItem(
          id: 'question-analytics',
          label: 'Questions',
          icon: Icons.bar_chart,
          route: '/admin/analytics/questions',
        ),
        NavigationItem(
          id: 'lesson-analytics',
          label: 'Lessons',
          icon: Icons.bar_chart,
          route: '/admin/analytics/lessons',
        ),
        NavigationItem(
          id: 'story-analytics',
          label: 'Stories',
          icon: Icons.bar_chart,
          route: '/admin/analytics/stories',
        ),
      ],
    ),
    NavigationItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: '/admin/settings',
      route: '/admin/settings',
    ), */
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.islamicGreen50,
      drawer: _buildMobileDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1024;

          if (isMobile) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.adminPanelGreen50,
            AppColors.adminPanelCream,
            AppColors.adminPanelGold50,
          ],
        ),
      ),
      child: Row(
        children: [
          // Fixed Sidebar
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppColors.islamicWhite.withOpacity(0.95),
              border: const Border(
                right: BorderSide(
                  color: AppColors.adminPanelGreen200,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildSidebarContent(),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [_buildTopBar(), Expanded(child: _buildMainContent())],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.adminPanelGreen50,
            AppColors.adminPanelCream,
            AppColors.adminPanelGold50,
          ],
        ),
      ),
      child: Column(
        children: [_buildTopBar(), Expanded(child: _buildMainContent())],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.adminPanelGreen200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.adminPanelGreen500,
                      AppColors.adminPanelGreen600,
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.adminPanelGreen200,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.adminPanelGreen800,
                      ),
                    ),
                    Text(
                      'Hidaya Management',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.adminPanelGreen600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Navigation
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: _navigationItems.map(_buildNavigationTile).toList(),
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.adminPanelGreen200, width: 1),
            ),
          ),
          child: _buildLogoutButton(),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppColors.islamicWhite,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.islamicWhite.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.adminPanelGreen200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Mobile menu button
            if (MediaQuery.of(context).size.width < 1024)
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu, color: AppColors.islamicGreen700),
              ),
            const SizedBox(width: 16),
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.islamicGreen800,
              ),
            ),
            const Spacer(),
            // Notifications Icon
            _buildNotificationsIcon(),
            const SizedBox(width: 16),
            _buildUserMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsIcon() {
    return Stack(
      children: [
        IconButton(
          onPressed: () => _navigateToRoute('/admin/notifications'),
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.islamicGreen700,
            size: 24,
          ),
          tooltip: 'Notifications',
        ),
        // Notification badge
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.islamicGreen500,
              child: const Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Admin',
              style: TextStyle(
                color: AppColors.islamicGreen700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.islamicGreen600,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            /*  const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 16),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(), */
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
      onSelected: _handleUserMenuAction,
    );
  }

  Widget _buildNavigationTile(NavigationItem item) {
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;
    final isExpanded = _expandedItems.contains(item.id);
    final isActive = _isItemActive(item);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _handleNavigationTap(item),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    isActive && !hasSubItems
                        ? AppColors.islamicGreen500
                        : isActive
                        ? AppColors.islamicGreen100
                        : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color:
                        isActive && !hasSubItems
                            ? Colors.white
                            : isActive
                            ? AppColors.islamicGreen800
                            : AppColors.islamicGreen700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            isActive && !hasSubItems
                                ? Colors.white
                                : isActive
                                ? AppColors.islamicGreen800
                                : AppColors.islamicGreen700,
                      ),
                    ),
                  ),
                  if (hasSubItems) ...[
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color:
                          isActive && !hasSubItems
                              ? Colors.white
                              : AppColors.islamicGreen600,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hasSubItems && isExpanded) ...[
          const SizedBox(height: 4),
          ...item.subItems!.map((subItem) => _buildSubNavigationTile(subItem)),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSubNavigationTile(NavigationItem item) {
    final isActive = _currentRoute == item.route;

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNavigationTap(item),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive ? AppColors.islamicGreen500 : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isActive ? Colors.white : AppColors.islamicGreen700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isActive ? Colors.white : AppColors.islamicGreen700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _handleLogout,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _getContentForRoute(_currentRoute),
    );
  }

  Widget _getContentForRoute(String route) {
    switch (route) {
      case '/admin/dashboard':
        return AdminDashboard();
      case '/admin/users':
        return AdminUsersPage();
      case '/admin/questions':
        return AdminQuestions();
      case '/admin/lessons':
        return AdminLessonsPage();
      case '/admin/lessons/add':
        return AddLessonPage();
      case '/admin/stories':
        return AdminStoriesPage(
          onNavigateToAddStory: () => _navigateToRoute('/admin/stories/add'),
        );
      case '/admin/stories/add':
        return AddStoryPage(
          onBackToStories: () => _navigateToRoute('/admin/stories'),
        );
      case '/admin/flags':
        return FlagsAdminPage();
      case '/admin/notifications':
        return NotificationCenter();
      default:
        return _buildPlaceholderPage(route);
    }
  }

  Widget _buildPlaceholderPage(String route) {
    final routeName = route.split('/').last.replaceAll('-', ' ').toUpperCase();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.islamicGreen100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction,
              size: 48,
              color: AppColors.islamicGreen600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            routeName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.islamicGreen800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This page is under construction',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _navigateToRoute('/admin/dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.islamicGreen600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  bool _isItemActive(NavigationItem item) {
    if (item.route == _currentRoute) return true;
    if (item.subItems != null) {
      return item.subItems!.any((subItem) => subItem.route == _currentRoute);
    }
    return false;
  }

  void _handleNavigationTap(NavigationItem item) {
    if (item.subItems != null && item.subItems!.isNotEmpty) {
      setState(() {
        if (_expandedItems.contains(item.id)) {
          _expandedItems.remove(item.id);
        } else {
          _expandedItems.add(item.id);
        }
      });
    } else if (item.route != null) {
      _navigateToRoute(item.route!);
    }

    // Close mobile drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToRoute(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  void _handleUserMenuAction(String action) {
    switch (action) {
      case 'settings':
        _navigateToRoute('/admin/settings');
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await AuthUtils.logout(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
