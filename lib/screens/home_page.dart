import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:provider/provider.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'package:ksrtc_users/widgets/bus_map.dart';
import 'package:ksrtc_users/widgets/bus_list.dart';
import 'package:ksrtc_users/widgets/all_bus_list.dart';
import 'package:ksrtc_users/screens/profile_screen.dart';
import 'package:ksrtc_users/widgets/custom_bottom_nav.dart';
import 'package:ksrtc_users/widgets/app_drawer.dart';
import 'package:ksrtc_users/providers/theme_provider.dart';
import 'package:ksrtc_users/widgets/drawer_helper.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  final Client client;
  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Global key for the scaffold to access drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Account account;
  bool _isLoading = true;
  int _currentIndex = 0;
  final GlobalKey<BusMapState> _mapKey = GlobalKey<BusMapState>();

  // Search animation controller
  late AnimationController _searchAnimController;
  late Animation<double> _searchAnimation;
  bool _isSearchVisible = false;

  // Search controller to share with AllBusList
  final TextEditingController _searchController = TextEditingController();

  // Focus node for search field
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    account = Account(widget.client);
    _loadUserData();

    // Initialize search animation controller
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _searchAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutBack,
    );

    // Add status listener for debugging
    _searchAnimController.addStatusListener((status) {
      print('Animation status changed: $status');
    });

    // Add value listener for debugging
    _searchAnimController.addListener(() {
      // Only print on significant changes to avoid console spam
      if (_searchAnimController.value % 0.25 < 0.01) {
        print('Animation value: ${_searchAnimController.value}');
      }
    });
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showSearchPanel() {
    print('===============================');
    print('SEARCH BUTTON CLICKED');
    print('Current visibility: $_isSearchVisible');
    print('Current animation value: ${_searchAnimController.value}');
    print('Current animation status: ${_searchAnimController.status}');

    // Force show search panel
    setState(() {
      _isSearchVisible = true;
    });
    print('New visibility state: $_isSearchVisible');

    print('Starting forward animation');
    // Reset animation before starting to ensure it plays from the beginning
    _searchAnimController.reset();
    _searchAnimController.forward();

    // Request focus only when explicitly opening the search panel
    _searchFocusNode.requestFocus();

    // Stay on current page - don't switch to All Buses tab
    print('Keeping current tab: $_currentIndex');
  }

  void _hideSearchPanel() {
    print('Hiding search animation');
    setState(() {
      _isSearchVisible = false;
    });

    // Remove focus to hide keyboard
    _searchFocusNode.unfocus();

    print('Starting reverse animation');
    _searchAnimController.reverse();

    // Add a slight delay before clearing the search to allow animation to complete
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isSearchVisible) {
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchAnimController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Helper method to get the current page name
  String _getPageName(int index) {
    switch (index) {
      case 0:
        return 'Map';
      case 1:
        return 'All Buses';
      case 2:
        return 'Favorites';
      case 3:
        return 'Alerts';
      case 4:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  // Helper method to get context-aware filters based on current page
  List<Widget> _getContextFilters(int index) {
    switch (index) {
      case 0: // Map
        return [
          _buildQuickFilter('Nearby'),
          _buildQuickFilter('Routes'),
          _buildQuickFilter('Stops'),
        ];
      case 1: // All Buses
        return [
          _buildQuickFilter('Express'),
          _buildQuickFilter('Local'),
          _buildQuickFilter('AC'),
        ];
      case 2: // Favorites
        return [
          _buildQuickFilter('Recent'),
          _buildQuickFilter('Frequent'),
          _buildQuickFilter('Saved'),
        ];
      case 3: // Alerts
        return [
          _buildQuickFilter('Delays'),
          _buildQuickFilter('Updates'),
          _buildQuickFilter('News'),
        ];
      case 4: // Profile
        return [
          _buildQuickFilter('History'),
          _buildQuickFilter('Bookings'),
          _buildQuickFilter('Settings'),
        ];
      default:
        return [
          _buildQuickFilter('Nearby'),
          _buildQuickFilter('Popular'),
          _buildQuickFilter('Recent'),
        ];
    }
  }

  // Helper method to build quick filter chips
  Widget _buildQuickFilter(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      await account.get();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Toggle theme mode
  void _toggleThemeMode() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  // Handle logout
  void _handleLogout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      if (mounted) {
        // Navigate to login screen and clear all previous routes
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to logout')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Define the pages
    final List<Widget> pages = [
      BusMap(key: _mapKey), // Home/Map
      AllBusList(
        externalSearchController: _searchController,
      ), // All Buses with search
      const BusList(), // Likes/Favorites
      Container(
        // Notifications/Alerts
        color: AppTheme.background,
        child: Center(
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
      ),
      ProfileScreen(client: widget.client), // Profile
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  // Unfocus any active text fields before opening drawer
                  FocusScope.of(context).unfocus();

                  // Show animated drawer instead of standard drawer
                  DrawerHelper.showAnimatedDrawer(
                    context: context,
                    drawer: Material(
                      child: AppDrawer(
                        client: widget.client,
                        currentIndex: _currentIndex,
                        onPageChange: _changePage,
                        onLogout: _handleLogout,
                        onToggleTheme: _toggleThemeMode,
                      ),
                    ),
                  );
                },
              ),
        ),
        title: const Text(
          'Namma Tumkuru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: AppTheme.accentRed),
            onPressed: () {
              // Show SOS dialog or navigate to SOS screen
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Emergency SOS'),
                      content: const Text(
                        'Do you want to send an emergency alert?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement SOS functionality
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Emergency alert sent!'),
                                backgroundColor: AppTheme.accentRed,
                              ),
                            );
                          },
                          child: const Text(
                            'Send Alert',
                            style: TextStyle(color: AppTheme.accentRed),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
        centerTitle: true,
        bottom:
            _currentIndex == 0
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: GestureDetector(
                      onTap: _showSearchPanel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: AppTheme.textDark.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Search for buses, routes, stops...',
                              style: TextStyle(
                                color: AppTheme.textDark.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                : null,
      ),
      body: Stack(
        children: [
          // Main content
          pages[_currentIndex],

          // Search overlay with 3D animation - only on home page
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              print(
                'Building search UI, visibility: $_isSearchVisible, animation: ${_searchAnimation.value}',
              );

              // Use visibility to control whether the widget is in the tree
              return Visibility(
                visible:
                    _isSearchVisible &&
                    _currentIndex == 0, // Only visible on home page
                maintainState: true,
                maintainAnimation: true,
                child: Positioned(
                  top:
                      kToolbarHeight +
                      60, // Position below app bar and search bar
                  left: 0,
                  right: 0,
                  child: Transform(
                    transform:
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspective effect
                          ..rotateX(
                            _searchAnimation.value * 0.05,
                          ), // Subtle rotation
                    alignment: Alignment.topCenter,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(_searchAnimation),
                      child: FadeTransition(
                        opacity: _searchAnimation,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              // Main shadow
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                              // Yellow top edge glow
                              BoxShadow(
                                color: AppTheme.primaryYellow.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, -2),
                              ),
                              // Inner shadow
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                spreadRadius: -3,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search title
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Search Buses',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  // Show current page indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryYellow.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getPageName(_currentIndex),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Search field with 3D effect
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  autofocus: false,
                                  decoration: InputDecoration(
                                    hintText: 'Enter bus route or destination',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: AppTheme.textDark,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: AppTheme.textDark,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Filter results and if on map page, switch to All Buses when user starts typing
                                    print('Search query changed: $value');

                                    // If user starts typing and we're on map page, switch to All Buses
                                    if (value.isNotEmpty &&
                                        _currentIndex == 0) {
                                      setState(() {
                                        _currentIndex =
                                            1; // Switch to All Buses tab
                                      });
                                    }
                                  },
                                ),
                              ),
                              // Quick filters based on current page
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: _getContextFilters(_currentIndex),
                                ),
                              ),
                              // Close button
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () => _hideSearchPanel(),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(
                                      color: AppTheme.primaryDark,
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
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: AppTheme.textDark,
                onPressed: () {
                  // Access the BusMap state through the key and call goToCurrentLocation
                  final mapState = _mapKey.currentState;
                  if (mapState != null) {
                    mapState.goToCurrentLocation();
                  }
                },
                child: const Icon(Icons.my_location),
              )
              : null,
      // Using custom animated drawer instead
      bottomNavigationBar: CustomBottomNavBarWithBadge(
        currentIndex: _currentIndex,
        onTap: _changePage,
        items: [
          const CustomNavItemWithBadge(icon: Icons.home, label: 'Map'),
          const CustomNavItemWithBadge(
            icon: Icons.directions_bus,
            label: 'All Buses',
          ),
          CustomNavItemWithBadge(
            icon: Icons.favorite,
            label: 'Likes',
            showBadge: _currentIndex != 2, // Show badge when not on this tab
            badgeCount: 2, // Example badge count
          ),
          const CustomNavItemWithBadge(
            icon: Icons.notifications,
            label: 'Alerts',
          ),
          const CustomNavItemWithBadge(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}
