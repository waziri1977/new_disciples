// questions.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

class QuestionScreen
    extends StatefulWidget {

  final Map userData;
  final Map questionData;

  const QuestionScreen({
    super.key,
    required this.userData,
    required this.questionData,
  });

  @override
  State<QuestionScreen>
  createState() =>
      _QuestionScreenState();
}

class _QuestionScreenState
    extends State<QuestionScreen> {

  ////////////////////////////////////////////////////////////
  /// CONTROLLER
  ////////////////////////////////////////////////////////////

  final answerController =
  TextEditingController();

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = false;

  bool isExpired = false;

  Duration countdown =
      Duration.zero;

  Timer? timer;

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String submitApi =
      "https://new-disciples.com/api/submit_answer.php";

  ////////////////////////////////////////////////////////////
  /// START COUNTDOWN
  ////////////////////////////////////////////////////////////

  void startCountdown() {

    DateTime endDate =
    DateTime.parse(
      widget.questionData['end_time'],
    );

    timer = Timer.periodic(
      const Duration(seconds: 1),

          (timer) {

        final now =
        DateTime.now();

        final difference =
        endDate.difference(now);

        if (difference.isNegative) {

          timer.cancel();

          setState(() {

            isExpired = true;

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
        n.toString().padLeft(2, '0');

    final hours =
    twoDigits(duration.inHours);

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
  /// SUBMIT ANSWER
  ////////////////////////////////////////////////////////////

  Future<void> submitAnswer()
  async {

    if (answerController.text
        .isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text(
            "Write your answer",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response =
      await http.post(

        Uri.parse(submitApi),

        body: {

          "contestant_id":

          widget.userData['id']
              .toString(),

          "question_id":

          widget.questionData[
          'id']
              .toString(),

          "answer":

          answerController.text,
        },
      );

      final data =
      jsonDecode(
          response.body);

      setState(() {
        isLoading = false;
      });

      ////////////////////////////////////////////////////////
      /// SUCCESS
      ////////////////////////////////////////////////////////

      if (data['status'] ==
          true) {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          SnackBar(
            backgroundColor:
            Colors.green,

            content:
            Text(
              data['message'],
            ),
          ),
        );

        //////////////////////////////////////////////////////
        /// RETURN TO HOME
        //////////////////////////////////////////////////////

        Future.delayed(
          const Duration(
              seconds: 1),

              () {

            Navigator.pop(
                context,
                true);
          },
        );

      } else {

        //////////////////////////////////////////////////////
        /// FAILED
        //////////////////////////////////////////////////////

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          SnackBar(
            backgroundColor:
            Colors.red,

            content:
            Text(
              data['message'],
            ),
          ),
        );
      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          backgroundColor:
          Colors.red,

          content:
          Text(
            "Submission Failed",
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    startCountdown();
  }

  @override
  void dispose() {

    timer?.cancel();

    answerController.dispose();

    super.dispose();
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset:
      true,

      backgroundColor:
      const Color(
          0xFF070B14),

      body: SafeArea(
        child:
        SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior
              .onDrag,

          padding:
          const EdgeInsets.all(
              24),

          child: ConstrainedBox(
            constraints:
            BoxConstraints(
              minHeight:
              MediaQuery.of(
                  context)
                  .size
                  .height -
                  100,
            ),

            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  //////////////////////////////////////////////////
                  /// HEADER
                  //////////////////////////////////////////////////

                  Row(
                    children: [

                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                              context);
                        },

                        child:
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
                                .arrow_back,

                            color:
                            Colors
                                .white,
                          ),
                        ),
                      ),

                      const SizedBox(
                          width:
                          18),

                      const Expanded(
                        child: Text(
                          "Answer Question",

                          style:
                          TextStyle(
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
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 30),

                  //////////////////////////////////////////////////
                  /// COUNTDOWN CARD
                  //////////////////////////////////////////////////

                  Container(
                    width:
                    double.infinity,

                    padding:
                    const EdgeInsets
                        .all(24),

                    decoration:
                    BoxDecoration(
                      gradient:
                      LinearGradient(
                        colors: [

                          isExpired

                              ? Colors.red

                              : Colors.green,

                          Colors.black,
                        ],

                        begin:
                        Alignment
                            .topLeft,

                        end:
                        Alignment
                            .bottomRight,
                      ),

                      borderRadius:
                      BorderRadius
                          .circular(
                          30),

                      boxShadow: [

                        BoxShadow(
                          color:

                          isExpired

                              ? Colors.red
                              .withOpacity(
                              0.4)

                              : Colors.green
                              .withOpacity(
                              0.4),

                          blurRadius:
                          25,
                        ),
                      ],
                    ),

                    child: Column(
                      children: [

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                          children: [

                            Icon(

                              isExpired

                                  ? Icons
                                  .lock_clock

                                  : Icons
                                  .timer,

                              color:
                              Colors
                                  .white,
                            ),

                            const SizedBox(
                                width:
                                10),

                            Text(

                              isExpired

                                  ? "QUESTION CLOSED"

                                  : "TIME REMAINING",

                              style:
                              const TextStyle(
                                color:
                                Colors
                                    .white,

                                fontWeight:
                                FontWeight
                                    .w800,

                                letterSpacing:
                                1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height:
                            18),

                        Text(
                          formatTime(
                              countdown),

                          style:
                          const TextStyle(
                            color:
                            Colors
                                .white,

                            fontSize:
                            42,

                            fontWeight:
                            FontWeight
                                .w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 28),

                  //////////////////////////////////////////////////
                  /// QUESTION CARD
                  //////////////////////////////////////////////////

                  Container(
                    width:
                    double.infinity,

                    padding:
                    const EdgeInsets
                        .all(24),

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                          0xFF161B22),

                      borderRadius:
                      BorderRadius
                          .circular(
                          30),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [

                        ////////////////////////////////////////////////
                        /// ACTIVE LABEL
                        ////////////////////////////////////////////////

                        Row(
                          children: [

                            Icon(
                              Icons.circle,

                              size: 12,

                              color:

                              isExpired

                                  ? Colors.red

                                  : Colors.green,
                            ),

                            const SizedBox(
                                width:
                                8),

                            Text(

                              isExpired

                                  ? "QUESTION CLOSED"

                                  : "QUESTION ACTIVE",

                              style:
                              TextStyle(

                                color:

                                isExpired

                                    ? Colors.red

                                    : Colors.green,

                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height:
                            22),

                        ////////////////////////////////////////////////
                        /// QUESTION
                        ////////////////////////////////////////////////

                        Text(
                          widget.questionData[
                          'question']
                              .toString(),

                          style:
                          const TextStyle(
                            color:
                            Colors
                                .white,

                            fontSize:
                            28,

                            height:
                            1.3,

                            fontWeight:
                            FontWeight
                                .w900,
                          ),
                        ),

                        const SizedBox(
                            height:
                            18),

                        ////////////////////////////////////////////////
                        /// DESCRIPTION
                        ////////////////////////////////////////////////

                        Text(
                          widget.questionData[
                          'description']
                              ?.toString() ??
                              "",

                          style:
                          const TextStyle(
                            color:
                            Colors
                                .white54,

                            height:
                            1.7,

                            fontSize:
                            15,
                          ),
                        ),

                        const SizedBox(
                            height:
                            28),

                        ////////////////////////////////////////////////
                        /// ANSWER FIELD
                        ////////////////////////////////////////////////

                        SizedBox(
                          height:
                          320,

                          child:
                          TextField(
                            controller:
                            answerController,

                            enabled:
                            !isExpired,

                            maxLines:
                            null,

                            expands:
                            true,

                            style:
                            const TextStyle(
                              color:
                              Colors
                                  .white,
                            ),

                            decoration:
                            InputDecoration(
                              hintText:
                              "Write your answer here...",

                              hintStyle:
                              const TextStyle(
                                color:
                                Colors
                                    .white38,
                              ),

                              filled:
                              true,

                              fillColor:
                              const Color(
                                  0xFF070B14),

                              contentPadding:
                              const EdgeInsets
                                  .all(
                                  24),

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    24),

                                borderSide:
                                BorderSide.none,
                              ),
                            ),

                            onChanged:
                                (value) {
                              setState(
                                      () {});
                            },
                          ),
                        ),

                        const SizedBox(
                            height:
                            18),

                        ////////////////////////////////////////////////
                        /// CHARACTER COUNT
                        ////////////////////////////////////////////////

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                          children: [

                            Text(
                              "${answerController.text.length} Characters",

                              style:
                              const TextStyle(
                                color:
                                Colors
                                    .white38,
                              ),
                            ),

                            Text(

                              isExpired

                                  ? "Submission Closed"

                                  : "Submission Open",

                              style:
                              TextStyle(

                                color:

                                isExpired

                                    ? Colors.red

                                    : Colors.green,

                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height:
                            24),

                        ////////////////////////////////////////////////
                        /// SUBMIT BUTTON
                        ////////////////////////////////////////////////

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

                              isExpired

                                  ? Colors.grey
                                  .shade700

                                  : const Color(
                                  0xFFFFC107),

                              elevation:
                              0,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    22),
                              ),
                            ),

                            onPressed:

                            isExpired ||
                                isLoading

                                ? null

                                : () async {

                              await submitAnswer();
                            },

                            child:

                            isLoading

                                ? const CircularProgressIndicator(
                              color:
                              Colors.black,
                            )

                                : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children: [

                                Icon(

                                  isExpired

                                      ? Icons.lock

                                      : Icons.send,

                                  color:
                                  Colors.black,
                                ),

                                const SizedBox(
                                    width:
                                    10),

                                Text(

                                  isExpired

                                      ? "QUESTION CLOSED"

                                      : "SUBMIT ANSWER",

                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.black,

                                    fontSize:
                                    15,

                                    letterSpacing:
                                    0.5,

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

                  const SizedBox(
                      height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}