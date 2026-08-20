// question.dart
// New Disciples - Protected examination screen for Android/iOS/Web.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuestionScreen extends StatefulWidget {
  final Map userData;
  final Map questionData;

  const QuestionScreen({
    super.key,
    required this.userData,
    required this.questionData,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with WidgetsBindingObserver {
  final TextEditingController answerController = TextEditingController();

  static const String submitApi =
      "https://new-disciples.com/api/submit_answer.php";
  static const String startSessionApi =
      "https://new-disciples.com/api/start_exam_session.php";
  static const String heartbeatApi =
      "https://new-disciples.com/api/exam_heartbeat.php";
  static const String violationApi =
      "https://new-disciples.com/api/report_exam_violation.php";

  bool isLoading = false;
  bool isExpired = false;

  bool sessionStarting = true;
  bool sessionReady = false;
  bool examProtectionActive = false;
  bool malpracticeTriggered = false;
  bool submitting = false;
  bool submitted = false;

  String? examSessionToken;
  int? examSessionId;
  String? sessionError;

  Duration countdown = Duration.zero;

  Timer? timer;
  Timer? heartbeatTimer;

  String get platformName {
    if (kIsWeb) return "web";

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "android";
      case TargetPlatform.iOS:
        return "ios";
      case TargetPlatform.windows:
        return "windows";
      case TargetPlatform.macOS:
        return "macos";
      case TargetPlatform.linux:
        return "linux";
      default:
        return "unknown";
    }
  }

  ////////////////////////////////////////////////////////////
  /// LOCAL DEVELOPMENT MODE
  ///
  /// Allows F12 / DevTools / tab changes ONLY when the web app
  /// is running from localhost or 127.0.0.1.
  ///
  /// Production remains fully protected:
  /// https://new-disciples.com/app/
  ////////////////////////////////////////////////////////////

  bool get isDevelopmentWeb {
    if (!kIsWeb) {
      return false;
    }

    final String host = Uri.base.host.toLowerCase();

    return host == "localhost" ||
        host == "127.0.0.1";
  }

  ////////////////////////////////////////////////////////////
  /// MALPRACTICE ENFORCEMENT
  ///
  /// DEVELOPMENT WEB:
  /// OFF so F12, DevTools and tab switching can be used safely.
  ///
  /// PRODUCTION WEB / MOBILE:
  /// ON during an active protected exam.
  ////////////////////////////////////////////////////////////

  bool get shouldEnforceProtection {
    if (isDevelopmentWeb) {
      return false;
    }

    return sessionReady &&
        examProtectionActive &&
        !malpracticeTriggered &&
        !submitted &&
        !submitting &&
        !isExpired;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // The countdown starts only AFTER the server confirms
    // that the protected exam session is active.
    //
    // This prevents the confusing state where the timer keeps
    // counting while "EXAM SESSION NOT READY" is displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startProtectedExamSession();
    });
  }

  @override
  void dispose() {
    examProtectionActive = false;

    timer?.cancel();
    heartbeatTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    answerController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // During local web development, allow F12, DevTools,
    // tab changes, window focus changes and browser inspection.
    // This bypass is automatically disabled in production.
    if (isDevelopmentWeb) {
      return;
    }

    if (!shouldEnforceProtection) return;

    if (kIsWeb) {
      if (state == AppLifecycleState.hidden ||
          state == AppLifecycleState.detached) {
        reportViolation(
          state == AppLifecycleState.hidden
              ? "tab_hidden"
              : "page_hidden",
          details:
              "Protected web examination lost browser visibility.",
        );
      }

      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      reportViolation(
        "app_minimized",
        details:
            "Protected mobile examination moved to background.",
      );
    }
  }

  Future<void> startProtectedExamSession() async {
    if (sessionReady || !sessionStarting) return;

    if (mounted) {
      setState(() {
        sessionStarting = true;
        sessionError = null;
      });
    }

    try {
      final response = await http
          .post(
            Uri.parse(startSessionApi),
            body: {
              "contestant_id": widget.userData['id'].toString(),
              "question_id": widget.questionData['id'].toString(),
              "platform": platformName,
            },
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception("Invalid examination-session response.");
      }

      final Map data = decoded;

      ////////////////////////////////////////////////////////
      /// REAL PREVIOUS SUBMISSION
      ///
      /// If an answer really exists, do not leave the
      /// contestant on a locked question page with a running
      /// timer. Return cleanly to HomeScreen instead.
      ////////////////////////////////////////////////////////

      final bool alreadySubmitted =
          data['already_submitted'] == true ||
          data['session_status']?.toString().toLowerCase() == "submitted";

      if (alreadySubmitted) {
        if (!mounted) return;

        timer?.cancel();
        heartbeatTimer?.cancel();

        setState(() {
          sessionStarting = false;
          sessionReady = false;
          examProtectionActive = false;
          submitted = true;
          countdown = Duration.zero;
          sessionError = null;
        });

        showMessage(
          data['message']?.toString() ??
              "This examination has already been submitted.",
        );

        await Future.delayed(
          const Duration(milliseconds: 650),
        );

        if (!mounted) return;

        Navigator.of(context).pop(true);
        return;
      }

      if (data['status'] != true) {
        throw Exception(
          data['message']?.toString() ??
              "Unable to start examination session.",
        );
      }

      final String token =
          data['exam_session_token']?.toString() ?? "";

      if (token.isEmpty) {
        throw Exception("Exam session token was not returned.");
      }

      if (!mounted) return;

      setState(() {
        examSessionToken = token;
        examSessionId =
            int.tryParse(data['exam_session_id']?.toString() ?? "");

        sessionStarting = false;
        sessionReady = true;
        examProtectionActive = true;
        submitted = false;
        sessionError = null;
      });

      ////////////////////////////////////////////////////////
      /// START TIMER ONLY AFTER SESSION IS READY
      ////////////////////////////////////////////////////////

      startCountdown();
      startHeartbeat();
    } catch (e, stackTrace) {
      timer?.cancel();
      heartbeatTimer?.cancel();

      debugPrint(
        "START EXAM SESSION ERROR: $e",
      );

      debugPrint(
        "START EXAM SESSION STACK: $stackTrace",
      );

      if (!mounted) return;

      setState(() {
        sessionStarting = false;
        sessionReady = false;
        examProtectionActive = false;
        countdown = Duration.zero;
        sessionError =
            e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void startHeartbeat() {
    heartbeatTimer?.cancel();

    sendHeartbeat();

    heartbeatTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => sendHeartbeat(),
    );
  }

  Future<void> sendHeartbeat() async {
    if (!sessionReady ||
        examSessionToken == null ||
        submitted ||
        malpracticeTriggered ||
        isExpired) {
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(heartbeatApi),
            body: {
              "contestant_id": widget.userData['id'].toString(),
              "question_id": widget.questionData['id'].toString(),
              "exam_session_token": examSessionToken!,
              "platform": platformName,
            },
          )
          .timeout(const Duration(seconds: 10));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) return;

      final Map data = decoded;

      if (data['disqualified'] == true ||
          data['session_status']?.toString() == "disqualified") {
        await handleServerDisqualification(
          data['message']?.toString() ??
              "You have been disqualified.",
        );

        return;
      }

      if (data['session_status']?.toString() == "expired") {
        timer?.cancel();
        heartbeatTimer?.cancel();

        if (!mounted) return;

        setState(() {
          isExpired = true;
          countdown = Duration.zero;
          examProtectionActive = false;
        });

        return;
      }

      if (data['session_status']?.toString() == "submitted") {
        heartbeatTimer?.cancel();

        if (!mounted) return;

        setState(() {
          submitted = true;
          examProtectionActive = false;
        });
      }
    } catch (e) {
      // A short network interruption is not automatically malpractice.
      debugPrint("Exam heartbeat warning: $e");
    }
  }

  Future<void> reportViolation(
    String violationType, {
    String details = "",
  }) async {
    if (!shouldEnforceProtection) return;

    malpracticeTriggered = true;
    examProtectionActive = false;

    timer?.cancel();
    heartbeatTimer?.cancel();

    if (mounted) setState(() {});

    String serverMessage =
        "A protected examination rule was violated.";

    try {
      final response = await http
          .post(
            Uri.parse(violationApi),
            body: {
              "contestant_id": widget.userData['id'].toString(),
              "question_id": widget.questionData['id'].toString(),
              "exam_session_token": examSessionToken ?? "",
              "violation_type": violationType,
              "platform": platformName,
              "details": details,
              "client_time": DateTime.now().toIso8601String(),
            },
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map) {
        serverMessage =
            decoded['message']?.toString() ?? serverMessage;

        if (decoded['session_status']?.toString() == "submitted" &&
            decoded['disqualified'] != true) {
          malpracticeTriggered = false;
          submitted = true;

          if (mounted) setState(() {});
          return;
        }
      }
    } catch (e) {
      debugPrint("Violation reporting warning: $e");
    }

    if (!mounted) return;

    await showDisqualifiedDialog(serverMessage);
  }

  Future<void> handleServerDisqualification(String message) async {
    if (malpracticeTriggered) return;

    malpracticeTriggered = true;
    examProtectionActive = false;

    timer?.cancel();
    heartbeatTimer?.cancel();

    if (mounted) setState(() {});

    await showDisqualifiedDialog(message);
  }

  Future<void> showDisqualifiedDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.gpp_bad, color: Colors.red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Disqualified",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text(
                  "CLOSE EXAM",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void startCountdown() {
    final DateTime endDate =
        DateTime.parse(widget.questionData['end_time'].toString());

    void updateCountdown() {
      final Duration difference =
          endDate.difference(DateTime.now());

      if (difference.inMilliseconds <= 0) {
        timer?.cancel();
        heartbeatTimer?.cancel();

        if (!mounted) return;

        setState(() {
          isExpired = true;
          countdown = Duration.zero;
          examProtectionActive = false;
        });

        return;
      }

      if (!mounted) return;

      setState(() {
        countdown = difference;
      });
    }

    updateCountdown();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateCountdown(),
    );
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return "${twoDigits(duration.inHours)}:"
        "${twoDigits(duration.inMinutes.remainder(60))}:"
        "${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Future<void> submitAnswer() async {
    if (!sessionReady || examSessionToken == null) {
      showMessage(
        sessionError ?? "Protected examination session is not ready.",
        error: true,
      );
      return;
    }

    if (malpracticeTriggered) {
      showMessage(
        "Submission is blocked because this exam session is disqualified.",
        error: true,
      );
      return;
    }

    if (isExpired) {
      showMessage(
        "The examination time has expired.",
        error: true,
      );
      return;
    }

    if (answerController.text.trim().isEmpty) {
      showMessage("Write your answer", error: true);
      return;
    }

    setState(() {
      isLoading = true;
      submitting = true;

      // Stop client-side lifecycle enforcement while the legitimate
      // submit request is in progress. The PHP endpoint remains authoritative.
      examProtectionActive = false;
    });

    try {
      final response = await http
          .post(
            Uri.parse(submitApi),
            body: {
              "contestant_id": widget.userData['id'].toString(),
              "question_id": widget.questionData['id'].toString(),
              "answer": answerController.text.trim(),

              // Existing PHP safely ignores unknown fields.
              // The next backend phase will make this token mandatory.
              "exam_session_token": examSessionToken!,
              "exam_session_id": examSessionId?.toString() ?? "",
              "platform": platformName,
            },
          )
          .timeout(const Duration(seconds: 75));

      debugPrint(
        "SUBMIT HTTP STATUS: ${response.statusCode}",
      );

      debugPrint(
        "SUBMIT RESPONSE: ${response.body}",
      );

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception("Invalid submission response.");
      }

      final Map data = decoded;

      if (!mounted) return;

      if (data['status'] == true) {
        timer?.cancel();
        heartbeatTimer?.cancel();

        setState(() {
          submitted = true;
          isLoading = false;
          submitting = false;
          examProtectionActive = false;
        });

        showMessage(
          data['message']?.toString() ??
              "Answer submitted successfully.",
        );

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        Navigator.pop(context, true);
        return;
      }

      final String message =
          data['message']?.toString() ?? "Submission failed.";

      final bool serverDisqualified =
          data['disqualified'] == true ||
              data['session_status']?.toString() == "disqualified";

      if (serverDisqualified) {
        setState(() {
          isLoading = false;
          submitting = false;
        });

        await handleServerDisqualification(message);
        return;
      }

      setState(() {
        isLoading = false;
        submitting = false;

        if (!isExpired &&
            !submitted &&
            !malpracticeTriggered) {
          examProtectionActive = true;
        }
      });

      showMessage(message, error: true);
    } catch (e, stackTrace) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        submitting = false;

        if (!isExpired &&
            !submitted &&
            !malpracticeTriggered) {
          examProtectionActive = true;
        }
      });

      debugPrint(
        "SUBMIT ERROR: $e",
      );

      debugPrint(
        "SUBMIT STACK TRACE: $stackTrace",
      );

      showMessage(
        isDevelopmentWeb
            ? "Submission error: $e"
            : "Submission failed. Your protected exam session remains active.",
        error: true,
      );
    }
  }

  void showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.red : Colors.green,
        content: Text(message),
      ),
    );
  }

  Future<void> handleExitAttempt() async {
    if (shouldEnforceProtection) {
      await reportViolation(
        "attempted_exam_exit",
        details:
            "Contestant attempted to leave the protected examination screen.",
      );
      return;
    }

    if (mounted &&
        (submitted ||
            isExpired ||
            !sessionReady ||
            sessionError != null)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool answerEnabled =
        sessionReady &&
            !isExpired &&
            !malpracticeTriggered &&
            !submitted;

    return PopScope(
      canPop: !shouldEnforceProtection,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && shouldEnforceProtection) {
          reportViolation(
            "browser_back",
            details:
                "Back navigation was attempted during the protected examination.",
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF070B14),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: handleExitAttempt,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              shouldEnforceProtection
                                  ? Icons.lock
                                  : Icons.arrow_back,
                              color: shouldEnforceProtection
                                  ? const Color(0xFFFFC107)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Text(
                            "Answer Question",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (sessionReady)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.green.withOpacity(.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isDevelopmentWeb
                                      ? "DEV MODE"
                                      : "PROTECTED",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFC107).withOpacity(.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.gpp_good,
                            color: Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isDevelopmentWeb
                                  ? "LOCAL DEVELOPMENT MODE: F12, DevTools and tab switching are allowed. Malpractice enforcement automatically turns ON when this web app is deployed to production."
                                  : kIsWeb
                                      ? "Protected exam: changing tabs, hiding the browser, or trying to leave this page during the live examination can result in disqualification."
                                      : "Protected exam: minimizing or leaving the app during the live examination can result in disqualification.",
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.6,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (sessionStarting)
                      buildSessionCard(
                        title: "SECURING EXAMINATION",
                        message:
                            "Creating your protected examination session...",
                        color: const Color(0xFFFFC107),
                        loading: true,
                      ),

                    if (sessionError != null)
                      buildSessionError(),

                    if (sessionStarting || sessionError != null)
                      const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            malpracticeTriggered || isExpired
                                ? Colors.red
                                : Colors.green,
                            Colors.black,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Text(
                            malpracticeTriggered
                                ? "DISQUALIFIED"
                                : isExpired
                                    ? "QUESTION CLOSED"
                                    : !sessionReady
                                        ? "WAITING FOR SECURE SESSION"
                                        : "TIME REMAINING",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            formatTime(countdown),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color:
                                    answerEnabled ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                answerEnabled
                                    ? "QUESTION ACTIVE"
                                    : malpracticeTriggered
                                        ? "SESSION DISQUALIFIED"
                                        : "QUESTION LOCKED",
                                style: TextStyle(
                                  color: answerEnabled
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          Text(
                            widget.questionData['question'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 18),

                          if ((widget.questionData['description']?.toString() ??
                                  "")
                              .isNotEmpty)
                            Text(
                              widget.questionData['description']?.toString() ??
                                  "",
                              style: const TextStyle(
                                color: Colors.white54,
                                height: 1.7,
                                fontSize: 15,
                              ),
                            ),

                          const SizedBox(height: 28),

                          SizedBox(
                            height: 320,
                            child: TextField(
                              controller: answerController,
                              enabled: answerEnabled && !isLoading,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Write your answer here...",
                                hintStyle:
                                    const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF070B14),
                                contentPadding: const EdgeInsets.all(24),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${answerController.text.length} Characters",
                                style:
                                    const TextStyle(color: Colors.white38),
                              ),
                              Text(
                                answerEnabled
                                    ? "Submission Open"
                                    : "Submission Closed",
                                style: TextStyle(
                                  color: answerEnabled
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 62,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: answerEnabled
                                    ? const Color(0xFFFFC107)
                                    : Colors.grey.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              onPressed: !answerEnabled || isLoading
                                  ? null
                                  : submitAnswer,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      answerEnabled
                                          ? "SUBMIT ANSWER"
                                          : "SUBMISSION LOCKED",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSessionCard({
    required String title,
    required String message,
    required Color color,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(
        children: [
          if (loading)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: color,
              ),
            )
          else
            Icon(Icons.gpp_bad, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSessionError() {
    return Column(
      children: [
        buildSessionCard(
          title: "EXAM SESSION NOT READY",
          message:
              sessionError ?? "Unable to secure examination session.",
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () {
              setState(() {
                sessionStarting = true;
                sessionError = null;
              });

              startProtectedExamSession();
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              "RETRY SECURE SESSION",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
