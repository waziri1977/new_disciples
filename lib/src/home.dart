// home.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

import 'question.dart';

class HomeScreen
    extends StatefulWidget {

  final Map userData;

  const HomeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<HomeScreen>
  createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/get_live_question.php";

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = true;

  bool isQuestionActive =
  true;

  bool alreadyAnswered =
  false;

  Map questionData = {};

  Duration countdown =
      Duration.zero;

  Timer? timer;

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

      if (data['status'] ==
          true) {

        setState(() {

          questionData =
          data['question'];

          alreadyAnswered =
          questionData[
          'already_answered'];

          isLoading = false;
        });

        startCountdown(
          questionData[
          'end_time'],
        );
      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// START COUNTDOWN
  ////////////////////////////////////////////////////////////

  void startCountdown(
      String endTime) {

    DateTime endDate =
    DateTime.parse(
        endTime);

    timer = Timer.periodic(
      const Duration(
          seconds: 1),

          (timer) {

        final now =
        DateTime.now();

        final difference =
        endDate
            .difference(now);

        if (difference
            .isNegative) {

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

            isQuestionActive =
            true;
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
        n
            .toString()
            .padLeft(2, '0');

    final hours =
    twoDigits(
        duration.inHours);

    final minutes =
    twoDigits(duration
        .inMinutes
        .remainder(60));

    final seconds =
    twoDigits(duration
        .inSeconds
        .remainder(60));

    return "$hours:$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();

    getLiveQuestion();
  }

  @override
  void dispose() {

    timer?.cancel();

    super.dispose();
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

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(
          color: Color(
              0xFFFFC107),
        ),
      )

          : SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets
              .all(24),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [

              //////////////////////////////////////////////////
              /// HEADER
              //////////////////////////////////////////////////

              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      const Text(
                        "Welcome Back 👋",

                        style:
                        TextStyle(
                          color:
                          Colors
                              .white54,
                        ),
                      ),

                      const SizedBox(
                          height:
                          6),

                      Text(
                        widget.userData[
                        'full_name']
                            ?.toString() ??
                            "Contestant",

                        style:
                        const TextStyle(
                          color:
                          Colors
                              .white,

                          fontSize:
                          28,

                          fontWeight:
                          FontWeight
                              .w900,
                        ),
                      ),
                    ],
                  ),

                  //////////////////////////////////////////////////
                  /// NOTIFICATION
                  //////////////////////////////////////////////////

                  Container(
                    padding:
                    const EdgeInsets
                        .all(
                        14),

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                          0xFF161B22),

                      borderRadius:
                      BorderRadius.circular(
                          18),
                    ),

                    child:
                    const Icon(
                      Icons
                          .notifications_none,

                      color:
                      Colors
                          .white,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                  height:
                  35),

              //////////////////////////////////////////////////
              /// LIVE QUESTION CARD
              //////////////////////////////////////////////////

              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets
                    .all(
                    26),

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
                      34),

                  boxShadow: [

                    BoxShadow(
                      color: const Color(
                          0xFFFFC107)
                          .withOpacity(
                          0.35),

                      blurRadius:
                      35,
                    ),
                  ],
                ),

                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    //////////////////////////////////////////////////
                    /// STATUS ROW
                    //////////////////////////////////////////////////

                    Row(
                      children: [

                        Icon(
                          Icons
                              .circle,

                          size:
                          12,

                          color:

                          isQuestionActive

                              ? Colors.green

                              : Colors.red,
                        ),

                        const SizedBox(
                            width:
                            8),

                        Text(

                          isQuestionActive

                              ? "QUESTION ACTIVE"

                              : "QUESTION CLOSED",

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
                        height:
                        30),

                    //////////////////////////////////////////////////
                    /// QUESTION
                    //////////////////////////////////////////////////

                    const Text(
                      "ACTIVE QUESTION",

                      style:
                      TextStyle(
                        color: Colors
                            .black54,

                        fontWeight:
                        FontWeight
                            .w700,

                        letterSpacing:
                        1.2,
                      ),
                    ),

                    const SizedBox(
                        height:
                        12),

                    Text(
                      questionData[
                      'question']
                          ?.toString() ??
                          "",

                      style:
                      const TextStyle(
                        color:
                        Colors.black,

                        fontSize:
                        30,

                        height:
                        1.2,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                        height:
                        18),

                    //////////////////////////////////////////////////
                    /// DESCRIPTION
                    //////////////////////////////////////////////////

                    Text(
                      questionData[
                      'description']
                          ?.toString() ??
                          "",

                      style:
                      const TextStyle(
                        color:
                        Colors.black87,

                        fontSize:
                        15,

                        height:
                        1.7,
                      ),
                    ),

                    const SizedBox(
                        height:
                        28),

                    //////////////////////////////////////////////////
                    /// SUBMISSION STATUS
                    //////////////////////////////////////////////////

                    Container(
                      padding:
                      const EdgeInsets
                          .all(
                          18),

                      decoration:
                      BoxDecoration(
                        color: Colors
                            .black
                            .withOpacity(
                            0.08),

                        borderRadius:
                        BorderRadius
                            .circular(
                            22),
                      ),

                      child: Row(
                        children: [

                          Container(
                            height:
                            55,

                            width:
                            55,

                            decoration:
                            const BoxDecoration(
                              color: Colors
                                  .black,

                              shape:
                              BoxShape.circle,
                            ),

                            child:
                            Icon(

                              alreadyAnswered

                                  ? Icons.check_circle

                                  : Icons.edit_note,

                              color:
                              const Color(
                                  0xFFFFC107),

                              size:
                              28,
                            ),
                          ),

                          const SizedBox(
                              width:
                              18),

                          Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                const Text(
                                  "Submission Status",

                                  style:
                                  TextStyle(
                                    color:
                                    Colors.black54,

                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                    6),

                                Text(

                                  alreadyAnswered

                                      ? "Answer Submitted Successfully"

                                      : "You have not submitted your answer yet.",

                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.black,

                                    fontWeight:
                                    FontWeight.w800,

                                    fontSize:
                                    15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height:
                        32),

                    //////////////////////////////////////////////////
                    /// BUTTON
                    //////////////////////////////////////////////////

                    SizedBox(
                      width:
                      double.infinity,

                      height:
                      62,

                      child:
                      ElevatedButton(
                        style:
                        ElevatedButton.styleFrom(

                          backgroundColor:

                          alreadyAnswered

                              ? Colors.green

                              : isQuestionActive

                              ? Colors.black

                              : Colors.grey.shade700,

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                22),
                          ),
                        ),

                        onPressed:

                        isQuestionActive &&
                            !alreadyAnswered

                            ? () {

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
                          );
                        }

                            : null,

                        child:
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,

                          children: [

                            Icon(

                              alreadyAnswered

                                  ? Icons.check_circle

                                  : isQuestionActive

                                  ? Icons.edit

                                  : Icons.lock_clock,

                              color:
                              const Color(
                                  0xFFFFC107),
                            ),

                            const SizedBox(
                                width:
                                10),

                            Text(

                              alreadyAnswered

                                  ? "ANSWER SUBMITTED"

                                  : isQuestionActive

                                  ? "WRITE YOUR ANSWER"

                                  : "QUESTION CLOSED",

                              style:
                              const TextStyle(
                                color:
                                Color(
                                    0xFFFFC107),

                                fontWeight:
                                FontWeight.w900,
                              ),
                            ),
                          ],
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