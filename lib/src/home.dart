// home.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'question.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {

  final Map userData;

  const HomeScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen>

    with WidgetsBindingObserver {

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/get_live_question.php";

  final String disqualifyApi =
      "https://new-disciples.com/api/disqualify_user.php";

  final String logoutApi =
      "https://new-disciples.com/api/logout.php";

  final String verifyExamCodeApi =
      "https://new-disciples.com/api/verify_exam_code.php";

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = true;

  bool isQuestionActive = false;

  bool alreadyAnswered = false;

  bool disqualified = false;

  bool verifyingCode = false;

  Map questionData = {};

  Duration countdown =
      Duration.zero;

  Timer? timer;

  ////////////////////////////////////////////////////////////
  /// INIT
  ////////////////////////////////////////////////////////////

  @override
  void initState() {

    super.initState();

    //////////////////////////////////////////////////////////
    /// OBSERVER
    //////////////////////////////////////////////////////////

    WidgetsBinding.instance
        .addObserver(this);

    //////////////////////////////////////////////////////////
    /// FETCH QUESTION
    //////////////////////////////////////////////////////////

    getLiveQuestion();
  }

  ////////////////////////////////////////////////////////////
  /// DISPOSE
  ////////////////////////////////////////////////////////////

  @override
  void dispose() {

    timer?.cancel();

    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }

  ////////////////////////////////////////////////////////////
  /// APP LIFECYCLE
  ////////////////////////////////////////////////////////////

  @override
  void didChangeAppLifecycleState(

      AppLifecycleState state

      ){

    //////////////////////////////////////////////////////////
    /// APP MINIMIZED
    //////////////////////////////////////////////////////////

    if(

    state ==
        AppLifecycleState.paused

        ||

        state ==
            AppLifecycleState.detached

        ||

        state ==
            AppLifecycleState.inactive

    ){

      ////////////////////////////////////////////////////////
      /// LIVE EXAM ONLY
      ////////////////////////////////////////////////////////

      if(

      isQuestionActive
          &&
          !alreadyAnswered
          &&
          !disqualified

      ){

        disqualifyUser();
      }
    }
  }

  ////////////////////////////////////////////////////////////
  /// GET LIVE QUESTION
  ////////////////////////////////////////////////////////////

  Future<void>
  getLiveQuestion() async {

    try {

      final response =
      await http.get(

        Uri.parse(

            "$apiUrl?contestant_id=${widget.userData['id']}"
        ),
      );

      final data =
      jsonDecode(response.body);

      ////////////////////////////////////////////////////////
      /// SUCCESS
      ////////////////////////////////////////////////////////

      if (data['status']
          == true) {

        setState(() {

          questionData =
          data['question'];

          alreadyAnswered =
              data['already_answered']
                  ?? false;

          isQuestionActive =
          true;

          isLoading =
          false;
        });

        //////////////////////////////////////////////////////
        /// START TIMER
        //////////////////////////////////////////////////////

        startCountdown(
          questionData['end_time'],
        );

      } else {

        setState(() {

          isQuestionActive =
          false;

          isLoading =
          false;
        });
      }

    } catch (e) {

      setState(() {

        isLoading = false;
      });

      print(e);
    }
  }

  ////////////////////////////////////////////////////////////
  /// DISQUALIFY USER
  ////////////////////////////////////////////////////////////

  Future<void>
  disqualifyUser() async {

    //////////////////////////////////////////////////////////
    /// PREVENT MULTIPLE CALLS
    //////////////////////////////////////////////////////////

    if(disqualified) return;

    disqualified = true;

    try {

      await http.post(

        Uri.parse(
            disqualifyApi
        ),

        body: {

          "user_id":

          widget.userData['id']
              .toString(),
        },
      );

    } catch (e) {

      print(e);
    }

    //////////////////////////////////////////////////////////
    /// SHOW BLOCK
    //////////////////////////////////////////////////////////

    if(mounted){

      showDialog(

        context: context,

        barrierDismissible: false,

        builder: (_) {

          return WillPopScope(

            onWillPop: () async =>
            false,

            child: AlertDialog(

              backgroundColor:
              const Color(
                  0xFF161B22),

              shape:
              RoundedRectangleBorder(

                borderRadius:
                BorderRadius.circular(
                    24),
              ),

              title: const Text(

                "Disqualified",

                style: TextStyle(

                  color: Colors.red,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              content: const Text(

                "You minimized or exited the mock screen during a live session.\n\nYou have been automatically disqualified for malpractice.",

                style: TextStyle(

                  color: Colors.white70,

                  height: 1.7,
                ),
              ),

              actions: [

                ElevatedButton(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.red,
                  ),

                  onPressed: () {

                    exit(0);
                  },

                  child: const Text(

                    "EXIT",

                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  ////////////////////////////////////////////////////////////
  /// START COUNTDOWN
  ////////////////////////////////////////////////////////////

  void startCountdown(
      String endTime) {

    DateTime endDate =
    DateTime.parse(endTime);

    timer = Timer.periodic(

      const Duration(seconds: 1),

          (timer) {

        final now =
        DateTime.now();

        final difference =
        endDate.difference(now);

        //////////////////////////////////////////////////////
        /// ENDED
        //////////////////////////////////////////////////////

        if (difference.isNegative) {

          timer.cancel();

          setState(() {

            isQuestionActive =
            false;

            countdown =
                Duration.zero;
          });

        } else {

          setState(() {

            countdown =
                difference;
          });
        }
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// FORMAT TIME
  ////////////////////////////////////////////////////////////

  String formatTime(
      Duration duration) {

    String twoDigits(int n) =>
        n.toString()
            .padLeft(2, '0');

    final hours =
    twoDigits(
        duration.inHours);

    final minutes =
    twoDigits(
        duration.inMinutes
            .remainder(60));

    final seconds =
    twoDigits(
        duration.inSeconds
            .remainder(60));

    return "$hours:$minutes:$seconds";
  }

  ////////////////////////////////////////////////////////////
  /// OPEN QUESTION
  ////////////////////////////////////////////////////////////

  void openQuestion() {

    final codeController =
    TextEditingController();

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (_) {

        return StatefulBuilder(

          builder: (context,setModalState){

            return AlertDialog(

              backgroundColor:
              const Color(
                  0xFF161B22),

              shape:
              RoundedRectangleBorder(

                borderRadius:
                BorderRadius.circular(
                    24),
              ),

              title: const Text(

                "Exam Verification",

                style: TextStyle(

                  color: Colors.white,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              content: Column(

                mainAxisSize:
                MainAxisSize.min,

                children: [

                  const Text(

                    "Enter the mock verification code before proceeding.",

                    style: TextStyle(

                      color:
                      Colors.white70,

                      height: 1.7,
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  TextField(

                    controller:
                    codeController,

                    style:
                    const TextStyle(

                      color:
                      Colors.white,
                    ),

                    decoration:
                    InputDecoration(

                      hintText:
                      "Enter Exam Code",

                      hintStyle:
                      const TextStyle(

                        color:
                        Colors.white38,
                      ),

                      filled: true,

                      fillColor:
                      const Color(
                          0xFF0F172A),

                      border:
                      OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(
                            18),

                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(
                        context);
                  },

                  child: const Text(

                    "Cancel",

                    style: TextStyle(
                      color:
                      Colors.white54,
                    ),
                  ),
                ),

                ElevatedButton(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(
                        0xFFFFC107),
                  ),

                  onPressed:
                  verifyingCode

                      ? null

                      : () async {

                    setModalState(() {

                      verifyingCode =
                      true;
                    });

                    //////////////////////////////////////////////////
                    /// VERIFY CODE
                    //////////////////////////////////////////////////

                    try {

                      final response =
                      await http.post(

                        Uri.parse(
                            verifyExamCodeApi
                        ),

                        body: {

                          "contestant_id":

                          widget.userData['id']
                              .toString(),

                          "question_id":

                          questionData['id']
                              .toString(),

                          "exam_code":

                          codeController.text
                              .trim(),
                        },
                      );

                      final data =
                      jsonDecode(
                          response.body
                      );

                      //////////////////////////////////////////////////
                      /// SUCCESS
                      //////////////////////////////////////////////////

                      if(

                      data['status']
                          == true

                      ){

                        Navigator.pop(
                            context);

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                QuestionScreen(

                                  userData:
                                  widget.userData,

                                  questionData:
                                  questionData,
                                ),
                          ),
                        ).then((_) {

                          //////////////////////////////////////////////////
                          /// REFRESH
                          //////////////////////////////////////////////////

                          getLiveQuestion();
                        });

                      } else {

                        ScaffoldMessenger.of(
                            context)

                            .showSnackBar(

                          SnackBar(

                            backgroundColor:
                            Colors.red,

                            content: Text(

                              data['message'],

                              style:
                              const TextStyle(

                                color:
                                Colors.white,
                              ),
                            ),
                          ),
                        );
                      }

                    } catch (e) {

                      print(e);

                    } finally {

                      setModalState(() {

                        verifyingCode =
                        false;
                      });
                    }
                  },

                  child:

                  verifyingCode

                      ? const SizedBox(

                    width: 20,
                    height: 20,

                    child:
                    CircularProgressIndicator(

                      strokeWidth: 2,

                      color:
                      Colors.black,
                    ),
                  )

                      : const Text(

                    "VERIFY",

                    style: TextStyle(

                      color:
                      Colors.black,

                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// LOGOUT
  ////////////////////////////////////////////////////////////

  Future<void> logout() async {

    try {

      ////////////////////////////////////////////////////////
      /// UPDATE LOGIN STATUS
      ////////////////////////////////////////////////////////

      await http.post(

        Uri.parse(logoutApi),

        body: {

          "user_id":

          widget.userData['id']
              .toString(),
        },
      );

    } catch (e) {

      print(e);
    }

    //////////////////////////////////////////////////////////
    /// GO TO LOGIN
    //////////////////////////////////////////////////////////

    if(mounted){

      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(

          builder: (_) =>
          const LoginScreen(),
        ),

            (route) => false,
      );
    }
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(
          0xFF070B14),

      //////////////////////////////////////////////////////////
      /// APP BAR
      //////////////////////////////////////////////////////////

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title: const Text(

          "New Disciples",

          style: TextStyle(

            fontWeight:
            FontWeight.w900,
          ),
        ),

        actions: [

          IconButton(

            onPressed: logout,

            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      //////////////////////////////////////////////////////////
      /// BODY
      //////////////////////////////////////////////////////////

      body: isLoading

          ? const Center(

        child:
        CircularProgressIndicator(

          color:
          Color(
              0xFFFFC107),
        ),
      )

          : SafeArea(

        child:
        SingleChildScrollView(

          padding:
          const EdgeInsets.all(
              24),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [

              //////////////////////////////////////////////////
              /// USER
              //////////////////////////////////////////////////

              Text(

                "Welcome, ${widget.userData['full_name']}",

                style:
                const TextStyle(

                  color:
                  Colors.white,

                  fontSize: 28,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                  height: 10),

              const Text(

                "Prepare for your live mock session.",

                style: TextStyle(

                  color:
                  Colors.white54,

                  height: 1.7,
                ),
              ),

              const SizedBox(
                  height: 35),

              //////////////////////////////////////////////////
              /// QUESTION CARD
              //////////////////////////////////////////////////

              Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets.all(
                    28),

                decoration:
                BoxDecoration(

                  gradient:
                  const LinearGradient(

                    colors: [

                      Color(
                          0xFFFFC107),

                      Color(
                          0xFFFFB300),
                    ],
                  ),

                  borderRadius:
                  BorderRadius.circular(
                      35),
                ),

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    //////////////////////////////////////////////////
                    /// STATUS
                    //////////////////////////////////////////////////

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
                            width: 8),

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

                        //////////////////////////////////////////////////
                        /// TIMER
                        //////////////////////////////////////////////////

                        if(
                        isQuestionActive
                        )

                          Row(

                            children: [

                              const Icon(

                                Icons.timer,

                                color:
                                Colors.black,
                              ),

                              const SizedBox(
                                  width:
                                  6),

                              Text(

                                formatTime(
                                    countdown),

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
                        height: 30),

                    //////////////////////////////////////////////////
                    /// QUESTION
                    //////////////////////////////////////////////////

                    Text(

                      isQuestionActive

                          ? questionData[
                      'question']

                          : "No active question currently.",

                      style:
                      const TextStyle(

                        color:
                        Colors.black,

                        fontSize:
                        28,

                        height: 1.2,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                        height: 20),

                    //////////////////////////////////////////////////
                    /// BUTTON
                    //////////////////////////////////////////////////

                    if(
                    isQuestionActive
                        &&
                        !alreadyAnswered
                    )

                      SizedBox(

                        width:
                        double.infinity,

                        height: 60,

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
                                  18),
                            ),
                          ),

                          onPressed:
                          openQuestion,

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

                    //////////////////////////////////////////////////
                    /// ALREADY ANSWERED
                    //////////////////////////////////////////////////

                    if(alreadyAnswered)

                      Container(

                        padding:
                        const EdgeInsets
                            .all(18),

                        decoration:
                        BoxDecoration(

                          color:
                          Colors.black,

                          borderRadius:
                          BorderRadius.circular(
                              18),
                        ),

                        child:
                        const Center(

                          child: Text(

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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}