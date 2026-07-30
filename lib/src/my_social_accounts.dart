import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MySocialAccountsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MySocialAccountsScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MySocialAccountsScreen> createState() =>
      _MySocialAccountsScreenState();
}

class _MySocialAccountsScreenState extends State<MySocialAccountsScreen> {
  static const Color _background = Color(0xFF070B14);
  static const Color _surface = Color(0xFF111827);
  static const Color _surface2 = Color(0xFF161B22);
  static const Color _gold = Color(0xFFFFC107);
  static const String _apiBase = 'https://new-disciples.com/api';

  final http.Client _client = http.Client();

  bool _loading = true;
  bool _refreshing = false;
  String _error = '';
  String? _busyAccountId;
  List<Map<String, dynamic>> _accounts = <Map<String, dynamic>>[];

  static const List<Map<String, dynamic>> _platforms = [
    {
      'code': 'facebook',
      'name': 'Facebook',
      'icon': Icons.facebook_rounded,
      'hint': 'https://facebook.com/username',
    },
    {
      'code': 'instagram',
      'name': 'Instagram',
      'icon': Icons.camera_alt_rounded,
      'hint': 'https://instagram.com/username',
    },
    {
      'code': 'tiktok',
      'name': 'TikTok',
      'icon': Icons.music_note_rounded,
      'hint': 'https://tiktok.com/@username',
    },
    {
      'code': 'youtube',
      'name': 'YouTube',
      'icon': Icons.play_circle_fill_rounded,
      'hint': 'https://youtube.com/@channel',
    },
    {
      'code': 'x',
      'name': 'X',
      'icon': Icons.alternate_email_rounded,
      'hint': 'https://x.com/username',
    },
  ];

