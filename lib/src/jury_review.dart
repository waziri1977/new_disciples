// jury_review.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JuryReviewScreen extends StatefulWidget {
  final Map contestant;
  final Map juryData;

  const JuryReviewScreen({
    super.key,
    required this.contestant,
    required this.juryData,
  });

  @override
  State<JuryReviewScreen> createState() =>
      _JuryReviewScreenState();
}

class _JuryReviewScreenState extends State<JuryReviewScreen> {
  final TextEditingController commentController =
      TextEditingController();

  bool isLoading = false;

  double selectedScore = 6.5;

  final String apiUrl =
      "https://new-disciples.com/api/submit_jury_score.php";

  static const List<double> allowedScores = [
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    3.5,
    4.0,
    4.5,
    5.0,
    5.5,
    6.0,
    6.5,
    7.0,
    7.5,
    8.0,
    8.5,
    9.0,
    9.5,
  ];

  String formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String scoreRemark(double value) {
    if (value >= 9.0) return "OUTSTANDING";
    if (value >= 8.0) return "EXCELLENT";
    if (value >= 7.0) return "VERY GOOD";
    if (value >= 6.0) return "GOOD";
    if (value >= 5.0) return "AVERAGE";
    if (value >= 3.0) return "NEEDS IMPROVEMENT";
    return "WEAK";
  }

