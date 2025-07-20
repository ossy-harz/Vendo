import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // In a real app, these would be loaded from shared preferences or similar
    setState(() {
      _darkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }
  
  Future<void> _saveSettings() async {
    // In a real app, these would be saved to shared preferences or similar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Settings
          Text(
            'App Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark theme'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                    // In a real app, this would change the theme
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable push notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Location Services'),
                  subtitle: const Text('Enable location for nearby items'),
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Account Settings
          Text(
            'Account Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Change Password'),
                  leading: const Icon(Icons.lock_outline),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Privacy Settings'),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to privacy settings screen
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Payment Methods'),
                  leading: const Icon(Icons.payment_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to payment methods screen
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Support
          Text(
            'Support',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Help Center'),
                  leading: const Icon(Icons.help_outline),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to help center
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Contact Support'),
                  leading: const Icon(Icons.support_agent_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to contact support
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('About'),
                  leading: const Icon(Icons.info_outline),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to about screen
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          CustomButton(
            text: 'Save Settings',
            onPressed: _saveSettings,
          ),
          const SizedBox(height: 16),
          
          // Sign out button
          CustomButton(
            text: 'Sign Out',
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            backgroundColor: Colors.red.shade100,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }
}

