import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteAccountScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onAccountDeleted;

  const DeleteAccountScreen({
    super.key,
    required this.userData,
    this.onAccountDeleted,
  });

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const Color _background = Color(0xFF070B14);
  static const Color _surface = Color(0xFF111827);
  static const Color _surface2 = Color(0xFF161B22);
  static const Color _gold = Color(0xFFFFC107);
  static const Color _danger = Color(0xFFFF4D67);
  static const String _apiUrl =
      'https://new-disciples.com/api/delete_account.php';

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final http.Client _client = http.Client();

  bool _submitting = false;
  bool _hidePassword = true;
  bool _understands = false;

  String get _userId =>
      (widget.userData['id'] ?? widget.userData['user_id'] ?? '').toString();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;

    if (!_understands) {
      _showMessage('Confirm that you understand this action is permanent.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: _danger),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Final confirmation',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your profile, social accounts, answers, votes, notifications and other linked records will be permanently deleted. This cannot be undone.',
          style: TextStyle(color: Colors.white60, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('KEEP MY ACCOUNT'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _submitting = true);

    try {
      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'user_id': _userId,
              'password': _passwordController.text,
              'confirmation': _confirmationController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid server response.');
      }

      final result = Map<String, dynamic>.from(decoded);
      final success = result['success'] == true || result['status'] == true;

      if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
        throw Exception(result['message']?.toString() ?? 'Deletion failed.');
      }

      if (!mounted) return;

      widget.onAccountDeleted?.call();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.greenAccent, size: 54),
          title: const Text(
            'Account deleted',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Text(
            result['message']?.toString() ??
                'Your account and associated records have been deleted.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on TimeoutException {
      _showMessage('The request timed out. Please try again.');
    } on FormatException {
      _showMessage('The server returned an invalid response.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _understands &&
        _confirmationController.text.trim().toUpperCase() == 'DELETE' &&
        _passwordController.text.isNotEmpty &&
        !_submitting;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5A70), Color(0xFFB00020)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: _danger.withOpacity(.18),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 40, color: Colors.white),
                      SizedBox(height: 14),
                      Text(
                        'Permanent account deletion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This action removes your New Disciples account and linked records from the database. It cannot be reversed.',
                        style: TextStyle(
                          color: Color(0xEEFFFFFF),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _sectionCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What will be deleted',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 14),
                      _DeleteItem('Profile and login credentials'),
                      _DeleteItem('Connected social accounts and verification data'),
                      _DeleteItem('Answers, votes and participation history'),
                      _DeleteItem('Notifications and related personal records'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Confirm your identity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                          label: 'Current password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your current password.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmationController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                          label: 'Type DELETE to confirm',
                          icon: Icons.keyboard_rounded,
                        ),
                        validator: (value) =>
                            value?.trim().toUpperCase() != 'DELETE'
                                ? 'Type DELETE exactly.'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _understands,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _danger,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                setState(() => _understands = value ?? false),
                        title: const Text(
                          'I understand that this deletion is permanent and cannot be undone.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _danger,
                      disabledBackgroundColor: _danger.withOpacity(.25),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: canDelete ? _deleteAccount : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      _submitting
                          ? 'DELETING ACCOUNT...'
                          : 'DELETE MY ACCOUNT PERMANENTLY',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'For your protection, your password is verified before deletion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.05)),
        ),
        child: child,
      );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: _gold),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface2,
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
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _danger),
      ),
    );
  }
}

class _DeleteItem extends StatelessWidget {
  final String text;

  const _DeleteItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.remove_circle_outline_rounded,
              color: Color(0xFFFF4D67), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
