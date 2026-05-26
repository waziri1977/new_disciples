// admin_dashboard.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

import 'login.dart';

import 'manage_questions.dart';
//import 'manage_contestants.dart';
//import 'manage_juries.dart';
//import 'live_voting.dart';
//import 'analytics.dart';
//import 'notifications.dart';

class AdminDashboard
    extends StatefulWidget {

  final Map adminData;

  const AdminDashboard({
    super.key,
    required this.adminData,
  });

  @override
  State<AdminDashboard>
  createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboard> {

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/admin_dashboard.php";

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = true;

  Map dashboardData = {};

  ////////////////////////////////////////////////////////////
  /// LOAD DASHBOARD
  ////////////////////////////////////////////////////////////

  Future<void>
  loadDashboard()
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

          dashboardData =
              data;

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
  /// NAVIGATIONS
  ////////////////////////////////////////////////////////////

  void openManageQuestions() {

    Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) =>
        const ManageQuestionsScreen(),
      ),
    );
  }

  void openManageContestants() {

    Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) =>
        const ManageQuestionsScreen(),
        //const ManageContestantsScreen(),
      ),
    );
  }

  void openManageJuries() {

    Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) =>
        const ManageQuestionsScreen(),
        //const ManageJuriesScreen(),
      ),
    );
  }

  void openLiveVoting() {

    Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) =>
        const ManageQuestionsScreen(),
       // const LiveVotingScreen(),
      ),
    );
  }

  void openAnalytics() {

    Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) =>
        const ManageQuestionsScreen(),
      //  const AnalyticsScreen(),
      ),
    );
  }

  void openNotifications() {

    Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) =>
       // const NotificationsScreen(),
        const ManageQuestionsScreen(),
      ),
    );
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
              ),

              onPressed: () {

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

    loadDashboard();
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

        child:

        isLoading

            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            Color(
                0xFFFFC107),
          ),
        )

            : RefreshIndicator(

          color:
          const Color(
              0xFFFFC107),

          onRefresh:
          loadDashboard,

          child:
          SingleChildScrollView(

            physics:
            const BouncingScrollPhysics(),

            padding:
            const EdgeInsets.all(
                24),

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

                    Expanded(
                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          const Text(
                            "Production Control",

                            style:
                            TextStyle(
                              color:
                              Colors.white54,
                            ),
                          ),

                          const SizedBox(
                              height:
                              8),

                          Text(

                            widget.adminData[
                            'full_name']
                                .toString(),

                            overflow:
                            TextOverflow.ellipsis,

                            style:
                            const TextStyle(

                              color:
                              Colors.white,

                              fontSize:
                              28,

                              fontWeight:
                              FontWeight
                                  .w900,
                            ),
                          ),
                        ],
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
                        34),
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
                            BoxDecoration(

                              color:

                              dashboardData[
                              'show_status'] ==

                                  "active"

                                  ? Colors.green

                                  : Colors.red,

                              shape:
                              BoxShape.circle,
                            ),
                          ),

                          const SizedBox(
                              width:
                              10),

                          Expanded(
                            child: Text(

                              dashboardData[
                              'show_status'] ==

                                  "active"

                                  ? "SHOW LIVE"

                                  : "SHOW OFFLINE",

                              overflow:
                              TextOverflow.ellipsis,

                              style:
                              const TextStyle(

                                color:
                                Colors.black,

                                fontWeight:
                                FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height:
                          25),

                      const Text(
                        "Reality Show Control Center",

                        style:
                        TextStyle(

                          color:
                          Colors.black,

                          fontSize:
                          28,

                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                          height:
                          14),

                      const Text(
                        "Manage contestants, juries, voting system and live production activities.",

                        style:
                        TextStyle(

                          color:
                          Colors.black87,

                          height:
                          1.7,
                        ),
                      ),

                      const SizedBox(
                          height:
                          30),

                      Row(
                        children: [

                          Expanded(
                            child:
                            buildMiniStat(

                              title:
                              "Round",

                              value:
                              dashboardData[
                              'current_round']
                                  .toString(),
                            ),
                          ),

                          const SizedBox(
                              width:
                              16),

                          Expanded(
                            child:
                            buildMiniStat(

                              title:
                              "Live Votes",

                              value:
                              dashboardData[
                              'total_votes']
                                  .toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height:
                    35),

                //////////////////////////////////////////////////
                /// STATS
                //////////////////////////////////////////////////

                GridView.builder(

                  shrinkWrap: true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  itemCount: 4,

                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount: 2,

                    crossAxisSpacing: 18,

                    mainAxisSpacing: 18,

                    childAspectRatio: 0.82,
                  ),

                  itemBuilder:
                      (context, index) {

                    final stats = [

                      {
                        "title":
                        "Contestants",

                        "value":

                        dashboardData[
                        'contestants']
                            .toString(),

                        "icon":
                        Icons.people,

                        "color":
                        Colors.blue,
                      },

                      {
                        "title":
                        "Juries",

                        "value":

                        dashboardData[
                        'juries']
                            .toString(),

                        "icon":
                        Icons.gavel,

                        "color":
                        Colors.orange,
                      },

                      {
                        "title":
                        "Questions",

                        "value":

                        dashboardData[
                        'questions']
                            .toString(),

                        "icon":
                        Icons.quiz,

                        "color":
                        Colors.green,
                      },

                      {
                        "title":
                        "Votes",

                        "value":

                        dashboardData[
                        'total_votes']
                            .toString(),

                        "icon":
                        Icons.how_to_vote,

                        "color":
                        Colors.purple,
                      },
                    ];

                    return buildStatCard(

                      title:

                      stats[index]['title']
                      as String,

                      value:

                      stats[index]['value']
                      as String,

                      icon:

                      stats[index]['icon']
                      as IconData,

                      color:

                      stats[index]['color']
                      as Color,
                    );
                  },
                ),

                const SizedBox(
                    height:
                    35),

                //////////////////////////////////////////////////
                /// QUICK ACTIONS
                //////////////////////////////////////////////////

                const Text(
                  "Quick Actions",

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
                    24),

                buildActionButton(
                  title:
                  "Manage Questions",

                  icon:
                  Icons.quiz,

                  onTap:
                  openManageQuestions,
                ),

                buildActionButton(
                  title:
                  "Manage Contestants",

                  icon:
                  Icons.people_alt,

                  onTap:
                  openManageContestants,
                ),

                buildActionButton(
                  title:
                  "Manage Juries",

                  icon:
                  Icons.gavel,

                  onTap:
                  openManageJuries,
                ),

                buildActionButton(
                  title:
                  "Live Voting",

                  icon:
                  Icons.how_to_vote,

                  onTap:
                  openLiveVoting,
                ),

                buildActionButton(
                  title:
                  "Analytics",

                  icon:
                  Icons.bar_chart,

                  onTap:
                  openAnalytics,
                ),

                buildActionButton(
                  title:
                  "Notifications",

                  icon:
                  Icons.notifications,

                  onTap:
                  openNotifications,
                ),

                const SizedBox(
                    height:
                    35),

                //////////////////////////////////////////////////
                /// RECENT ACTIVITY
                //////////////////////////////////////////////////

                const Text(
                  "Recent Activities",

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
                    20),

                ListView.builder(

                  itemCount:
                  dashboardData[
                  'activities']
                      .length,

                  shrinkWrap:
                  true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  itemBuilder:
                      (context, index) {

                    final activity =

                    dashboardData[
                    'activities'][index];

                    return buildActivityCard(
                        activity);
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
  /// MINI STAT
  ////////////////////////////////////////////////////////////

  Widget buildMiniStat({

    required String title,

    required String value,
  }) {

    return Container(

      padding:
      const EdgeInsets.all(
          18),

      decoration:
      BoxDecoration(

        color:
        Colors.black
            .withOpacity(0.1),

        borderRadius:
        BorderRadius.circular(
            22),
      ),

      child: Column(
        children: [

          Text(
            value,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(

              color:
              Colors.black,

              fontSize:
              28,

              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(
              height:
              6),

          Text(
            title,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(
              color:
              Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STAT CARD
  ////////////////////////////////////////////////////////////

  Widget buildStatCard({

    required String title,

    required String value,

    required IconData icon,

    required Color color,
  }) {

    return Container(

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
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Container(

            padding:
            const EdgeInsets.all(
                14),

            decoration:
            BoxDecoration(

              color:
              color.withOpacity(
                  0.15),

              borderRadius:
              BorderRadius.circular(
                  18),
            ),

            child: Icon(
              icon,

              color:
              color,

              size: 28,
            ),
          ),

          const Spacer(),

          Text(
            value,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(

              color:
              Colors.white,

              fontSize:
              30,

              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(
              height:
              8),

          Text(
            title,

            overflow:
            TextOverflow.ellipsis,

            maxLines: 1,

            style:
            const TextStyle(
              color:
              Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// ACTION BUTTON
  ////////////////////////////////////////////////////////////

  Widget buildActionButton({

    required String title,

    required IconData icon,

    required VoidCallback onTap,
  }) {

    return Container(

      margin:
      const EdgeInsets.only(
          bottom: 18),

      child: ElevatedButton(

        style:
        ElevatedButton.styleFrom(

          backgroundColor:
          const Color(
              0xFF161B22),

          elevation: 0,

          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
                24),
          ),
        ),

        onPressed: onTap,

        child: Row(
          children: [

            Container(

              padding:
              const EdgeInsets.all(
                  14),

              decoration:
              BoxDecoration(

                color:
                const Color(
                    0xFFFFC107)
                    .withOpacity(
                    0.15),

                borderRadius:
                BorderRadius.circular(
                    16),
              ),

              child: Icon(
                icon,

                color:
                const Color(
                    0xFFFFC107),
              ),
            ),

            const SizedBox(
                width:
                16),

            Expanded(

              child: Text(
                title,

                overflow:
                TextOverflow.ellipsis,

                maxLines: 1,

                style:
                const TextStyle(

                  color:
                  Colors.white,

                  fontSize:
                  16,

                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(
                width:
                10),

            const Icon(
              Icons.arrow_forward_ios,

              color:
              Colors.white38,

              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// ACTIVITY CARD
  ////////////////////////////////////////////////////////////

  Widget buildActivityCard(
      Map activity) {

    return Container(

      margin:
      const EdgeInsets.only(
          bottom: 18),

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
            24),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Container(

            padding:
            const EdgeInsets.all(
                14),

            decoration:
            BoxDecoration(

              color:
              const Color(
                  0xFFFFC107)
                  .withOpacity(
                  0.15),

              borderRadius:
              BorderRadius.circular(
                  16),
            ),

            child: const Icon(
              Icons.notifications,

              color:
              Color(
                  0xFFFFC107),
            ),
          ),

          const SizedBox(
              width:
              18),

          Expanded(
            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(

                  activity['title']
                      .toString(),

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(

                    color:
                    Colors.white,

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                    height:
                    8),

                Text(

                  activity['message']
                      .toString(),

                  style:
                  const TextStyle(

                    color:
                    Colors.white54,

                    height:
                    1.5,
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