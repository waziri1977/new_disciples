import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final requestApi = "https://new-disciples.com/api/request_password_reset.php";
  final verifyApi = "https://new-disciples.com/api/verify_reset_code.php";
  final resetApi = "https://new-disciples.com/api/reset_password.php";

  int step = 1;
  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String resetToken = "";
  int resendSeconds = 0;
  Timer? resendTimer;

  @override
  void dispose() {
    resendTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool validEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  void showMessage(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: error ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startResendTimer() {
    resendTimer?.cancel();
    setState(() => resendSeconds = 60);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  Future<void> requestCode({bool resend = false}) async {
    final email = emailController.text.trim().toLowerCase();

    if (!validEmail(email)) {
      showMessage("Enter your registered email address.");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(requestApi),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email}),
      ).timeout(
        const Duration(seconds: 30),
      );

      if (!mounted) return;

      debugPrint(
        "PASSWORD RESET HTTP ${response.statusCode}: ${response.body}",
      );

      setState(() => loading = false);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        showMessage(
          "Server error ${response.statusCode}. Please check request_password_reset.php.",
        );
        return;
      }

      if (response.body.trim().isEmpty) {
        showMessage(
          "The server returned an empty response.",
        );
        return;
      }

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        showMessage(
          "Invalid server response. Check PHP error log.",
        );
        return;
      }

      if (data["status"] == true) {
        codeController.clear();
        setState(() => step = 2);
        startResendTimer();
        showMessage(
          data["message"]?.toString() ??
              (resend
                  ? "A new recovery code has been sent."
                  : "Recovery code sent to your email."),
          error: false,
        );
      } else {
        showMessage(
          data["message"]?.toString() ?? "Unable to send recovery code.",
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage(
        "Connection timed out while contacting the recovery server.",
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      debugPrint(
        "PASSWORD RESET REQUEST ERROR: $e",
      );

      showMessage(
        "Recovery request failed: $e",
      );
    }
  }

  Future<void> verifyCode() async {
    final code = codeController.text.trim();

    if (code.length != 6) {
      showMessage("Enter the 6-digit recovery code.");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(verifyApi),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim().toLowerCase(),
          "code": code,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => loading = false);

      if (data["status"] == true) {
        resetToken = data["reset_token"]?.toString() ?? "";
        if (resetToken.isEmpty) {
          showMessage("Verification succeeded but reset token is missing.");
          return;
        }
        setState(() => step = 3);
        showMessage("Email verified successfully.", error: false);
      } else {
        showMessage(data["message"]?.toString() ?? "Invalid recovery code.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage("Unable to verify recovery code.");
    }
  }

  Future<void> resetPassword() async {
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (password.length < 6) {
      showMessage("Password must contain at least 6 characters.");
      return;
    }

    if (password != confirm) {
      showMessage("Passwords do not match.");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(resetApi),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim().toLowerCase(),
          "reset_token": resetToken,
          "new_password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => loading = false);

      if (data["status"] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFC107).withOpacity(.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF00C853),
                    child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Password Updated",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your password has been changed successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("RETURN TO LOGIN", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (mounted) Navigator.pop(context);
      } else {
        showMessage(data["message"]?.toString() ?? "Unable to reset password.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage("Unable to reset password. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Account Recovery",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 78,
                      width: 78,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFFFFC107), size: 42),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Recover Your Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 27, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step == 1
                          ? "We’ll send a secure recovery code to your registered email."
                          : step == 2
                              ? "Enter the 6-digit code sent to ${emailController.text.trim()}."
                              : "Create a new secure password for your account.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _stepIndicator(),
              const SizedBox(height: 28),
              if (step == 1) _emailStep(),
              if (step == 2) _verifyStep(),
              if (step == 3) _resetStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Row(
      children: [
        _stepCircle(1, "Email"),
        _line(step >= 2),
        _stepCircle(2, "Verify"),
        _line(step >= 3),
        _stepCircle(3, "Reset"),
      ],
    );
  }

  Widget _stepCircle(int number, String label) {
    final active = step >= number;
    return Column(
      children: [
        Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFC107) : const Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
          child: Text(
            "$number",
            style: TextStyle(
              color: active ? Colors.black : Colors.white38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _line(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 18),
        color: active ? const Color(0xFFFFC107) : const Color(0xFF1E293B),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: const Color(0xFFFFC107)),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _emailStep() {
    return _card([
      const Text("Registered Email", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration("you@example.com", Icons.email_outlined),
      ),
      const SizedBox(height: 22),
      _button("SEND RECOVERY CODE", Icons.send_rounded, () => requestCode()),
    ]);
  }

  Widget _verifyStep() {
    return _card([
      const Text("Verification Code", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      TextField(
        controller: codeController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: Color(0xFFFFC107),
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 12,
        ),
        decoration: _decoration("000000", Icons.pin_outlined).copyWith(counterText: ""),
      ),
      const SizedBox(height: 22),
      _button("VERIFY CODE", Icons.verified_outlined, verifyCode),
      Center(
        child: TextButton(
          onPressed: resendSeconds > 0 || loading ? null : () => requestCode(resend: true),
          child: Text(
            resendSeconds > 0 ? "Resend code in ${resendSeconds}s" : "Resend recovery code",
            style: TextStyle(
              color: resendSeconds > 0 ? Colors.white38 : const Color(0xFFFFC107),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _resetStep() {
    return _card([
      const Text("Create New Password", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      _passwordField(passwordController, "New password", obscurePassword, () {
        setState(() => obscurePassword = !obscurePassword);
      }),
      const SizedBox(height: 14),
      _passwordField(confirmController, "Confirm new password", obscureConfirm, () {
        setState(() => obscureConfirm = !obscureConfirm);
      }),
      const SizedBox(height: 22),
      _button("UPDATE PASSWORD", Icons.lock_reset_rounded, resetPassword),
    ]);
  }

  Widget _passwordField(TextEditingController controller, String hint, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(hint, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _button(String label, IconData icon, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: loading ? null : action,
        icon: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
              )
            : Icon(icon),
        label: Text(
          loading ? "PLEASE WAIT..." : label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
