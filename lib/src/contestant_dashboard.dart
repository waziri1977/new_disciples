// contestant_dashboard.dart

import 'package:flutter/material.dart';

import 'home.dart';
import 'votes.dart';
import 'readiness_profile.dart';
import 'readiness_leaderboard.dart';
import 'profile.dart';

class ContestantDashboard extends StatefulWidget {
  final Map userData;

  const ContestantDashboard({
    super.key,
    required this.userData,
  });

  @override
  State<ContestantDashboard> createState() =>
      _ContestantDashboardState();
}

class _ContestantDashboardState extends State<ContestantDashboard> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    //////////////////////////////////////////////////////////
    /// DASHBOARD PAGES
    //////////////////////////////////////////////////////////

    pages = [
      HomeScreen(
        userData: widget.userData,
      ),

    ///  VotesScreen(
    ///    userData: widget.userData,
      ///   ),

    ///   ReadinessProfileScreen(
    ///   userData: widget.userData,
      ///   ),

    ///   ReadinessLeaderboardScreen(
    ///    userData: widget.userData,
      ///   ),

      ProfileScreen(
        userData: widget.userData,
      ),
    ];
  }

  ////////////////////////////////////////////////////////////
  /// CHANGE ACTIVE PAGE
  ////////////////////////////////////////////////////////////

  void changePage(int index) {
    if (index < 0 || index >= pages.length) {
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),

      ////////////////////////////////////////////////////////
      /// KEEP PAGE STATE ALIVE
      ////////////////////////////////////////////////////////

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      ////////////////////////////////////////////////////////
      /// PREMIUM BOTTOM NAVIGATION
      ////////////////////////////////////////////////////////

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            18,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              backgroundColor: const Color(0xFF161B22),
              elevation: 0,
              selectedItemColor: const Color(0xFFFFC107),
              unselectedItemColor: Colors.white38,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              type: BottomNavigationBarType.fixed,
              onTap: changePage,
              items: const [
                ////////////////////////////////////////////////////
                /// HOME
                ////////////////////////////////////////////////////

                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home_outlined,
                  ),
                  activeIcon: Icon(
                    Icons.home_rounded,
                  ),
                  label: "Home",
                ),

                ////////////////////////////////////////////////////
                /// VOTES
                ////////////////////////////////////////////////////

              ///  BottomNavigationBarItem(
            ///      icon: Icon(
              ///      Icons.how_to_vote_outlined,
                ///     ),
              ///   activeIcon: Icon(
              ///      Icons.how_to_vote_rounded,
                ///     ),
                ///      label: "Votes",
           // ///     ),

                ////////////////////////////////////////////////////
                /// READINESS
                ////////////////////////////////////////////////////

              ///    BottomNavigationBarItem(
              ///     icon: Icon(
              ///        Icons.insights_outlined,
              ///       ),
              ///      activeIcon: Icon(
              ///        Icons.insights_rounded,
              ///      ),
              ///     label: "Readiness",
                ///   ),

                ////////////////////////////////////////////////////
                /// LEADERBOARD
                ////////////////////////////////////////////////////

              ///    BottomNavigationBarItem(
              ///    icon: Icon(
              ///     Icons.leaderboard_outlined,
              ///    ),
              ///    activeIcon: Icon(
              ///       Icons.leaderboard_rounded,
              ///     ),
              ///    label: "Ranks",
                ///     ),

                ////////////////////////////////////////////////////
                /// PROFILE
                ////////////////////////////////////////////////////

                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person_outline_rounded,
                  ),
                  activeIcon: Icon(
                    Icons.person_rounded,
                  ),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