  String get _userId =>
      (widget.userData['id'] ?? widget.userData['user_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAccounts();
    });
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid JSON.');
    }

    if (decoded is! Map) {
      throw const FormatException('Unexpected server response.');
    }

    final result = Map<String, dynamic>.from(decoded);
    final success = result['success'] == true || result['status'] == true;

    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      throw Exception(
        result['message']?.toString().trim().isNotEmpty == true
            ? result['message'].toString()
            : 'The request could not be completed.',
      );
    }

    return result;
  }

  Future<void> _loadAccounts({bool refresh = false}) async {
    if (_userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'User ID is missing. Please sign in again.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        if (refresh) {
          _refreshing = true;
        } else {
          _loading = true;
        }
        _error = '';
      });
    }

    try {
      final uri = Uri.parse('$_apiBase/get_social_accounts.php').replace(
        queryParameters: {'user_id': _userId},
      );

      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      final result = await _decode(response);
      final rawAccounts = result['accounts'];
      final loaded = rawAccounts is List
          ? rawAccounts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _accounts = loaded;
        _loading = false;
        _refreshing = false;
      });
    } on TimeoutException {
      _setLoadError('The request timed out. Check your internet connection.');
    } on FormatException catch (error) {
      _setLoadError(error.message);
    } catch (error) {
      _setLoadError(_cleanError(error));
    }
  }

  void _setLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
      _error = message;
    });
  }

  Map<String, dynamic>? _accountFor(String platform) {
    for (final account in _accounts) {
      if (account['platform']?.toString().toLowerCase() ==
          platform.toLowerCase()) {
        return account;
      }
    }
    return null;
  }

  Future<void> _openAccountEditor(Map<String, dynamic> platform) async {
    if (!mounted) return;

    final existing = _accountFor(platform['code'].toString());
    final result = await showModalBottomSheet<_SocialAccountInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountEditorSheet(
        platformName: platform['name'].toString(),
        hint: platform['hint'].toString(),
        initialUsername: existing?['username']?.toString() ?? '',
        initialProfileUrl: existing?['profile_url']?.toString() ?? '',
      ),
    );

    if (!mounted || result == null) return;

    final saved = await _saveAccount(
      platform: platform['code'].toString(),
      username: result.username,
      profileUrl: result.profileUrl,
    );

    if (!mounted || !saved) return;
    await _loadAccounts(refresh: true);
  }

  Future<bool> _saveAccount({
    required String platform,
    required String username,
    required String profileUrl,
  }) async {
    final cleanUsername = username.trim().replaceFirst(RegExp(r'^@+'), '');
    final cleanUrl = profileUrl.trim();

    if (cleanUsername.isEmpty || cleanUrl.isEmpty) {
      _showMessage('Username and public profile URL are required.', error: true);
      return false;
    }

    final parsedUrl = Uri.tryParse(cleanUrl);
    if (parsedUrl == null ||
        !(parsedUrl.scheme == 'https' || parsedUrl.scheme == 'http') ||
        parsedUrl.host.isEmpty) {
      _showMessage('Enter a valid public profile URL.', error: true);
      return false;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_apiBase/save_social_account.php'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'user_id': _userId,
              'platform': platform,
              'username': cleanUsername,
              'profile_url': cleanUrl,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final result = await _decode(response);
      if (!mounted) return false;
      _showMessage(result['message']?.toString() ?? 'Social account saved.');
      return true;
    } on TimeoutException {
      _showMessage('Saving timed out. Please try again.', error: true);
    } catch (error) {
      _showMessage(_cleanError(error), error: true);
    }
    return false;
  }

  Future<void> _verifyAccount(Map<String, dynamic> account) async {
    final accountId = account['id']?.toString() ?? '';
    if (accountId.isEmpty || _busyAccountId != null) return;

    setState(() => _busyAccountId = accountId);

    try {
      final response = await _client
          .post(
            Uri.parse('$_apiBase/verify_social_account.php'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'user_id': _userId,
              'social_account_id': accountId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final result = await _decode(response);
      if (!mounted) return;
      _showMessage(result['message']?.toString() ?? 'Verification completed.');
      await _loadAccounts(refresh: true);
    } on TimeoutException {
      _showMessage('Verification timed out. Please try again.', error: true);
    } catch (error) {
      _showMessage(_cleanError(error), error: true);
    } finally {
      if (mounted) setState(() => _busyAccountId = null);
    }
  }

  Future<void> _removeAccount(Map<String, dynamic> account) async {
    if (_busyAccountId != null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Remove social account?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'This profile will stop contributing to your readiness score and verification status.',
          style: TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final accountId = account['id']?.toString() ?? '';
    if (accountId.isEmpty) return;
    setState(() => _busyAccountId = accountId);

    try {
      final response = await _client
          .post(
            Uri.parse('$_apiBase/delete_social_account.php'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'user_id': _userId,
              'social_account_id': accountId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final result = await _decode(response);
      if (!mounted) return;
      _showMessage(result['message']?.toString() ?? 'Social account removed.');
      await _loadAccounts(refresh: true);
    } on TimeoutException {
      _showMessage('The request timed out. Please try again.', error: true);
    } catch (error) {
      _showMessage(_cleanError(error), error: true);
    } finally {
      if (mounted) setState(() => _busyAccountId = null);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.redAccent : _surface2,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return _gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Social Accounts',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: _gold,
        backgroundColor: _surface,
        onRefresh: () => _loadAccounts(refresh: true),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _loading
              ? _buildLoading()
              : _error.isNotEmpty
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() => ListView(
        key: const ValueKey('loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator(color: _gold)),
        ],
      );

  Widget _buildError() => ListView(
        key: const ValueKey('error'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 110),
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 58),
          const SizedBox(height: 16),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _loadAccounts(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('TRY AGAIN'),
          ),
        ],
      );

  Widget _buildContent() => ListView(
        key: const ValueKey('content'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(.16),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 34),
                SizedBox(height: 12),
                Text(
                  'Build a trusted public identity',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Connect and verify your official profiles. Verified accounts may improve readiness, visibility and recognition.',
                  style: TextStyle(
                    color: Color(0xDD000000),
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: LinearProgressIndicator(color: _gold, minHeight: 2),
            ),
          ..._platforms.map(
            (platform) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildPlatformCard(platform),
            ),
          ),
        ],
      );

  Widget _buildPlatformCard(Map<String, dynamic> platform) {
    final account = _accountFor(platform['code'].toString());
    final icon = platform['icon'] as IconData;

    if (account == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.05)),
        ),
        child: Row(
          children: [
            _platformIcon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform['name'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Not connected',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold.withOpacity(.14),
                foregroundColor: _gold,
                elevation: 0,
              ),
              onPressed: _busyAccountId == null
                  ? () => _openAccountEditor(platform)
                  : null,
              child: const Text(
                'CONNECT',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }

    final status = account['verification_status']?.toString() ?? 'pending';
    final verificationCode = account['verification_code']?.toString() ?? '';
    final accountId = account['id']?.toString() ?? '';
    final isBusy = _busyAccountId == accountId;
    final verified = status.toLowerCase() == 'verified';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _statusColor(status).withOpacity(.28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _platformIcon(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform['name'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${account['username']?.toString().replaceFirst(RegExp(r'^@+'), '') ?? ''}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (!verified && verificationCode.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _surface2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLACE THIS CODE IN YOUR PUBLIC BIO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          verificationCode,
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy code',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: verificationCode),
                          );
                          if (mounted) _showMessage('Verification code copied.');
                        },
                        icon: const Icon(Icons.copy_rounded, color: _gold),
                      ),
                    ],
                  ),
                  const Text(
                    'Keep your profile public, save the bio, then return and tap Verify.',
                    style: TextStyle(color: Colors.white54, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (!verified)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: _busyAccountId == null
                        ? () => _verifyAccount(account)
                        : null,
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.verified_user_rounded),
                    label: Text(
                      isBusy ? 'VERIFYING...' : 'VERIFY',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              if (!verified) const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Edit account',
                onPressed: _busyAccountId == null
                    ? () => _openAccountEditor(platform)
                    : null,
                icon: const Icon(Icons.edit_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Remove account',
                onPressed:
                    _busyAccountId == null ? () => _removeAccount(account) : null,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _platformIcon(IconData icon) => CircleAvatar(
        radius: 24,
        backgroundColor: _gold.withOpacity(.12),
        child: Icon(icon, color: _gold),
      );
}

class _SocialAccountInput {
  final String username;
  final String profileUrl;

  const _SocialAccountInput({
    required this.username,
    required this.profileUrl,
  });
}

class _AccountEditorSheet extends StatefulWidget {
  final String platformName;
  final String hint;
  final String initialUsername;
  final String initialProfileUrl;

  const _AccountEditorSheet({
    required this.platformName,
    required this.hint,
    required this.initialUsername,
    required this.initialProfileUrl,
  });

  @override
  State<_AccountEditorSheet> createState() => _AccountEditorSheetState();
}

class _AccountEditorSheetState extends State<_AccountEditorSheet> {
  static const Color _surface = Color(0xFF111827);
  static const Color _surface2 = Color(0xFF161B22);
  static const Color _gold = Color(0xFFFFC107);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _urlController = TextEditingController(text: widget.initialProfileUrl);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.initialProfileUrl.isEmpty
                    ? 'Connect ${widget.platformName}'
                    : 'Update ${widget.platformName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Use a public profile that belongs to you.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Username',
                  hint: '@username',
                  icon: Icons.alternate_email_rounded,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your username.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration(
                  label: 'Public profile URL',
                  hint: widget.hint,
                  icon: Icons.link_rounded,
                ),
                validator: (value) {
                  final url = value?.trim() ?? '';
                  final uri = Uri.tryParse(url);
                  if (url.isEmpty) return 'Enter your public profile URL.';
                  if (uri == null ||
                      !(uri.scheme == 'https' || uri.scheme == 'http') ||
                      uri.host.isEmpty) {
                    return 'Enter a valid URL beginning with https://';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'SAVE ACCOUNT',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: _gold),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _SocialAccountInput(
        username: _usernameController.text.trim(),
        profileUrl: _urlController.text.trim(),
      ),
    );
  }
}
