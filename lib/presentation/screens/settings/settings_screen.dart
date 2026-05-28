import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/presentation/providers/theme_provider.dart';
import 'package:byure/presentation/widgets/mesh_gradient_background.dart';
import 'package:byure/core/theme/app_theme.dart';

import 'package:byure/services/user_service.dart';
import 'package:byure/domain/entities/user_entity.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final UserService _userService = UserService();
  UserEntity? _user;
  double _searchRadius = 10.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final user = await _userService.getUserById(currentUser.id);
      setState(() {
        _user = user;
        _searchRadius = user?.walkingPreferences.searchRadiusKm ?? 10.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSearchRadius(double value) async {
    if (_user == null) return;
    
    final updatedUser = _user!.copyWith(
      walkingPreferences: _user!.walkingPreferences.copyWith(
        searchRadiusKm: value,
      ),
    );
    
    try {
      await _userService.updateUser(updatedUser);
      setState(() {
        _user = updatedUser;
        _searchRadius = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: MeshGradientBackground(
        isDark: themeMode == ThemeMode.dark,
        child: ListView(
          children: [
            // Account section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.push('/profile/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Safety'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon')),
                );
              },
            ),
            
            // Discovery Settings
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Discovery',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search Radius',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${_searchRadius.toInt()} km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _searchRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppTheme.primaryGreen,
                    label: '${_searchRadius.toInt()} km',
                    onChanged: (value) {
                      setState(() => _searchRadius = value);
                    },
                    onChangeEnd: (value) {
                      _saveSearchRadius(value);
                    },
                  ),
                  Text(
                    'Find walking buddies within this distance',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // App settings
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Theme'),
              subtitle: Text(themeMode == ThemeMode.dark
                  ? 'Dark'
                  : themeMode == ThemeMode.light
                      ? 'Light'
                  : 'Light'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showThemeDialog(context, themeMode, themeNotifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon')),
                );
              },
            ),
            // Subscription
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('GuzoMate+'),
              subtitle: const Text('Upgrade to premium'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.push('/paywall');
              },
            ),
            // Support
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Support',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help center coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'GuzoMate',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Walk Together, Connect Forever',
                );
              },
            ),

            // Developer Tools removed for production

            // Sign out
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _handleSignOut(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    ThemeMode currentMode,
    ThemeModeNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  notifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  notifier.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            // Removed System option as per user request to avoid glitches
          ],

        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (context.mounted) {
        context.go('/auth/login');
      }
    }
  }
}


