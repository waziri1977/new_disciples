import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'change_picture.dart';
import 'delete_account.dart';
import 'edit_profile.dart';
import 'login.dart';
import 'my_social_accounts.dart';
import 'notification.dart';

class ProfileScreen extends StatefulWidget {
  final Map userData;

  const ProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _background = Color(0xFF070B14);
  static const Color _surface = Color(0xFF111827);
  static const Color _surface2 = Color(0xFF161B22);
  static const Color _gold = Color(0xFFFFC107);
  static const Color _danger = Color(0xFFFF4D67);
  static const String _profileApi =
      'https://new-disciples.com/api/get_profile.php';

  final http.Client _client = http.Client();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';
  Map<String, dynamic> _profile = {};

  String get _userId =>
      (widget.userData['id'] ?? widget.userData['user_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _getProfile({bool refresh = false}) async {
    if (_userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid user account.';
      });
      return;
    }

    if (refresh) {
      if (_isRefreshing) return;
      setState(() => _isRefreshing = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_profileApi),
            headers: const {'Accept': 'application/json'},
            body: {'contestant_id': _userId},
          )
          .timeout(const Duration(seconds: 25));

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid server response.');
      }

      final data = Map<String, dynamic>.from(decoded);
      final success = data['status'] == true || data['success'] == true;

      if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
        throw Exception(data['message']?.toString() ?? 'Unable to load profile.');
      }

      final user = data['user'];
      if (user is! Map) {
        throw const FormatException('Profile information is missing.');
      }

      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(user);
        _errorMessage = '';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _errorMessage = 'The request timed out. Pull down to retry.');
    } on FormatException {
      if (!mounted) return;
      setState(() => _errorMessage = 'The server returned an invalid response.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openPage(Widget page, {bool reloadProfile = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;
    if (reloadProfile) await _getProfile(refresh: true);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openDeleteAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeleteAccountScreen(
          userData: _profile,
          onAccountDeleted: () {},
        ),
      ),
    );
  }

  String? get _pictureUrl {
    final value = _profile['picture']?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : _errorMessage.isNotEmpty && _profile.isEmpty
                ? _buildErrorState()
                : RefreshIndicator(
                    color: _gold,
                    backgroundColor: _surface,
                    onRefresh: () => _getProfile(refresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 42),
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 18),
                        _buildProfileHeader(),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildInlineError(),
                        ],
                        const SizedBox(height: 26),
                        _sectionTitle('ACCOUNT'),
                        const SizedBox(height: 10),
                        _buildMenuCard(
                          icon: Icons.edit_rounded,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () => _openPage(
                            EditProfileScreen(userData: _profile),
                            reloadProfile: true,
                          ),
                        ),
                        _buildMenuCard(
                          icon: Icons.add_a_photo_rounded,
                          title: 'Change Picture',
                          subtitle: 'Use a clear and recent profile photo',
                          onTap: () => _openPage(
                            ChangePictureScreen(
                              contestantId: _profile['id'].toString(),
                            ),
                            reloadProfile: true,
                          ),
                        ),
                        _buildMenuCard(
                          icon: Icons.public_rounded,
                          title: 'My Social Accounts',
                          subtitle: 'Connect and verify your public profiles',
                          onTap: () => _openPage(
                            MySocialAccountsScreen(userData: _profile),
                            reloadProfile: true,
                          ),
                        ),
                        _buildMenuCard(
                          icon: Icons.notifications_rounded,
                          title: 'Notifications',
                          subtitle: 'View announcements and account updates',
                          onTap: () => _openPage(
                            NotificationScreen(
                              contestantId: _profile['id'].toString(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('SECURITY & ACCESS'),
                        const SizedBox(height: 10),
                        _buildMenuCard(
                          icon: Icons.logout_rounded,
                          title: 'Log Out',
                          subtitle: 'Sign out securely from this device',
                          onTap: _logout,
                        ),
                        _buildMenuCard(
                          icon: Icons.delete_forever_rounded,
                          title: 'Delete My Account',
                          subtitle: 'Permanently remove your account and data',
                          onTap: _openDeleteAccount,
                          danger: true,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Deleting your account is permanent and cannot be reversed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Manage your identity and account',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: _isRefreshing ? null : () => _getProfile(refresh: true),
          style: IconButton.styleFrom(
            backgroundColor: _surface2,
            foregroundColor: _gold,
          ),
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _gold,
                  ),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171E2E), Color(0xFF0F1522)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _gold.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_gold, Color(0xFFFF8F00)]),
                ),
                child: CircleAvatar(
                  radius: 62,
                  backgroundColor: _surface,
                  backgroundImage:
                      _pictureUrl == null ? null : NetworkImage(_pictureUrl!),
                  child: _pictureUrl == null
                      ? const Icon(Icons.person_rounded,
                          size: 68, color: Colors.white54)
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Material(
                  color: _gold,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _openPage(
                      ChangePictureScreen(
                        contestantId: _profile['id'].toString(),
                      ),
                      reloadProfile: true,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(11),
                      child: Icon(Icons.camera_alt_rounded,
                          color: Colors.black, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _profile['full_name']?.toString() ?? 'New Disciples User',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _profile['phone']?.toString() ?? '',
            style: const TextStyle(color: Colors.white60),
          ),
          if ((_profile['email']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _profile['email'].toString(),
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _gold.withOpacity(.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _gold.withOpacity(.25)),
            ),
            child: Text(
              (_profile['role']?.toString() ?? 'contestant').toUpperCase(),
              style: const TextStyle(
                color: _gold,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final accent = danger ? _danger : _gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: danger ? _danger.withOpacity(.20) : Colors.white.withOpacity(.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger ? _danger : Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: danger ? _danger.withOpacity(.65) : Colors.white24,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _danger.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _danger.withOpacity(.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _danger, size: 58),
            const SizedBox(height: 16),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _getProfile,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'TRY AGAIN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
