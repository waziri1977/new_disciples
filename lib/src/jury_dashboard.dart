// jury_dashboard.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

import 'login.dart';

class JuryDashboard
    extends StatefulWidget {

  final Map juryData;

  const JuryDashboard({
    super.key,
    required this.juryData,
  });

  @override
  State<JuryDashboard>
  createState() =>
      _JuryDashboardState();
}

class _JuryDashboardState
    extends State<JuryDashboard> {

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/get_top10.php";

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = true;

  List contestants = [];

  ////////////////////////////////////////////////////////////
  /// GET TOP 10
  ////////////////////////////////////////////////////////////

  Future<void>
  getTopContestants()
  async {

    try {

      final response =
      await http.get(
        Uri.parse(apiUrl),
      );

      print(response.body);

      final data =
      jsonDecode(
          response.body);

      if (data['status']
          == true) {

        setState(() {

          contestants =
          data['contestants'];

          isLoading = false;
        });

      } else {

        setState(() {
          isLoading = false;
        });
      }

    } catch (e) {

      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// LOGOUT
  ////////////////////////////////////////////////////////////

  void logout() {

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          backgroundColor:
          const Color(0xFF161B22),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
                24),
          ),

          title: const Text(
            "Logout",

            style: TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.w900,
            ),
          ),

          content: const Text(
            "Are you sure you want to logout?",

            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
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
                Colors.red,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      14),
                ),
              ),

              onPressed: () {

                Navigator.pop(
                    context);

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
                "Logout",

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    getTopContestants();
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

      body: SafeArea(

        child: isLoading

            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            Color(
                0xFFFFC107),
          ),
        )

            : SingleChildScrollView(

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
                        "Jury Panel",

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
                        widget.juryData[
                        'full_name']
                            .toString(),

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

                  Row(
                    children: [

                      //////////////////////////////////////////////////
                      /// ROLE BADGE
                      //////////////////////////////////////////////////

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          18,

                          vertical:
                          12,
                        ),

                        decoration:
                        BoxDecoration(

                          color:
                          const Color(
                              0xFFFFC107),

                          borderRadius:
                          BorderRadius.circular(
                              18),
                        ),

                        child: Text(

                          widget.juryData[
                          'role']
                              .toString(),

                          style:
                          const TextStyle(
                            color:
                            Colors.black,

                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(
                          width:
                          12),

                      //////////////////////////////////////////////////
                      /// LOGOUT
                      //////////////////////////////////////////////////

                      GestureDetector(

                        onTap:
                        logout,

                        child:
                        Container(

                          padding:
                          const EdgeInsets
                              .all(14),

                          decoration:
                          BoxDecoration(

                            color:
                            Colors.red
                                .withOpacity(
                                0.15),

                            borderRadius:
                            BorderRadius.circular(
                                18),
                          ),

                          child:
                          const Icon(
                            Icons.logout,

                            color:
                            Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(
                  height:
                  35),

              //////////////////////////////////////////////////
              /// LIVE CARD
              //////////////////////////////////////////////////

              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets
                    .all(28),

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
                      color:
                      const Color(
                          0xFFFFC107)
                          .withOpacity(
                          0.35),

                      blurRadius:
                      30,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    Row(
                      children: [

                        Container(
                          height:
                          14,

                          width:
                          14,

                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.green,

                            shape:
                            BoxShape.circle,
                          ),
                        ),

                        const SizedBox(
                            width:
                            10),

                        const Text(
                          "LIVE JUDGING",

                          style:
                          TextStyle(
                            color:
                            Colors.black,

                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height:
                        24),

                    const Text(
                      "Top Contestants",

                      style:
                      TextStyle(
                        color:
                        Colors.black,

                        fontSize:
                        30,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                        height:
                        14),

                    const Text(
                      "Review contestant answers and submit your jury scores for the current reality show stage.",

                      style:
                      TextStyle(
                        color:
                        Colors.black87,

                        height:
                        1.7,

                        fontSize:
                        15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height:
                  35),

              //////////////////////////////////////////////////
              /// TITLE
              //////////////////////////////////////////////////

              const Text(
                "Top Contestants",

                style:
                TextStyle(
                  color:
                  Colors.white,

                  fontSize:
                  24,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                  height:
                  25),

              //////////////////////////////////////////////////
              /// LIST
              //////////////////////////////////////////////////

              ListView.builder(

                itemCount:
                contestants.length,

                shrinkWrap:
                true,

                physics:
                const NeverScrollableScrollPhysics(),

                itemBuilder:
                    (context, index) {

                  final contestant =
                  contestants[index];

                  return buildContestantCard(
                      contestant);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// CONTESTANT CARD
  ////////////////////////////////////////////////////////////

  Widget buildContestantCard(
      Map contestant) {

    return Container(
      margin:
      const EdgeInsets.only(
          bottom: 20),

      padding:
      const EdgeInsets.all(
          20),

      decoration:
      BoxDecoration(

        color:
        const Color(
            0xFF161B22),

        borderRadius:
        BorderRadius.circular(
            28),

        border: Border.all(
          color:
          Colors.white
              .withOpacity(
              0.05),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [

          //////////////////////////////////////////////////////
          /// TOP
          //////////////////////////////////////////////////////

          Row(
            children: [

              CircleAvatar(
                radius: 34,

                backgroundColor:
                const Color(
                    0xFFFFC107),

                backgroundImage:

                contestant['picture']
                    .toString()
                    .isNotEmpty

                    ? NetworkImage(
                  contestant[
                  'picture'],
                )

                    : null,

                child:

                contestant['picture']
                    .toString()
                    .isEmpty

                    ? const Icon(
                  Icons.person,

                  color:
                  Colors.black,

                  size:
                  34,
                )

                    : null,
              ),

              const SizedBox(
                  width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    Text(
                      contestant[
                      'full_name']
                          .toString(),

                      style:
                      const TextStyle(
                        color:
                        Colors.white,

                        fontSize:
                        20,

                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                        height:
                        6),

                    Text(
                      contestant[
                      'phone']
                          .toString(),

                      style:
                      const TextStyle(
                        color:
                        Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal:
                  16,

                  vertical:
                  10,
                ),

                decoration:
                BoxDecoration(

                  color:
                  Colors.green
                      .withOpacity(
                      0.15),

                  borderRadius:
                  BorderRadius.circular(
                      16),
                ),

                child:
                const Text(
                  "TOP ",

                  style:
                  TextStyle(
                    color:
                    Colors.green,

                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
              height: 24),

          const Text(
            "Contestant Answer",

            style:
            TextStyle(
              color:
              Colors.white54,

              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
              height: 14),

          Text(
            contestant['answer']
                .toString(),

            style:
            const TextStyle(
              color:
              Colors.white,

              height:
              1.7,

              fontSize:
              15,
            ),
          ),

          const SizedBox(
              height: 26),

          //////////////////////////////////////////////////////
          /// REVIEW BUTTON
          //////////////////////////////////////////////////////

          Row(
            children: [

              Expanded(
                child:
                ElevatedButton(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(
                        0xFFFFC107),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          18),
                    ),
                  ),

                  onPressed:
                      () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            JuryReviewScreen(

                              contestant:
                              contestant,

                              juryData:
                              widget.juryData,
                            ),
                      ),
                    );
                  },

                  child:
                  const Text(
                    "REVIEW",

                    style:
                    TextStyle(
                      color:
                      Colors.black,

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
    );
  }
}

////////////////////////////////////////////////////////////
/// REVIEW SCREEN
////////////////////////////////////////////////////////////

class JuryReviewScreen
    extends StatefulWidget {

  final Map contestant;
  final Map juryData;

  const JuryReviewScreen({
    super.key,
    required this.contestant,
    required this.juryData,
  });

  @override
  State<JuryReviewScreen>
  createState() =>
      _JuryReviewScreenState();
}

class _JuryReviewScreenState
    extends State<JuryReviewScreen> {

  final commentController =
  TextEditingController();

  double score = 5;

  bool isLoading = false;

  final String apiUrl =
      "https://aktcpro.com.ng/api/submit_jury_score.php";

  ////////////////////////////////////////////////////////////
  /// SUBMIT SCORE
  ////////////////////////////////////////////////////////////

  Future<void>
  submitScore()
  async {

    setState(() {
      isLoading = true;
    });

    try {

      final response =
      await http.post(

        Uri.parse(apiUrl),

        body: {

          "jury_id":

          widget.juryData['id']
              .toString(),

          "contestant_id":

          widget.contestant['contestant_id']
              .toString(),

          "question_id":

          widget.contestant['question_id']
              .toString(),

          "score":
          score.toInt().toString(),

          "comment":

          commentController.text,
        },
      );

      final data =
      jsonDecode(
          response.body);

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
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

      Navigator.pop(context);

    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(
          0xFF070B14),

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title: const Text(
          "Jury Review",
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(
            24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [

            Text(
              widget.contestant[
              'full_name']
                  .toString(),

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
                25),

            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets
                  .all(22),

              decoration:
              BoxDecoration(

                color:
                const Color(
                    0xFF161B22),

                borderRadius:
                BorderRadius.circular(
                    26),
              ),

              child: Text(
                widget.contestant[
                'answer']
                    .toString(),

                style:
                const TextStyle(
                  color:
                  Colors.white,

                  height:
                  1.7,
                ),
              ),
            ),

            const SizedBox(
                height:
                30),

            const Text(
              "Score Contestant",

              style:
              TextStyle(
                color:
                Colors.white,

                fontSize:
                20,

                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
                height:
                25),

            Slider(

              activeColor:
              const Color(
                  0xFFFFC107),

              value: score,

              min: 1,
              max: 10,

              divisions: 9,

              label:
              score.toInt()
                  .toString(),

              onChanged:
                  (value) {

                setState(() {
                  score = value;
                });
              },
            ),

            Center(
              child: Text(
                "${score.toInt()}/10",

                style:
                const TextStyle(
                  color:
                  Colors.white,

                  fontSize:
                  32,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(
                height:
                30),

            TextField(
              controller:
              commentController,

              maxLines: 6,

              style:
              const TextStyle(
                color:
                Colors.white,
              ),

              decoration:
              InputDecoration(

                hintText:
                "Write jury comment...",

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
                  BorderRadius.circular(
                      24),

                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
                height:
                35),

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
                  const Color(
                      0xFFFFC107),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        20),
                  ),
                ),

                onPressed:

                isLoading

                    ? null

                    : submitScore,

                child:

                isLoading

                    ? const CircularProgressIndicator(
                  color:
                  Colors.black,
                )

                    : const Text(
                  "SUBMIT SCORE",

                  style:
                  TextStyle(
                    color:
                    Colors.black,

                    fontWeight:
                    FontWeight.w900,
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