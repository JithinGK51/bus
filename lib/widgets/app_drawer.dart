import 'package:flutter/material.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'package:appwrite/appwrite.dart';
import 'package:provider/provider.dart';
import 'package:ksrtc_users/providers/theme_provider.dart';
import 'package:ksrtc_users/screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final Client client;
  final Function(int) onPageChange;
  final int currentIndex;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  const AppDrawer({
    super.key,
    required this.client,
    required this.onPageChange,
    required this.currentIndex,
    required this.onLogout,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildNavItem(
            context: context,
            icon: Icons.map,
            title: 'Map',
            index: 0,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.directions_bus,
            title: 'All Buses',
            index: 1,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.favorite,
            title: 'Favorites',
            index: 2,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.notifications,
            title: 'Alerts',
            index: 3,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person,
            title: 'Profile',
            index: 4,
          ),
          const Divider(),
          _buildThemeToggle(context),
          _buildSettingsItem(context),
          _buildHelpItem(context),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Builder(
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
        final isDarkMode = themeProvider.isDarkMode;

        return DrawerHeader(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkSurface : AppTheme.primaryYellow,
          ),
          child: Stack(
            children: [
              // Close button positioned further down on the right side
              Positioned(
                top: 50,
                right: 8,
                child: _build3DCloseButton(context, isDarkMode),
              ),
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namma Tumkuru',
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppTheme.darkPrimaryText
                              : AppTheme.primaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'City Bus Transport',
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppTheme.darkSecondaryText
                              : AppTheme.primaryDark,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white : Colors.black)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'User Account',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppTheme.darkPrimaryText
                                : AppTheme.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
  }) {
    return Builder(
      builder: (BuildContext builderContext) {
        final isSelected = currentIndex == index;
        final themeProvider = Provider.of<ThemeProvider>(builderContext);
        final isDarkMode = themeProvider.isDarkMode;

        return ListTile(
          leading: Icon(
            icon,
            color:
                isSelected
                    ? AppTheme.primaryYellow
                    : isDarkMode
                    ? AppTheme.darkPrimaryText
                    : AppTheme.textDark,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected
                      ? AppTheme.primaryYellow
                      : isDarkMode
                      ? AppTheme.darkPrimaryText
                      : AppTheme.textDark,
            ),
          ),
          onTap: () {
            onPageChange(index);
            Navigator.pop(context);
          },
          selected: isSelected,
          selectedTileColor: (isDarkMode
                  ? Colors.white
                  : AppTheme.primaryYellow)
              .withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      },
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Builder(
      builder: (BuildContext builderContext) {
        final themeProvider = Provider.of<ThemeProvider>(builderContext);
        final isDarkMode = themeProvider.isDarkMode;

        return SwitchListTile(
          title: Text(
            'Dark Mode',
            style: TextStyle(
              color: isDarkMode ? AppTheme.darkPrimaryText : AppTheme.textDark,
            ),
          ),
          secondary: Icon(
            isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: isDarkMode ? AppTheme.darkPrimaryText : AppTheme.textDark,
          ),
          value: isDarkMode,
          activeColor: AppTheme.primaryYellow,
          onChanged: (_) => onToggleTheme(),
        );
      },
    );
  }

  Widget _buildSettingsItem(BuildContext context) {
    return Builder(
      builder: (BuildContext builderContext) {
        final themeProvider = Provider.of<ThemeProvider>(builderContext);
        final isDarkMode = themeProvider.isDarkMode;

        return ListTile(
          leading: Icon(
            Icons.settings,
            color: isDarkMode ? AppTheme.darkPrimaryText : AppTheme.textDark,
          ),
          title: Text(
            'Settings',
            style: TextStyle(
              color: isDarkMode ? AppTheme.darkPrimaryText : AppTheme.textDark,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildHelpItem(BuildContext context) {
    return Builder(
      builder: (BuildContext builderContext) {
        final themeProvider = Provider.of<ThemeProvider>(builderContext);
        final isDarkMode = themeProvider.isDarkMode;

        return ListTile(
          leading: Icon(
            Icons.help,
            color: isDarkMode ? AppTheme.darkPrimaryText : AppTheme.textDark,
          ),
          title: Text(
            'Help & Support',
            style: TextStyle(
              color: isDarkMode ? AppTheme.darkPrimaryText : AppTheme.textDark,
            ),
          ),
          onTap: () {
            // TODO: Navigate to help screen
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Builder(
      builder: (BuildContext builderContext) {
        return ListTile(
          leading: Icon(Icons.logout, color: AppTheme.accentRed),
          title: Text('Logout', style: TextStyle(color: AppTheme.accentRed)),
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: AppTheme.accentRed),
                        ),
                      ),
                    ],
                  ),
            );
          },
        );
      },
    );
  }

  // 3D close button for the drawer
  Widget _build3DCloseButton(BuildContext context, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.85),
            boxShadow: [
              // Subtle shadow for 3D effect
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
              // Subtle highlight for 3D effect
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, -1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.close_rounded,
              color:
                  isDarkMode ? AppTheme.darkPrimaryText : AppTheme.primaryDark,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
