import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendo/screens/payment/payment_methods_screen.dart';
import 'package:vendo/screens/verification/verification_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'analytics/user_analytics_screen.dart';
import 'auth/login_screen.dart';
import 'dashboard/my_listings_screen.dart';
import 'transaction/transaction_list_screen.dart';
import 'settings/settings_screen.dart';
import 'wishlist/wishlist_screen.dart';
import 'location/nearby_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileData = await authService.getUserProfile();

      if (mounted) {
        setState(() {
          _profileData = profileData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
          ? const Center(child: Text('Failed to load profile'))
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: _profileData!['photoUrl'] != null && _profileData!['photoUrl'].isNotEmpty
                    ? NetworkImage(_profileData!['photoUrl'])
                    : null,
                child: _profileData!['photoUrl'] == null || _profileData!['photoUrl'].isEmpty
                    ? Icon(
                  Icons.person,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                _profileData!['name'] ?? 'User',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),

              // Email
              Text(
                _profileData!['email'] ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),

              // Verification badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _profileData!['isVerified'] == true
                        ? Icons.verified
                        : Icons.verified_outlined,
                    color: _profileData!['isVerified'] == true
                        ? Colors.blue
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _profileData!['isVerified'] == true
                        ? 'Verified Account'
                        : 'Not Verified',
                    style: TextStyle(
                      color: _profileData!['isVerified'] == true
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                  if (_profileData!['isVerified'] != true) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserVerificationScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                      child: const Text('Verify Now'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Listings', '0'),
                  _buildStatColumn('Sold', '0'),
                  _buildStatColumn('Bought', '0'),
                ],
              ),
              const SizedBox(height: 24),

              // Profile sections
              _buildProfileSection(
                'My Listings',
                Icons.list_alt_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyListingsScreen()),
                  );
                },
              ),
              _buildProfileSection(
                'Wishlist',
                Icons.favorite_border,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                },
              ),
              _buildProfileSection(
                'Transactions',
                Icons.receipt_long_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionListScreen()),
                  );
                },
              ),
              _buildProfileSection(
                'Payment Methods',
                Icons.payment_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                  );
                },
              ),
              _buildProfileSection(
                'Analytics',
                Icons.analytics_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserAnalyticsScreen()),
                  );
                },
              ),
              _buildProfileSection(
                'Nearby Items',
                Icons.location_on_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyScreen()),
                  );
                },
              ),
              _buildProfileSection(
                'Help & Support',
                Icons.help_outline,
                    () {
                  // Navigate to help & support screen
                },
              ),
              const SizedBox(height: 24),

              // Sign out button
              CustomButton(
                text: 'Sign Out',
                isLoading: _isLoading,
                onPressed: _signOut,
                backgroundColor: Colors.red.shade100,
                textColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

