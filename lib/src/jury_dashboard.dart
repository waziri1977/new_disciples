// jury_dashboard.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'jury_review.dart';
import 'login.dart';

class JuryDashboard extends StatefulWidget {
  final Map juryData;

  const JuryDashboard({
    super.key,
    required this.juryData,
  });

  @override
  State<JuryDashboard> createState() =>
      _JuryDashboardState();
}

class _JuryDashboardState extends State<JuryDashboard> {
  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/get_top10.php";

  final String logoutApi =
      "https://new-disciples.com/api/logout.php";

  ////////////////////////////////////////////////////////////
  /// STATE
  ////////////////////////////////////////////////////////////

  bool isLoading = true;
  bool isRefreshing = false;

  List<Map<String, dynamic>> contestants = [];

  int totalJuryStage = 0;
  int reviewedByCurrentJury = 0;
  int remainingForCurrentJury = 0;
  int presidentScoredCount = 0;

  ////////////////////////////////////////////////////////////
  /// INIT
  ////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    getJuryContestants();
  }

  ////////////////////////////////////////////////////////////
  /// LOAD ALL CONTESTANTS AT JURY STAGE
  ////////////////////////////////////////////////////////////

  Future<void> getJuryContestants({
    bool showLoader = true,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final String juryId =
          widget.juryData['id']
              ?.toString() ??
              "";

      final Uri uri = Uri.parse(
        "$apiUrl?jury_id=$juryId",
      );

      final response = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
        },
      );

      debugPrint(
        "GET JURY CONTESTANTS HTTP ${response.statusCode}",
      );

      debugPrint(
        response.body,
      );

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isRefreshing = false;
        });

        showMessage(
          "Unable to load Jury contestants. Server returned ${response.statusCode}.",
        );

        return;
      }

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isRefreshing = false;
        });

        showMessage(
          "Invalid response received from the server.",
        );

        return;
      }

      if (data is! Map) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isRefreshing = false;
        });

        showMessage(
          "Unexpected response received from the server.",
        );

        return;
      }

      if (data['status'] == true) {
        final dynamic rawContestants =
            data['contestants'];

        final List<Map<String, dynamic>>
            loadedContestants = [];

        if (rawContestants is List) {
          for (final item in rawContestants) {
            if (item is Map) {
              loadedContestants.add(
                Map<String, dynamic>.from(
                  item,
                ),
              );
            }
          }
        }

        if (!mounted) return;

        setState(() {
          contestants =
              loadedContestants;

          totalJuryStage =
              int.tryParse(
                data['total_jury_stage']
                    ?.toString() ??
                    '',
              ) ??
                  loadedContestants.length;

          reviewedByCurrentJury =
              int.tryParse(
                data['reviewed_by_current_jury']
                    ?.toString() ??
                    '',
              ) ??
                  loadedContestants
                      .where(
                        (item) =>
                            item['reviewed_by_current_jury'] ==
                            true,
                      )
                      .length;

          remainingForCurrentJury =
              int.tryParse(
                data['remaining_for_current_jury']
                    ?.toString() ??
                    '',
              ) ??
                  (
                    loadedContestants.length -
                    reviewedByCurrentJury
                  );

          presidentScoredCount =
              int.tryParse(
                data['president_scored_count']
                    ?.toString() ??
                    '',
              ) ??
                  loadedContestants
                      .where(
                        (item) =>
                            item['president_scored'] ==
                            true,
                      )
                      .length;

          isLoading = false;
          isRefreshing = false;
        });

        return;
      }

      if (!mounted) return;

      setState(() {
        contestants = [];
        totalJuryStage = 0;
        reviewedByCurrentJury = 0;
        remainingForCurrentJury = 0;
        presidentScoredCount = 0;

        isLoading = false;
        isRefreshing = false;
      });

      final String message =
          data['message']
              ?.toString() ??
              "";

      if (message.trim().isNotEmpty) {
        showMessage(
          message,
          isError: false,
        );
      }
    } catch (e) {
      debugPrint(
        "GET JURY CONTESTANTS ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
      });

      showMessage(
        "Unable to connect to the server. Please check your internet connection.",
      );
    }
  }

  ////////////////////////////////////////////////////////////
  /// REFRESH
  ////////////////////////////////////////////////////////////

  Future<void> refreshContestants() async {
    if (isRefreshing) {
      return;
    }

    setState(() {
      isRefreshing = true;
    });

    await getJuryContestants(
      showLoader: false,
    );
  }

  ////////////////////////////////////////////////////////////
  /// OPEN JURY REVIEW
  ////////////////////////////////////////////////////////////

  Future<void> openJuryReview(
    Map<String, dynamic> contestant,
  ) async {
    final bool reviewed =
        contestant['reviewed_by_current_jury'] ==
            true;

    if (reviewed) {
      final dynamic score =
          contestant['current_jury_score'];

      showMessage(
        score == null
            ? "You already reviewed this contestant."
            : "You already scored this contestant ${score.toString()}.",
        isError: false,
      );

      return;
    }

    final bool presidentScored =
        contestant['president_scored'] ==
            true;

    if (presidentScored) {
      showMessage(
        "President scoring is already complete for this contestant.",
        isError: false,
      );

      return;
    }

    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JuryReviewScreen(
          contestant: contestant,
          juryData: widget.juryData,
        ),
      ),
    );

    if (result == true && mounted) {
      await refreshContestants();
    }
  }

  ////////////////////////////////////////////////////////////
  /// LOGOUT
  ////////////////////////////////////////////////////////////

  Future<void> logoutUser() async {
    final userId =
        widget.juryData['id'];

    if (userId == null) {
      goToLogin();
      return;
    }

    try {
      await http.post(
        Uri.parse(logoutApi),
        body: {
          "user_id":
              userId.toString(),
        },
      );
    } catch (e) {
      debugPrint(
        "LOGOUT ERROR: $e",
      );
    }

    if (!mounted) return;

    goToLogin();
  }

  void goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
                Icons.logout_rounded,
                color:
                    Colors.red,
              ),
              SizedBox(
                width:
                    10,
              ),
              Text(
                "Logout",
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          content:
              const Text(
            "Are you sure you want to logout from the Jury panel?",
            style:
                TextStyle(
              color:
                  Colors.white70,
              height:
                  1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                "CANCEL",
                style:
                    TextStyle(
                  color:
                      Colors.white54,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
                elevation:
                    0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await logoutUser();
              },
              icon:
                  const Icon(
                Icons.logout_rounded,
              ),
              label:
                  const Text(
                "LOGOUT",
                style:
                    TextStyle(
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

  ////////////////////////////////////////////////////////////
  /// MESSAGE
  ////////////////////////////////////////////////////////////

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
              const EdgeInsets.all(
            18,
          ),
          content: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  18,
              vertical:
                  16,
            ),
            decoration:
                BoxDecoration(
              color: isError
                  ? const Color(
                      0xFFB91C1C,
                    )
                  : const Color(
                      0xFF15803D,
                    ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons
                          .error_outline_rounded
                      : Icons
                          .check_circle_rounded,
                  color:
                      Colors.white,
                ),
                const SizedBox(
                  width:
                      12,
                ),
                Expanded(
                  child: Text(
                    message,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
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

  ////////////////////////////////////////////////////////////
  /// BUILD
  ////////////////////////////////////////////////////////////

  @override
  Widget build(
    BuildContext context,
  ) {
    final String juryName =
        widget.juryData['full_name']
            ?.toString() ??
            "Jury";

    final String role =
        widget.juryData['role']
            ?.toString()
            .toUpperCase() ??
            "JURY";

    return Scaffold(
      backgroundColor:
          const Color(
        0xFF070B14,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color:
              const Color(
            0xFFFFC107,
          ),
          backgroundColor:
              const Color(
            0xFF161B22,
          ),
          onRefresh:
              refreshContestants,
          child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        Color(
                      0xFFFFC107,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      //////////////////////////////////////////////////
                      /// HEADER
                      //////////////////////////////////////////////////

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Jury Panel",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white54,
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      6,
                                ),

                                Text(
                                  juryName,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
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
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  16,
                              vertical:
                                  11,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFFC107,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                17,
                              ),
                            ),
                            child: Text(
                              role,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black,
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width:
                                9,
                          ),

                          GestureDetector(
                            onTap:
                                isRefreshing
                                    ? null
                                    : refreshContestants,
                            child:
                                Container(
                              width:
                                  46,
                              height:
                                  46,
                              alignment:
                                  Alignment.center,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFFFC107,
                                ).withOpacity(
                                  .10,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                              child:
                                  isRefreshing
                                      ? const SizedBox(
                                          width:
                                              20,
                                          height:
                                              20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Color(
                                              0xFFFFC107,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .refresh_rounded,
                                          color:
                                              Color(
                                            0xFFFFC107,
                                          ),
                                        ),
                            ),
                          ),

                          const SizedBox(
                            width:
                                9,
                          ),

                          GestureDetector(
                            onTap:
                                logout,
                            child:
                                Container(
                              width:
                                  46,
                              height:
                                  46,
                              alignment:
                                  Alignment.center,
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.red
                                        .withOpacity(
                                  .12,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .logout_rounded,
                                color:
                                    Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            34,
                      ),

                      //////////////////////////////////////////////////
                      /// HERO
                      //////////////////////////////////////////////////

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
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                            colors: [
                              Color(
                                0xFFFFD54F,
                              ),
                              Color(
                                0xFFFFC107,
                              ),
                              Color(
                                0xFFFF9800,
                              ),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            34,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    13,
                                vertical:
                                    8,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.black
                                        .withOpacity(
                                  .12,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  30,
                                ),
                              ),
                              child:
                                  const Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size:
                                        10,
                                    color:
                                        Color(
                                      0xFF00C853,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        7,
                                  ),
                                  Text(
                                    "JURY STAGE",
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.black,
                                      fontSize:
                                          11,
                                      letterSpacing:
                                          .8,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height:
                                  22,
                            ),

                            const Text(
                              "Contestants for Jury Assessment",
                              style:
                                  TextStyle(
                                color:
                                    Colors.black,
                                fontSize:
                                    31,
                                height:
                                    1.08,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  10,
                            ),

                            const Text(
                              "Review every contestant admitted to the Jury Stage. Each Jury member can submit only one score per contestant.",
                              style:
                                  TextStyle(
                                color:
                                    Colors.black87,
                                fontSize:
                                    14,
                                height:
                                    1.55,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  22,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      buildHeroStat(
                                    icon:
                                        Icons
                                            .groups_rounded,
                                    value:
                                        totalJuryStage
                                            .toString(),
                                    label:
                                        "Jury Stage",
                                  ),
                                ),
                                const SizedBox(
                                  width:
                                      12,
                                ),
                                Expanded(
                                  child:
                                      buildHeroStat(
                                    icon:
                                        Icons
                                            .check_circle_rounded,
                                    value:
                                        reviewedByCurrentJury
                                            .toString(),
                                    label:
                                        "Reviewed",
                                  ),
                                ),
                                const SizedBox(
                                  width:
                                      12,
                                ),
                                Expanded(
                                  child:
                                      buildHeroStat(
                                    icon:
                                        Icons
                                            .pending_actions_rounded,
                                    value:
                                        remainingForCurrentJury
                                            .toString(),
                                    label:
                                        "Remaining",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            34,
                      ),

                      Row(
                        children: [
                          const Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Jury Stage Contestants",
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
                                SizedBox(
                                  height:
                                      6,
                                ),
                                Text(
                                  "All contestants marked CONTINUE by the pre-Jury control are shown below.",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white54,
                                    fontSize:
                                        13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  12,
                              vertical:
                                  8,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFFC107,
                              ).withOpacity(
                                .10,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                            child:
                                Text(
                              "${contestants.length} TOTAL",
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFFFFC107,
                                ),
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            22,
                      ),

                      if (contestants.isEmpty)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            36,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF161B22,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              28,
                            ),
                          ),
                          child:
                              const Column(
                            children: [
                              Icon(
                                Icons
                                    .hourglass_empty_rounded,
                                color:
                                    Color(
                                  0xFFFFC107,
                                ),
                                size:
                                    48,
                              ),
                              SizedBox(
                                height:
                                    14,
                              ),
                              Text(
                                "No Jury Stage Contestants",
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
                              SizedBox(
                                height:
                                    8,
                              ),
                              Text(
                                "Contestants will appear after they are marked CONTINUE in contestant_remaining.php.",
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white54,
                                  height:
                                      1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          itemCount:
                              contestants.length,
                          shrinkWrap:
                              true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            return buildContestantCard(
                              contestants[
                                  index],
                              index,
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// CONTESTANT CARD
  ////////////////////////////////////////////////////////////

  Widget buildContestantCard(
    Map<String, dynamic> contestant,
    int index,
  ) {
    final String name =
        contestant['full_name']
            ?.toString() ??
            "Contestant";

    final String phone =
        contestant['phone']
            ?.toString() ??
            "";

    final String picture =
        contestant['picture']
            ?.toString()
            .trim() ??
            "";

    final String answer =
        contestant['answer']
            ?.toString() ??
            "";

    final bool reviewed =
        contestant['reviewed_by_current_jury'] ==
            true;

    final bool presidentScored =
        contestant['president_scored'] ==
            true;

    final dynamic ownScore =
        contestant['current_jury_score'];

    final int juryCount =
        int.tryParse(
          contestant['jury_score_count']
              ?.toString() ??
              '',
        ) ??
            0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            20,
      ),
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(
              0xFF161B22,
            ),
            Color(
              0xFF101720,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        border:
            Border.all(
          color: reviewed
              ? const Color(
                  0xFF22C55E,
                ).withOpacity(
                  .35,
                )
              : const Color(
                  0xFFFFC107,
                ).withOpacity(
                  .20,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius:
                    34,
                backgroundColor:
                    const Color(
                  0xFF0F172A,
                ),
                backgroundImage:
                    picture.isNotEmpty
                        ? NetworkImage(
                            picture,
                          )
                        : null,
                child:
                    picture.isEmpty
                        ? const Icon(
                            Icons
                                .person_rounded,
                            color:
                                Colors.white54,
                            size:
                                34,
                          )
                        : null,
              ),

              const SizedBox(
                width:
                    18,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            20,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height:
                          7,
                    ),

                    Text(
                      phone,
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize:
                            13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      12,
                  vertical:
                      9,
                ),
                decoration:
                    BoxDecoration(
                  color: reviewed
                      ? const Color(
                          0xFF22C55E,
                        ).withOpacity(
                          .12,
                        )
                      : const Color(
                          0xFFFFC107,
                        ).withOpacity(
                          .10,
                        ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Text(
                  reviewed
                      ? ownScore == null
                          ? "REVIEWED"
                          : "YOUR SCORE ${ownScore.toString()}"
                      : "PENDING",
                  style:
                      TextStyle(
                    color: reviewed
                        ? const Color(
                            0xFF86EFAC,
                          )
                        : const Color(
                            0xFFFFC107,
                          ),
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                20,
          ),

          Row(
            children: [
              Expanded(
                child:
                    buildMetricBox(
                  icon:
                      Icons
                          .gavel_rounded,
                  label:
                      "JURY SCORES",
                  value:
                      juryCount
                          .toString(),
                  color:
                      const Color(
                    0xFF38BDF8,
                  ),
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    buildMetricBox(
                      icon:
                      Icons
                          .workspace_premium_rounded,
                  label:
                      "PRESIDENT",
                  value:
                      presidentScored
                          ? "SCORED"
                          : "PENDING",
                  color:
                      presidentScored
                          ? const Color(
                              0xFF22C55E,
                            )
                          : const Color(
                              0xFFFFC107,
                            ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                20,
          ),

          const Text(
            "QUALIFICATION ANSWER",
            style:
                TextStyle(
              color:
                  Colors.white38,
              fontSize:
                  10,
              letterSpacing:
                  1.1,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height:
                10,
          ),

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              17,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFF0F172A,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Text(
              answer.isNotEmpty
                  ? answer
                  : "Qualification answer is not available.",
              style:
                  const TextStyle(
                color:
                    Colors.white,
                height:
                    1.6,
                fontSize:
                    15,
              ),
            ),
          ),

          const SizedBox(
            height:
                20,
          ),

          SizedBox(
            width:
                double.infinity,
            height:
                58,
            child:
                ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    reviewed ||
                            presidentScored
                        ? const Color(
                            0xFF334155,
                          )
                        : const Color(
                            0xFFFFC107,
                          ),
                foregroundColor:
                    reviewed ||
                            presidentScored
                        ? Colors.white70
                        : Colors.black,
                elevation:
                    0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              onPressed:
                  reviewed ||
                          presidentScored
                      ? null
                      : () async {
                          await openJuryReview(
                            contestant,
                          );
                        },
              icon:
                  Icon(
                reviewed
                    ? Icons
                        .check_circle_rounded
                    : presidentScored
                        ? Icons
                            .lock_rounded
                        : Icons
                            .rate_review_rounded,
              ),
              label: Text(
                reviewed
                    ? "REVIEW SUBMITTED"
                    : presidentScored
                        ? "PRESIDENT COMPLETED"
                        : "REVIEW CONTESTANT",
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
    );
  }

  ////////////////////////////////////////////////////////////
  /// HERO STAT
  ////////////////////////////////////////////////////////////

  Widget buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            12,
        vertical:
            14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.black
                .withOpacity(
          .10,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                Colors.black,
            size:
                20,
          ),
          const SizedBox(
            height:
                7,
          ),
          Text(
            value,
            style:
                const TextStyle(
              color:
                  Colors.black,
              fontSize:
                  17,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height:
                2,
          ),
          Text(
            label,
            style:
                TextStyle(
              color:
                  Colors.black
                      .withOpacity(
                .66,
              ),
              fontSize:
                  9,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// METRIC BOX
  ////////////////////////////////////////////////////////////

  Widget buildMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
          .08,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border:
            Border.all(
          color:
              color.withOpacity(
            .18,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                color,
            size:
                19,
          ),

          const SizedBox(
            width:
                10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize:
                        8,
                    letterSpacing:
                        .7,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                      4,
                ),

                Text(
                  value,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        color,
                    fontSize:
                        14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
