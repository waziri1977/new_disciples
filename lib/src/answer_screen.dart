// answer_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

class AnswerScreen
    extends StatefulWidget {

  final Map userData;
  final Map questionData;

  const AnswerScreen({
    super.key,
    required this.userData,
    required this.questionData,
  });

  @override
  State<AnswerScreen>
  createState() =>
      _AnswerScreenState();
}

class _AnswerScreenState
    extends State<AnswerScreen> {

  final answerController =
  TextEditingController();

  Duration countdown =
      Duration.zero;

  Timer? timer;

  bool isExpired = false;

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

  @override
  void initState() {
    super.initState();

    startCountdown();
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
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF070B14),

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title: const Text(
          "Write Answer",
        ),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(
            24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [

            //////////////////////////////////////////////////////
            /// COUNTDOWN CARD
            //////////////////////////////////////////////////////

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
                ),

                borderRadius:
                BorderRadius
                    .circular(
                    30),
              ),

              child: Column(
                children: [

                  Text(

                    isExpired

                        ? "TIME EXPIRED"

                        : "TIME REMAINING",

                    style:
                    const TextStyle(
                      color:
                      Colors.white70,

                      letterSpacing:
                      1.2,
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  Text(
                    formatTime(
                        countdown),

                    style:
                    const TextStyle(
                      color:
                      Colors.white,

                      fontSize:
                      40,

                      fontWeight:
                      FontWeight
                          .w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            //////////////////////////////////////////////////////
            /// QUESTION
            //////////////////////////////////////////////////////

            Text(
              widget.questionData[
              'question']
                  .toString(),

              style:
              const TextStyle(
                color:
                Colors.white,

                fontSize: 28,

                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(height: 25),

            //////////////////////////////////////////////////////
            /// ANSWER FIELD
            //////////////////////////////////////////////////////

            Expanded(
              child: TextField(
                controller:
                answerController,

                enabled:
                !isExpired,

                maxLines: null,

                expands: true,

                style:
                const TextStyle(
                  color:
                  Colors.white,
                ),

                decoration:
                InputDecoration(
                  hintText:
                  "Write your answer here...",

                  hintStyle:
                  const TextStyle(
                    color:
                    Colors.white38,
                  ),

                  filled: true,

                  fillColor:
                  const Color(
                      0xFF161B22),

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        24),

                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            //////////////////////////////////////////////////////
            /// SUBMIT BUTTON
            //////////////////////////////////////////////////////

            SizedBox(
              width:
              double.infinity,

              height:
              62,

              child:
              ElevatedButton(
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:

                  isExpired

                      ? Colors.grey

                      : const Color(
                      0xFFFFC107),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        22),
                  ),
                ),

                onPressed:

                isExpired

                    ? null

                    : () {},

                child: Text(

                  isExpired

                      ? "TIME EXPIRED"

                      : "SUBMIT ANSWER",

                  style:
                  const TextStyle(
                    color:
                    Colors.black,

                    fontWeight:
                    FontWeight
                        .w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}