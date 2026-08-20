// home.dart
//
// NEW DISCIPLES - WEB/MOBILE SAFE HOME SCREEN
//
// IMPORTANT SECURITY ARCHITECTURE:
//
// HomeScreen DOES NOT disqualify contestants.
//
// Why?
// HomeScreen remains mounted underneath QuestionScreen after Navigator.push().
// If HomeScreen also watches lifecycle changes, opening F12/DevTools,
// changing browser focus, or QuestionScreen transitions can trigger a second
// disqualification path.
//
// QuestionScreen is now the ONLY client-side exam-malpractice detector.
// PHP report_exam_violation.php is the ONLY server-side malpractice enforcer.
//
// HomeScreen only:
// - polls for a live question
// - shows countdown
// - verifies exam code
// - opens QuestionScreen
// - refreshes on resume
// - logs out
//
// This keeps Android/iOS/Web behavior consistent.

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
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  static const String apiUrl =
      "https://new-disciples.com/api/get_live_question.php";

  static const String logoutApi =
      "https://new-disciples.com/api/logout.php";

  static const String verifyExamCodeApi =
      "https://new-disciples.com/api/verify_exam_code.php";

  ////////////////////////////////////////////////////////////
  /// STATE
  ////////////////////////////////////////////////////////////

  bool isLoading = true;
  bool isQuestionActive = false;
  bool alreadyAnswered = false;
  bool disqualified = false;
  bool alreadyQualified = false;
  String qualificationMessage = "";
  bool verifyingCode = false;
  bool fetchingQuestion = false;
  bool _disqualificationDialogShown = false;

  // Inline exam-code verification.
  // We intentionally do NOT use showDialog here because the previous
  // dialog route was the point where Flutter hit the
  // `_dependents.isEmpty` framework assertion on some devices.
  final TextEditingController _examCodeController =
      TextEditingController();

  bool _showExamCodeForm = false;
  String? _examCodeError;

  Map<String, dynamic> questionData = {};

  Duration countdown = Duration.zero;

  Timer? timer;
  Timer? liveQuestionRefreshTimer;

  static const Duration liveQuestionRefreshInterval =
      Duration(seconds: 3);

  ////////////////////////////////////////////////////////////
  /// DEVELOPMENT INFO
  ////////////////////////////////////////////////////////////

  bool get isDevelopmentWeb {
    if (!kIsWeb) {
      return false;
    }

    final String host =
        Uri.base.host.toLowerCase();

    return host == "localhost" ||
        host == "127.0.0.1";
  }

  ////////////////////////////////////////////////////////////
  /// INIT
  ////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    getLiveQuestion(
      showLoader: true,
    );

    startLiveQuestionRefresh();
  }

  ////////////////////////////////////////////////////////////
  /// DISPOSE
  ////////////////////////////////////////////////////////////

  @override
  void dispose() {
    timer?.cancel();
    liveQuestionRefreshTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    _examCodeController.dispose();

    super.dispose();
  }

  ////////////////////////////////////////////////////////////
  /// APP LIFECYCLE
  ///
  /// IMPORTANT:
  /// HomeScreen no longer performs malpractice enforcement.
  ///
  /// QuestionScreen owns that responsibility.
  ////////////////////////////////////////////////////////////

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      if (!disqualified) {
        getLiveQuestion(
          showLoader: false,
        );
      }
    }
  }

  ////////////////////////////////////////////////////////////
  /// AUTO REFRESH LIVE QUESTION
  ////////////////////////////////////////////////////////////

  void startLiveQuestionRefresh() {
    liveQuestionRefreshTimer?.cancel();

    liveQuestionRefreshTimer =
        Timer.periodic(
      liveQuestionRefreshInterval,
      (_) {
        if (!mounted ||
            disqualified ||
            alreadyQualified) {
          return;
        }

        getLiveQuestion(
          showLoader: false,
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// GET LIVE QUESTION
  ////////////////////////////////////////////////////////////

  Future<void> getLiveQuestion({
    bool showLoader = false,
  }) async {
    if (fetchingQuestion ||
        disqualified) {
      return;
    }

    fetchingQuestion = true;

    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final Uri uri =
          Uri.parse(
        "$apiUrl"
        "?contestant_id=${widget.userData['id']}"
        "&_=${DateTime.now().millisecondsSinceEpoch}",
      );

      final http.Response response =
          await http
              .get(
                uri,
                headers: {
                  "Accept":
                      "application/json",

                  "Cache-Control":
                      "no-cache, no-store, must-revalidate",

                  "Pragma":
                      "no-cache",
                },
              )
              .timeout(
                const Duration(
                  seconds: 15,
                ),
              );

      debugPrint(
        "LIVE QUESTION HTTP: ${response.statusCode}",
      );

      debugPrint(
        "LIVE QUESTION RESPONSE: ${response.body}",
      );

      Map<String, dynamic> data = {};

      if (response.body.trim().isNotEmpty) {
        try {
          final dynamic decoded =
              jsonDecode(
            response.body,
          );

          if (decoded is Map) {
            data =
                Map<String, dynamic>.from(
              decoded,
            );
          }
        } catch (e) {
          debugPrint(
            "LIVE QUESTION JSON ERROR: $e",
          );
        }
      }

      if (!mounted) {
        return;
      }

      ////////////////////////////////////////////////////////
      /// DISQUALIFIED
      ///
      /// Stop polling immediately so we do not create dozens
      /// of repeated 403 requests.
      ////////////////////////////////////////////////////////

      final String contestantStatus =
          data['contestant_status']
                  ?.toString()
                  .toLowerCase()
                  .trim() ??
              "";

      final bool serverDisqualified =
          data['disqualified'] == true ||
              contestantStatus ==
                  "disqualified";

      if (serverDisqualified) {
        timer?.cancel();
        liveQuestionRefreshTimer
            ?.cancel();

        setState(() {
          disqualified = true;
          isQuestionActive = false;
          alreadyAnswered = false;
          isLoading = false;
          countdown =
              Duration.zero;
        });

        await _showServerDisqualifiedDialog(
          data['message']?.toString() ??
              "Contestant is no longer eligible.",
        );

        return;
      }

      ////////////////////////////////////////////////////////
      /// OTHER HTTP ERROR
      ////////////////////////////////////////////////////////

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data['message']?.toString() ??
              "Server returned ${response.statusCode}",
        );
      }

      ////////////////////////////////////////////////////////
      /// ALREADY QUALIFIED
      ///
      /// Exact server message is shown on the Home screen.
      /// This prevents the blank screen that occurred when
      /// question=null was returned.
      ////////////////////////////////////////////////////////

      final bool serverAlreadyQualified =
          data['already_qualified'] == true;

      if (serverAlreadyQualified) {
        timer?.cancel();
        liveQuestionRefreshTimer?.cancel();

        setState(() {
          alreadyQualified = true;
          qualificationMessage =
              data['message']?.toString().trim().isNotEmpty == true
                  ? data['message'].toString()
                  : "You have already qualified for the judging stage.";

          isQuestionActive = false;
          alreadyAnswered = false;
          questionData = {};
          countdown = Duration.zero;
          isLoading = false;
        });

        return;
      }

      ////////////////////////////////////////////////////////
      /// LIVE QUESTION FOUND
      ////////////////////////////////////////////////////////

      if (data['status'] == true) {
        final Map<String, dynamic>
            incomingQuestion =
            Map<String, dynamic>.from(
          data['question'] ?? {},
        );

        //////////////////////////////////////////////////////
        /// IMPORTANT FIX:
        ///
        /// Current PHP returns already_answered INSIDE
        /// the question object.
        ///
        /// Older APIs may return it at top level.
        ///
        /// Support both.
        //////////////////////////////////////////////////////

        final bool incomingAnswered =
            incomingQuestion[
                    'already_answered'] ==
                true ||
            data['already_answered'] ==
                true;

        final String? oldQuestionId =
            questionData['id']
                ?.toString();

        final String? newQuestionId =
            incomingQuestion['id']
                ?.toString();

        final String? oldEndTime =
            questionData['end_time']
                ?.toString();

        final String? newEndTime =
            incomingQuestion['end_time']
                ?.toString();

        final bool questionChanged =
            oldQuestionId !=
                    newQuestionId ||
                oldEndTime !=
                    newEndTime ||
                !isQuestionActive;

        setState(() {
          alreadyQualified = false;
          qualificationMessage = "";

          questionData =
              incomingQuestion;

          alreadyAnswered =
              incomingAnswered;

          isQuestionActive =
              true;

          isLoading =
              false;
        });

        //////////////////////////////////////////////////////
        /// KEEP HOME TIMER RUNNING AFTER SUBMISSION
        ///
        /// The timer is cancelled before QuestionScreen opens.
        /// When the contestant returns after submitting, the
        /// question has not changed, so questionChanged can be
        /// false. The old logic therefore failed to restart the
        /// Home countdown.
        ///
        /// Restart whenever the timer is missing or inactive,
        /// even if alreadyAnswered == true.
        //////////////////////////////////////////////////////

        final bool countdownNeedsRestart =
            questionChanged ||
            timer == null ||
            !(timer?.isActive ?? false);

        if (countdownNeedsRestart &&
            newEndTime != null &&
            newEndTime.isNotEmpty) {
          startCountdown(
            newEndTime,
          );
        }

        return;
      }

      ////////////////////////////////////////////////////////
      /// NO LIVE QUESTION
      ////////////////////////////////////////////////////////

      timer?.cancel();

      setState(() {
        alreadyQualified = false;
        qualificationMessage = "";

        isQuestionActive = false;
        alreadyAnswered = false;
        questionData = {};
        countdown = Duration.zero;
        isLoading = false;
      });
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      debugPrint(
        "Live question timeout: $e",
      );
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      debugPrint(
        "Live question refresh error: $e",
      );

      debugPrint(
        "LIVE QUESTION STACK: $stackTrace",
      );
    } finally {
      fetchingQuestion = false;
    }
  }

  ////////////////////////////////////////////////////////////
  /// SERVER DISQUALIFICATION DIALOG
  ////////////////////////////////////////////////////////////

  Future<void>
      _showServerDisqualifiedDialog(
    String message,
  ) async {
    if (!mounted ||
        _disqualificationDialogShown) {
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
            backgroundColor:
                const Color(
              0xFF161B22,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),

            title:
                const Row(
              children: [
                Icon(
                  Icons.gpp_bad,
                  color:
                      Colors.red,
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    "Disqualified",
                    style:
                        TextStyle(
                      color:
                          Colors.red,
                      fontWeight:
                          FontWeight
                              .w900,
                    ),
                  ),
                ),
              ],
            ),

            content:
                Text(
              message,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                height:
                    1.6,
              ),
            ),

            actions: [
              ElevatedButton(
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.red,
                ),

                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();

                  Navigator
                      .pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(),
                    ),
                    (route) =>
                        false,
                  );
                },

                child:
                    const Text(
                  "CLOSE",
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// START COUNTDOWN
  ////////////////////////////////////////////////////////////

  void startCountdown(
    String endTime,
  ) {
    timer?.cancel();

    final DateTime endDate =
        DateTime.parse(
      endTime,
    );

    void updateCountdown() {
      if (!mounted) {
        return;
      }

      final Duration difference =
          endDate.difference(
        DateTime.now(),
      );

      if (difference.inSeconds <=
          0) {
        timer?.cancel();

        setState(() {
          isQuestionActive = false;
          countdown =
              Duration.zero;
        });

        getLiveQuestion(
          showLoader: false,
        );

        return;
      }

      setState(() {
        countdown = difference;
      });
    }

    updateCountdown();

    timer =
        Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (_) {
        updateCountdown();
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// FORMAT TIME
  ////////////////////////////////////////////////////////////

  String formatTime(
    Duration duration,
  ) {
    String twoDigits(int n) =>
        n.toString().padLeft(
              2,
              '0',
            );

    final String hours =
        twoDigits(
      duration.inHours,
    );

    final String minutes =
        twoDigits(
      duration.inMinutes.remainder(
        60,
      ),
    );

    final String seconds =
        twoDigits(
      duration.inSeconds.remainder(
        60,
      ),
    );

    return "$hours:$minutes:$seconds";
  }

  ////////////////////////////////////////////////////////////
  /// OPEN / VERIFY QUESTION
  ///
  /// IMPORTANT:
  /// We no longer use showDialog/StatefulBuilder for exam-code
  /// verification. The code form is rendered directly inside
  /// HomeScreen. This removes the dialog-route disposal race
  /// that triggered:
  ///
  ///   '_dependents.isEmpty': is not true
  ///
  /// on some Android devices.
  ////////////////////////////////////////////////////////////

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
            body: {
              "contestant_id":
                  widget.userData['id'].toString(),
              "question_id": questionId,
              "exam_code": enteredCode,
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      Map<String, dynamic> data = {};

      if (response.body.trim().isNotEmpty) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          data =
              Map<String, dynamic>.from(
            decoded,
          );
        }
      }

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

      ////////////////////////////////////////////////////////
      /// SUCCESS
      ///
      /// Snapshot the question first. Then hide the inline
      /// verification form. No popup route is being popped.
      ////////////////////////////////////////////////////////

      final Map<String, dynamic> questionSnapshot =
          Map<String, dynamic>.from(
        questionData,
      );

      setState(() {
        verifyingCode = false;
        _showExamCodeForm = false;
        _examCodeError = null;
      });

      // Let the HomeScreen rebuild cleanly before navigation.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      ////////////////////////////////////////////////////////
      /// PAUSE HOME POLLING WHILE EXAM SCREEN IS OPEN
      ////////////////////////////////////////////////////////

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

      if (!disqualified &&
          !alreadyQualified) {
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

  ////////////////////////////////////////////////////////////
  /// LOGOUT
  ////////////////////////////////////////////////////////////

  Future<void> logout() async {
    liveQuestionRefreshTimer?.cancel();
    timer?.cancel();

    try {
      await http
          .post(
            Uri.parse(
              logoutApi,
            ),
            body: {
              "user_id":
                  widget.userData['id']
                      .toString(),
            },
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );
    } catch (e) {
      debugPrint(
        "Logout warning: $e",
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFF070B14,
      ),

      appBar:
          AppBar(
        backgroundColor:
            Colors.transparent,
        elevation:
            0,
        title:
            const Text(
          "New Disciples",
          style:
              TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),

        actions: [
          if (isDevelopmentWeb)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child:
                  Center(
                child: Text(
                  "DEV",
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFFFFC107,
                    ),
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ),

          IconButton(
            onPressed:
                logout,
            icon:
                const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body:
          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        Color(
                      0xFFFFC107,
                    ),
                  ),
                )
              : SafeArea(
                  child:
                      Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            900,
                      ),
                      child:
                          SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, ${widget.userData['full_name']}",
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    28,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  10,
                            ),

                            const Text(
                              "Prepare for your live mock session.",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white54,
                                height:
                                    1.7,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  35,
                            ),

                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets.all(
                                28,
                              ),
                              decoration:
                                  BoxDecoration(
                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    Color(
                                      0xFFFFC107,
                                    ),
                                    Color(
                                      0xFFFFB300,
                                    ),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  35,
                                ),
                              ),
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (alreadyQualified) ...[
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xFFFFC107),
                                            size: 25,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            "QUALIFICATION COMPLETE",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              letterSpacing: .8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 26),
                                    Text(
                                      qualificationMessage.isNotEmpty
                                          ? qualificationMessage
                                          : "You have already qualified for the judging stage.",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                        height: 1.25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      "You do not need to answer another qualification question.",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        height: 1.6,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ] else ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size:
                                            12,
                                        color:
                                            isQuestionActive
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                      const SizedBox(
                                        width:
                                            8,
                                      ),
                                      Text(
                                        isQuestionActive
                                            ? "LIVE QUESTION"
                                            : "NO LIVE QUESTION",
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.black,
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
                                              width:
                                                  6,
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

                                  const SizedBox(
                                    height:
                                        30,
                                  ),

                                  Text(
                                    isQuestionActive
                                        ? questionData['question']?.toString() ??
                                            "Question unavailable."
                                        : "No active question currently.",
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.black,
                                      fontSize:
                                          28,
                                      height:
                                          1.2,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        12,
                                  ),

                                  if (!isQuestionActive)
                                    const Row(
                                      children: [
                                        SizedBox(
                                          width:
                                              14,
                                          height:
                                              14,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Colors.black,
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              10,
                                        ),
                                        Expanded(
                                          child:
                                              Text(
                                            "Waiting for the next live exam • updates automatically",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.black87,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(
                                    height:
                                        20,
                                  ),

                                  if (isQuestionActive &&
                                      !alreadyAnswered &&
                                      !_showExamCodeForm)
                                    SizedBox(
                                      width:
                                          double.infinity,
                                      height:
                                          60,
                                      child:
                                          ElevatedButton(
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
                                        child:
                                            const Text(
                                          "START MOCK",
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
                                            fontWeight:
                                                FontWeight.w900,
                                            fontSize:
                                                16,
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
                                        color:
                                            Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.verified_user_outlined,
                                                color:
                                                    Color(
                                                  0xFFFFC107,
                                                ),
                                              ),
                                              SizedBox(
                                                width:
                                                    10,
                                              ),
                                              Expanded(
                                                child:
                                                    Text(
                                                  "Exam Verification",
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white,
                                                    fontSize:
                                                        18,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height:
                                                10,
                                          ),
                                          const Text(
                                            "Enter the exam code to continue to the protected examination.",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white60,
                                              height:
                                                  1.5,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                16,
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
                                              color:
                                                  Colors.white,
                                              fontWeight:
                                                  FontWeight.w800,
                                              letterSpacing:
                                                  2,
                                            ),
                                            decoration:
                                                InputDecoration(
                                              hintText:
                                                  "Enter Exam Code",
                                              hintStyle:
                                                  const TextStyle(
                                                color:
                                                    Colors.white38,
                                                letterSpacing:
                                                    0,
                                              ),
                                              errorText:
                                                  _examCodeError,
                                              filled:
                                                  true,
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
                                            height:
                                                14,
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
                                                        const EdgeInsets.symmetric(
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
                                                width:
                                                    12,
                                              ),
                                              Expanded(
                                                flex:
                                                    2,
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
                                                        const EdgeInsets.symmetric(
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
                                                              width:
                                                                  22,
                                                              height:
                                                                  22,
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
                                        color:
                                            Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                      ),
                                      child:
                                          const Center(
                                        child:
                                            Text(
                                          "You have already submitted your answer.",
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
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
