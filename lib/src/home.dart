// home.dart
//
// NEW DISCIPLES - APPLE / iPAD PRODUCTION RELIABILITY VERSION
//
// HomeScreen DOES NOT disqualify contestants.
// QuestionScreen remains the client-side exam-malpractice detector.
//
// Reliability improvements:
// - explicit content error state
// - strict JSON validation
// - clear RETRY action
// - 10-second polling instead of 3 seconds
// - preserves last valid content during temporary refresh failures
// - malformed/empty responses no longer look like "No live question"
// - production-safe timeout handling
// - iPad-friendly constrained layout

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'question.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  final Map userData;

  const HomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  static const String apiUrl =
      "https://new-disciples.com/api/get_live_question.php";

  static const String logoutApi =
      "https://new-disciples.com/api/logout.php";

  static const String verifyExamCodeApi =
      "https://new-disciples.com/api/verify_exam_code.php";

  bool isLoading = true;
  bool isQuestionActive = false;
  bool alreadyAnswered = false;
  bool disqualified = false;
  bool alreadyQualified = false;
  bool verifyingCode = false;
  bool fetchingQuestion = false;

  bool hasContentError = false;
  bool hasLoadedValidContentOnce = false;

  String contentErrorMessage = "";
  String qualificationMessage = "";

  bool _disqualificationDialogShown = false;

  final TextEditingController _examCodeController =
      TextEditingController();

  bool _showExamCodeForm = false;
  String? _examCodeError;

  Map<String, dynamic> questionData = {};

  Duration countdown = Duration.zero;

  Timer? timer;
  Timer? liveQuestionRefreshTimer;

  static const Duration liveQuestionRefreshInterval =
      Duration(seconds: 10);

  bool get isDevelopmentWeb {
    if (!kIsWeb) {
      return false;
    }

    final String host = Uri.base.host.toLowerCase();

    return host == "localhost" || host == "127.0.0.1";
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    getLiveQuestion(showLoader: true);
    startLiveQuestionRefresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    liveQuestionRefreshTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    _examCodeController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed && !disqualified) {
      getLiveQuestion(showLoader: false);
    }
  }

  void startLiveQuestionRefresh() {
    liveQuestionRefreshTimer?.cancel();

    liveQuestionRefreshTimer = Timer.periodic(
      liveQuestionRefreshInterval,
      (_) {
        if (!mounted ||
            disqualified ||
            alreadyQualified ||
            fetchingQuestion) {
          return;
        }

        getLiveQuestion(showLoader: false);
      },
    );
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response,
  ) {
    final String body = response.body.trim();

    if (body.isEmpty) {
      throw const FormatException(
        "Empty server response.",
      );
    }

    final dynamic decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw const FormatException(
        "Unexpected server response format.",
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  void _setContentError(
    String message, {
    bool preserveExistingContent = true,
  }) {
    if (!mounted) return;

    setState(() {
      hasContentError = true;
      contentErrorMessage = message;
      isLoading = false;

      if (!preserveExistingContent ||
          !hasLoadedValidContentOnce) {
        isQuestionActive = false;
        alreadyAnswered = false;
        questionData = {};
        countdown = Duration.zero;
      }
    });
  }

  Future<void> getLiveQuestion({
    bool showLoader = false,
  }) async {
    if (fetchingQuestion || disqualified) {
      return;
    }

    final String contestantId =
        widget.userData['id']?.toString().trim() ?? "";

    if (contestantId.isEmpty) {
      _setContentError(
        "Your contestant session is incomplete. Please sign in again.",
        preserveExistingContent: false,
      );
      return;
    }

    fetchingQuestion = true;

    if (showLoader &&
        mounted &&
        !hasLoadedValidContentOnce) {
      setState(() {
        isLoading = true;
        hasContentError = false;
        contentErrorMessage = "";
      });
    }

    try {
      final Uri uri = Uri.parse(
        "$apiUrl"
        "?contestant_id=$contestantId"
        "&_=${DateTime.now().millisecondsSinceEpoch}",
      );

      final http.Response response = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Cache-Control":
                  "no-cache, no-store, must-revalidate",
              "Pragma": "no-cache",
            },
          )
          .timeout(
            const Duration(seconds: 12),
          );

      debugPrint(
        "LIVE QUESTION HTTP: ${response.statusCode}",
      );

      debugPrint(
        "LIVE QUESTION RESPONSE: ${response.body}",
      );

      final Map<String, dynamic> data =
          _decodeJsonResponse(response);

      if (!mounted) return;

      final String contestantStatus =
          data['contestant_status']
                  ?.toString()
                  .toLowerCase()
                  .trim() ??
              "";

      final bool serverDisqualified =
          data['disqualified'] == true ||
              contestantStatus == "disqualified";

      if (serverDisqualified) {
        timer?.cancel();
        liveQuestionRefreshTimer?.cancel();

        setState(() {
          disqualified = true;
          isQuestionActive = false;
          alreadyAnswered = false;
          isLoading = false;
          hasContentError = false;
          contentErrorMessage = "";
          countdown = Duration.zero;
        });

        await _showServerDisqualifiedDialog(
          data['message']?.toString() ??
              "Contestant is no longer eligible.",
        );

        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data['message']?.toString() ??
              "Server returned ${response.statusCode}.",
        );
      }

      hasLoadedValidContentOnce = true;

      final bool serverAlreadyQualified =
          data['already_qualified'] == true;

      if (serverAlreadyQualified) {
        timer?.cancel();
        liveQuestionRefreshTimer?.cancel();

        setState(() {
          alreadyQualified = true;
          qualificationMessage =
              data['message']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? data['message'].toString()
                  : "You have already qualified for the judging stage.";

          isQuestionActive = false;
          alreadyAnswered = false;
          questionData = {};
          countdown = Duration.zero;
          isLoading = false;
          hasContentError = false;
          contentErrorMessage = "";
        });

        return;
      }

      if (data['status'] == true) {
        final dynamic rawQuestion = data['question'];

        if (rawQuestion is! Map) {
          throw const FormatException(
            "Live question payload is missing.",
          );
        }

        final Map<String, dynamic> incomingQuestion =
            Map<String, dynamic>.from(rawQuestion);

        final bool incomingAnswered =
            incomingQuestion['already_answered'] == true ||
                data['already_answered'] == true;

        final String? oldQuestionId =
            questionData['id']?.toString();

        final String? newQuestionId =
            incomingQuestion['id']?.toString();

        final String? oldEndTime =
            questionData['end_time']?.toString();

        final String? newEndTime =
            incomingQuestion['end_time']?.toString();

        final bool questionChanged =
            oldQuestionId != newQuestionId ||
                oldEndTime != newEndTime ||
                !isQuestionActive;

        setState(() {
          alreadyQualified = false;
          qualificationMessage = "";

          questionData = incomingQuestion;
          alreadyAnswered = incomingAnswered;
          isQuestionActive = true;
          isLoading = false;
          hasContentError = false;
          contentErrorMessage = "";
        });

        final bool countdownNeedsRestart =
            questionChanged ||
                timer == null ||
                !(timer?.isActive ?? false);

        if (countdownNeedsRestart &&
            newEndTime != null &&
            newEndTime.isNotEmpty) {
          try {
            startCountdown(newEndTime);
          } catch (e) {
            debugPrint(
              "Countdown parse warning: $e",
            );

            _setContentError(
              "The live examination timing could not be read correctly. Please retry.",
              preserveExistingContent: true,
            );
          }
        }

        return;
      }

      timer?.cancel();

      setState(() {
        alreadyQualified = false;
        qualificationMessage = "";

        isQuestionActive = false;
        alreadyAnswered = false;
        questionData = {};
        countdown = Duration.zero;
        isLoading = false;
        hasContentError = false;
        contentErrorMessage = "";
      });
    } on TimeoutException catch (e) {
      debugPrint("Live question timeout: $e");

      _setContentError(
        "The New Disciples server took too long to respond. Please check your connection and try again.",
        preserveExistingContent: true,
      );
    } on FormatException catch (e) {
      debugPrint(
        "LIVE QUESTION JSON/FORMAT ERROR: $e",
      );

      _setContentError(
        "We received an invalid response while loading competition content. Please try again.",
        preserveExistingContent: true,
      );
    } catch (e, stackTrace) {
      debugPrint(
        "Live question refresh error: $e",
      );

      debugPrint(
        "LIVE QUESTION STACK: $stackTrace",
      );

      _setContentError(
        "Unable to load competition content right now. Please check your internet connection and try again.",
        preserveExistingContent: true,
      );
    } finally {
      fetchingQuestion = false;
    }
  }

  Future<void> retryContent() async {
    if (fetchingQuestion) return;

    if (mounted) {
      setState(() {
        hasContentError = false;
        contentErrorMessage = "";
      });
    }

    await getLiveQuestion(
      showLoader: !hasLoadedValidContentOnce,
    );
  }

  Future<void> _showServerDisqualifiedDialog(
    String message,
  ) async {
    if (!mounted || _disqualificationDialogShown) {
      return;
    }

    _disqualificationDialogShown = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.gpp_bad,
                  color: Colors.red,
                ),
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

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  "CLOSE",
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

  void startCountdown(
    String endTime,
  ) {
    timer?.cancel();

    final DateTime endDate = DateTime.parse(endTime);

    void updateCountdown() {
      if (!mounted) return;

      final Duration difference =
          endDate.difference(DateTime.now());

      if (difference.inSeconds <= 0) {
        timer?.cancel();

        setState(() {
          isQuestionActive = false;
          countdown = Duration.zero;
        });

        getLiveQuestion(showLoader: false);
        return;
      }

      setState(() {
        countdown = difference;
      });
    }

    updateCountdown();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        updateCountdown();
      },
    );
  }

  String formatTime(
    Duration duration,
  ) {
    String twoDigits(int n) =>
        n.toString().padLeft(2, '0');

    final String hours =
        twoDigits(duration.inHours);

    final String minutes =
        twoDigits(
      duration.inMinutes.remainder(60),
    );

    final String seconds =
        twoDigits(
      duration.inSeconds.remainder(60),
    );

    return "$hours:$minutes:$seconds";
  }

  void openQuestion() {
    if (disqualified ||
        !isQuestionActive ||
        alreadyAnswered ||
        verifyingCode) {
      return;
    }

    setState(() {
      _showExamCodeForm = true;
      _examCodeError = null;
      _examCodeController.clear();
    });
  }

  void cancelExamCodeVerification() {
    if (verifyingCode) return;

    setState(() {
      _showExamCodeForm = false;
      _examCodeError = null;
      _examCodeController.clear();
    });
  }

  Future<void> verifyAndOpenQuestion() async {
    if (verifyingCode ||
        disqualified ||
        !isQuestionActive ||
        alreadyAnswered) {
      return;
    }

    final String enteredCode =
        _examCodeController.text.trim();

    if (enteredCode.isEmpty) {
      setState(() {
        _examCodeError = "Enter the exam code.";
      });
      return;
    }

    final String questionId =
        questionData['id']?.toString() ?? "";

    if (questionId.isEmpty) {
      setState(() {
        _examCodeError =
            "The live question is no longer available. Please refresh.";
      });
      return;
    }

    setState(() {
      verifyingCode = true;
      _examCodeError = null;
    });

    try {
      final http.Response response = await http
          .post(
            Uri.parse(verifyExamCodeApi),
            headers: {
              "Accept": "application/json",
            },
            body: {
              "contestant_id":
                  widget.userData['id'].toString(),
              "question_id": questionId,
              "exam_code": enteredCode,
            },
          )
          .timeout(
            const Duration(seconds: 12),
          );

      final Map<String, dynamic> data =
          _decodeJsonResponse(response);

      if (!mounted) return;

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        setState(() {
          verifyingCode = false;
          _examCodeError =
              data['message']?.toString() ??
                  "Server returned ${response.statusCode}.";
        });
        return;
      }

      if (data['status'] != true) {
        setState(() {
          verifyingCode = false;
          _examCodeError =
              data['message']?.toString() ??
                  "Invalid exam code.";
        });
        return;
      }

      final Map<String, dynamic> questionSnapshot =
          Map<String, dynamic>.from(
        questionData,
      );

      setState(() {
        verifyingCode = false;
        _showExamCodeForm = false;
        _examCodeError = null;
      });

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      liveQuestionRefreshTimer?.cancel();
      timer?.cancel();

      final dynamic examResult =
          await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(
            userData: widget.userData,
            questionData: questionSnapshot,
          ),
        ),
      );

      if (!mounted) return;

      _examCodeController.clear();

      if (!disqualified && !alreadyQualified) {
        startLiveQuestionRefresh();

        await getLiveQuestion(
          showLoader: false,
        );
      }

      debugPrint(
        "QuestionScreen returned: $examResult",
      );
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        verifyingCode = false;
        _examCodeError =
            "Exam-code verification timed out. Please try again.";
      });
    } on FormatException {
      if (!mounted) return;

      setState(() {
        verifyingCode = false;
        _examCodeError =
            "The verification server returned an invalid response.";
      });
    } catch (e, stackTrace) {
      debugPrint(
        "Exam code verification error: $e",
      );

      debugPrint(
        "Exam code verification stack: $stackTrace",
      );

      if (!mounted) return;

      setState(() {
        verifyingCode = false;
        _examCodeError =
            "Unable to verify exam code. Please try again.";
      });
    }
  }

  Future<void> logout() async {
    liveQuestionRefreshTimer?.cancel();
    timer?.cancel();

    try {
      await http
          .post(
            Uri.parse(logoutApi),
            headers: {
              "Accept": "application/json",
            },
            body: {
              "user_id":
                  widget.userData['id'].toString(),
            },
          )
          .timeout(
            const Duration(seconds: 8),
          );
    } catch (e) {
      debugPrint(
        "Logout warning: $e",
      );
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget buildContentErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.redAccent.withOpacity(.28),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Unable to Load Content",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contentErrorMessage.trim().isNotEmpty
                ? contentErrorMessage
                : "Competition content could not be loaded right now.",
            style: const TextStyle(
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  fetchingQuestion ? null : retryContent,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                "RETRY",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "New Disciples",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (isDevelopmentWeb)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Center(
                child: Text(
                  "DEV",
                  style: TextStyle(
                    color: Color(0xFFFFC107),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body:
          isLoading &&
                  !hasLoadedValidContentOnce
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFC107),
                  ),
                )
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 900,
                      ),
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, ${widget.userData['full_name'] ?? 'Contestant'}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Prepare for your live mock session.",
                              style: TextStyle(
                                color: Colors.white54,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (hasContentError)
                              buildContentErrorCard(),

                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFFFC107),
                                    Color(0xFFFFB300),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(35),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (alreadyQualified) ...[
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          alignment:
                                              Alignment.center,
                                          decoration:
                                              BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child:
                                              const Icon(
                                            Icons.verified_rounded,
                                            color:
                                                Color(0xFFFFC107),
                                            size: 25,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 12,
                                        ),
                                        const Expanded(
                                          child: Text(
                                            "QUALIFICATION COMPLETE",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              letterSpacing: .8,
                                              fontWeight:
                                                  FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 26,
                                    ),
                                    Text(
                                      qualificationMessage
                                              .isNotEmpty
                                          ? qualificationMessage
                                          : "You have already qualified for the judging stage.",
                                      style:
                                          const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                        height: 1.25,
                                        fontWeight:
                                            FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    const Text(
                                      "You do not need to answer another qualification question.",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        height: 1.6,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ] else ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 12,
                                          color:
                                              isQuestionActive
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Text(
                                          isQuestionActive
                                              ? "LIVE QUESTION"
                                              : "NO LIVE QUESTION",
                                          style:
                                              const TextStyle(
                                            color: Colors.black,
                                            fontWeight:
                                                FontWeight.w900,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isQuestionActive)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.timer,
                                                color:
                                                    Colors.black,
                                              ),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              Text(
                                                formatTime(
                                                  countdown,
                                                ),
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.black,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    Text(
                                      isQuestionActive
                                          ? questionData['question']
                                                  ?.toString() ??
                                              "Question unavailable."
                                          : "No active question currently.",
                                      style:
                                          const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                        height: 1.2,
                                        fontWeight:
                                            FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isQuestionActive)
                                      const Text(
                                        "There is currently no live examination. This page will refresh automatically.",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight:
                                              FontWeight.w700,
                                          height: 1.5,
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    if (isQuestionActive &&
                                        !alreadyAnswered &&
                                        !_showExamCodeForm)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 60,
                                        child: ElevatedButton(
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.black,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                            ),
                                          ),
                                          onPressed:
                                              verifyingCode
                                                  ? null
                                                  : openQuestion,
                                          child: const Text(
                                            "START MOCK",
                                            style:
                                                TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isQuestionActive &&
                                        !alreadyAnswered &&
                                        _showExamCodeForm)
                                      Container(
                                        width:
                                            double.infinity,
                                        padding:
                                            const EdgeInsets.all(
                                          20,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .verified_user_outlined,
                                                  color:
                                                      Color(0xFFFFC107),
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Exam Verification",
                                                    style:
                                                        TextStyle(
                                                      color:
                                                          Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const Text(
                                              "Enter the exam code to continue to the protected examination.",
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.white60,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                            TextField(
                                              controller:
                                                  _examCodeController,
                                              enabled:
                                                  !verifyingCode,
                                              keyboardType:
                                                  TextInputType.number,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onSubmitted:
                                                  verifyingCode
                                                      ? null
                                                      : (_) =>
                                                          verifyAndOpenQuestion(),
                                              style:
                                                  const TextStyle(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w800,
                                                letterSpacing: 2,
                                              ),
                                              decoration:
                                                  InputDecoration(
                                                hintText:
                                                    "Enter Exam Code",
                                                hintStyle:
                                                    const TextStyle(
                                                  color:
                                                      Colors.white38,
                                                  letterSpacing: 0,
                                                ),
                                                errorText:
                                                    _examCodeError,
                                                filled: true,
                                                fillColor:
                                                    const Color(
                                                  0xFF0F172A,
                                                ),
                                                border:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    16,
                                                  ),
                                                  borderSide:
                                                      BorderSide.none,
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    16,
                                                  ),
                                                  borderSide:
                                                      BorderSide.none,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    16,
                                                  ),
                                                  borderSide:
                                                      const BorderSide(
                                                    color:
                                                        Color(
                                                      0xFFFFC107,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 14,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      OutlinedButton(
                                                    onPressed:
                                                        verifyingCode
                                                            ? null
                                                            : cancelExamCodeVerification,
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.white70,
                                                      side:
                                                          const BorderSide(
                                                        color:
                                                            Colors.white24,
                                                      ),
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        vertical:
                                                            16,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          15,
                                                        ),
                                                      ),
                                                    ),
                                                    child:
                                                        const Text(
                                                      "CANCEL",
                                                      style:
                                                          TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 12,
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child:
                                                      ElevatedButton(
                                                    onPressed:
                                                        verifyingCode
                                                            ? null
                                                            : verifyAndOpenQuestion,
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                        0xFFFFC107,
                                                      ),
                                                      foregroundColor:
                                                          Colors.black,
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        vertical:
                                                            16,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          15,
                                                        ),
                                                      ),
                                                    ),
                                                    child:
                                                        verifyingCode
                                                            ? const SizedBox(
                                                                width: 22,
                                                                height: 22,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2.5,
                                                                  color:
                                                                      Colors.black,
                                                                ),
                                                              )
                                                            : const Text(
                                                                "VERIFY & START",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight.w900,
                                                                ),
                                                              ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (alreadyAnswered)
                                      Container(
                                        padding:
                                            const EdgeInsets.all(
                                          18,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "You have already submitted your answer.",
                                            style:
                                                TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
