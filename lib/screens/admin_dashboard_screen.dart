import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import 'admin_login_screen.dart';
import 'members_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AdminDashboardScreen({
    super.key,
    required this.userData,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AdminAuthService();
    await authService.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AdminLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            userData['name']?.toString().substring(0, 1).toUpperCase() ?? 'A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData['name']?.toString() ?? 'Admin',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(Icons.email, 'Email', userData['email']?.toString() ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, 'Phone', userData['phone']?.toString() ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.badge, 'Role', userData['role']?.toString().toUpperCase() ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.circle,
                      'Status',
                      userData['status']?.toString().toUpperCase() ?? 'N/A',
                      statusColor: userData['status'] == 'active' ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.people,
                  title: 'Manage Users',
                  color: Colors.blue,
                  onTap: () {
                    print('🔵 [Dashboard] Manage Users button tapped');
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            print('🔵 [Dashboard] Building MembersListScreen');
                            return const MembersListScreen();
                          },
                        ),
                      ).then((value) {
                        print('🔵 [Dashboard] Returned from MembersListScreen');
                      }).catchError((error) {
                        print('❌ [Dashboard] Navigation error: $error');
                      });
                    } catch (e) {
                      print('❌ [Dashboard] Exception during navigation: $e');
                    }
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to settings
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  color: Colors.green,
                  onTap: () {
                    // Navigate to analytics
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to notifications
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: statusColor ?? Colors.black87,
              fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