  Color scoreColor(double value) {
    if (value >= 8.0) {
      return const Color(0xFF22C55E);
    }

    if (value >= 6.0) {
      return const Color(0xFFFFC107);
    }

    if (value >= 4.0) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFFEF4444);
  }

  String maskPhone(dynamic phone) {
    final value =
        phone?.toString().trim() ?? "";

    if (value.length <= 7) {
      return value;
    }

    return "${value.substring(0, 7)}XXX";
  }

  ////////////////////////////////////////////////////////////
  /// SUBMIT JURY REVIEW
  ///
  /// FINAL FLOW:
  ///
  /// contestant_remaining.php
  ///        ↓
  /// CONTINUE contestants
  ///        ↓
  /// get_top10.php
  ///        ↓
  /// jury_dashboard.dart
  ///        ↓
  /// jury_review.dart
  ///        ↓
  /// submit_jury_score.php
  ///
  /// NO round_id is required in this flow.
  ////////////////////////////////////////////////////////////

  Future<void> submitReview() async {
    if (isLoading) {
      return;
    }

    final dynamic contestantId =
        widget.contestant['contestant_id'] ??
        widget.contestant['id'];

    final dynamic juryId =
        widget.juryData['id'];

    final dynamic questionId =
        widget.contestant['question_id'] ??
        widget.contestant['qualified_question_id'];

    debugPrint(
      "JURY REVIEW VALUES => "
      "contestant_id=$contestantId, "
      "jury_id=$juryId, "
      "question_id=$questionId",
    );

    if (contestantId == null ||
        contestantId.toString().trim().isEmpty) {
      showMessage(
        "Contestant information is missing.",
      );

      return;
    }

    if (juryId == null ||
        juryId.toString().trim().isEmpty) {
      showMessage(
        "Jury account information is missing.",
      );

      return;
    }

    if (questionId == null ||
        questionId.toString().trim().isEmpty ||
        questionId.toString() == "0") {
      showMessage(
        "Qualification question information is missing.",
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Accept": "application/json",
        },
        body: {
          "contestant_id":
              contestantId.toString(),

          "jury_id":
              juryId.toString(),

          "question_id":
              questionId.toString(),

          "score":
              selectedScore.toStringAsFixed(
            1,
          ),

          "comment":
              commentController.text.trim(),
        },
      );

      debugPrint(
        "JURY SCORE HTTP ${response.statusCode}",
      );

      debugPrint(
        response.body,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        showMessage(
          "Invalid response received from server.",
        );

        return;
      }

      if (response.statusCode != 200) {
        showMessage(
          data is Map &&
                  data['message'] != null
              ? data['message'].toString()
              : "Server error ${response.statusCode}.",
        );

        return;
      }

      if (data is Map &&
          data['status'] == true) {
        showMessage(
          data['message']?.toString() ??
              "Jury score submitted successfully.",
          isError: false,
        );

        await Future.delayed(
          const Duration(
            milliseconds: 650,
          ),
        );

        if (mounted) {
          Navigator.pop(
            context,
            true,
          );
        }

        return;
      }

      showMessage(
        data is Map
            ? data['message']?.toString() ??
                "Unable to submit Jury score."
            : "Unable to submit Jury score.",
      );
    } catch (e) {
      debugPrint(
        "JURY SCORE ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        "Unable to submit Jury score. Please try again.",
      );
    }
  }

  void showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          margin:
              const EdgeInsets.all(18),
          content: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isError
                    ? const [
                        Color(0xFFD50000),
                        Color(0xFFFF1744),
                      ]
                    : const [
                        Color(0xFF00C853),
                        Color(0xFF64DD17),
                      ],
              ),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final contestant =
        widget.contestant;

    final String name =
        contestant['full_name']
            ?.toString() ??
            "Contestant";

    final String picture =
        contestant['picture']
            ?.toString()
            .trim() ??
            "";

    final String answer =
        contestant['answer']
            ?.toString() ??
            "Qualification answer is not available.";

    final int juryScoreCount =
        int.tryParse(
          contestant['jury_score_count']
              ?.toString() ??
              '',
        ) ??
            0;

    final Color currentColor =
        scoreColor(
      selectedScore,
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF050914),
        elevation: 0,
        toolbarHeight: 74,
        leading: IconButton(
          icon:
              const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 31,
          ),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
        title:
            const Text(
          "Jury Review",
          style:
              TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            38,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              //////////////////////////////////////////////////
              /// JURY STAGE BANNER
              //////////////////////////////////////////////////

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFFC107),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "JURY STAGE",
                            style:
                                TextStyle(
                              color: Colors.black,
                              fontWeight:
                                  FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Official contestant assessment",
                            style:
                                TextStyle(
                              color:
                                  Colors.black87,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "$juryScoreCount SCORE(S)",
                      style:
                          const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              //////////////////////////////////////////////////
              /// CONTESTANT
              //////////////////////////////////////////////////

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(22),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF0C1425),
                  borderRadius:
                      BorderRadius.circular(30),
                  border:
                      Border.all(
                    color:
                        const Color(0xFFFFC107)
                            .withOpacity(.65),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 47,
                      backgroundColor:
                          const Color(0xFF111827),
                      backgroundImage:
                          picture.isNotEmpty
                              ? NetworkImage(
                                  picture,
                                )
                              : null,
                      child:
                          picture.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color:
                                      Colors.white54,
                                )
                              : null,
                    ),

                    const SizedBox(width: 24),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                color:
                                    Colors.white54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                maskPhone(
                                  contestant['phone'],
                                ),
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              //////////////////////////////////////////////////
              /// QUALIFICATION ANSWER
              //////////////////////////////////////////////////

              _premiumPanel(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QUALIFICATION ANSWER",
                      style:
                          TextStyle(
                        color:
                            Color(0xFFFFC107),
                        fontSize: 14,
                        letterSpacing: .7,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(18),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(0xFF111B30),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Text(
                        answer,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.6,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              //////////////////////////////////////////////////
              /// SCORE
              //////////////////////////////////////////////////

              _premiumPanel(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "JURY SCORE (1.0 – 9.5)",
                      style:
                          TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        "${formatScore(selectedScore)} / 9.5",
                        style:
                            TextStyle(
                          color: currentColor,
                          fontSize: 49,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              currentColor.withOpacity(
                            .12,
                          ),
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: Text(
                          scoreRemark(
                            selectedScore,
                          ),
                          style:
                              TextStyle(
                            color: currentColor,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Slider(
                      min: 1.0,
                      max: 9.5,
                      divisions: 17,
                      value: selectedScore,
                      label:
                          formatScore(
                        selectedScore,
                      ),
                      activeColor:
                          const Color(0xFFFFC107),
                      onChanged: (value) {
                        setState(() {
                          selectedScore =
                              (value * 2).round() /
                                  2;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount:
                          allowedScores.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.15,
                      ),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final value =
                            allowedScores[index];

                        final selected =
                            selectedScore == value;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedScore =
                                  value;
                            });
                          },
                          borderRadius:
                              BorderRadius.circular(15),
                          child:
                              AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 160,
                            ),
                            alignment:
                                Alignment.center,
                            decoration:
                                BoxDecoration(
                              color: selected
                                  ? const Color(
                                      0xFFFFC107,
                                    )
                                  : const Color(
                                      0xFF10192B,
                                    ),
                              borderRadius:
                                  BorderRadius.circular(15),
                              border:
                                  Border.all(
                                color: selected
                                    ? const Color(
                                        0xFFFFC107,
                                      )
                                    : Colors.white12,
                              ),
                            ),
                            child: Text(
                              formatScore(value),
                              style:
                                  TextStyle(
                                color: selected
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              //////////////////////////////////////////////////
              /// COMMENT
              //////////////////////////////////////////////////

              _premiumPanel(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "JURY COMMENT (Optional)",
                      style:
                          TextStyle(
                        color:
                            Color(0xFFFFC107),
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          commentController,
                      maxLines: 5,
                      maxLength: 500,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        height: 1.6,
                      ),
                      decoration:
                          InputDecoration(
                        hintText:
                            "Write your comment about this contestant...",
                        hintStyle:
                            const TextStyle(
                          color:
                              Colors.white30,
                        ),
                        filled: true,
                        fillColor:
                            const Color(0xFF101722),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(20),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child:
                        OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                            },
                      style:
                          OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(
                          62,
                        ),
                        foregroundColor:
                            Colors.white70,
                        side:
                            const BorderSide(
                          color:
                              Colors.white24,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
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

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 3,
                    child:
                        ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : submitReview,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFFC107),
                        foregroundColor:
                            Colors.black,
                        minimumSize:
                            const Size.fromHeight(
                          62,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                            ),
                      label: Text(
                        isLoading
                            ? "SUBMITTING..."
                            : "SUBMIT ${formatScore(selectedScore)} SCORE",
                        style:
                            const TextStyle(
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
      ),
    );
  }

  Widget _premiumPanel({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101827),
            Color(0xFF09111F),
          ],
        ),
        borderRadius:
            BorderRadius.circular(27),
        border:
            Border.all(
          color:
              Colors.white.withOpacity(
            .09,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
