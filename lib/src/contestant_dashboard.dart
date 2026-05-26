// contestant_dashboard.dart

import 'package:flutter/material.dart';

import 'home.dart';
import 'votes.dart';
import 'profile.dart';

class ContestantDashboard
    extends StatefulWidget {

  final Map userData;

  const ContestantDashboard({
    super.key,
    required this.userData,
  });

  @override
  State<ContestantDashboard>
  createState() =>
      _ContestantDashboardState();
}

class _ContestantDashboardState
    extends State<ContestantDashboard> {

  int currentIndex = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    //////////////////////////////////////////////////////////
    /// REMOVE QUESTION PAGE
    //////////////////////////////////////////////////////////

    pages = [

      HomeScreen(
        userData: widget.userData,
      ),

      VotesScreen(
        userData: widget.userData,
      ),

      ProfileScreen(
        userData: widget.userData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF070B14),

      body: pages[currentIndex],

      ////////////////////////////////////////////////////////
      /// PREMIUM BOTTOM NAV
      ////////////////////////////////////////////////////////

      bottomNavigationBar:
      Container(
        margin:
        const EdgeInsets.all(
            18),

        decoration: BoxDecoration(
          color:
          const Color(
              0xFF161B22),

          borderRadius:
          BorderRadius.circular(
              24),

          boxShadow: [

            BoxShadow(
              color: Colors.black
                  .withOpacity(0.3),

              blurRadius: 20,
            ),
          ],
        ),

        child: BottomNavigationBar(
          currentIndex:
          currentIndex,

          backgroundColor:
          Colors.transparent,

          elevation: 0,

          selectedItemColor:
          const Color(
              0xFFFFC107),

          unselectedItemColor:
          Colors.white38,

          type:
          BottomNavigationBarType
              .fixed,

          onTap: (index) {

            setState(() {
              currentIndex =
                  index;
            });
          },

          items: const [

            ////////////////////////////////////////////////////
            /// HOME
            ////////////////////////////////////////////////////

            BottomNavigationBarItem(
              icon: Icon(
                  Icons.home),
              label: "Home",
            ),

            ////////////////////////////////////////////////////
            /// VOTES
            ////////////////////////////////////////////////////

            BottomNavigationBarItem(
              icon: Icon(Icons
                  .how_to_vote),
              label: "Votes",
            ),

            ////////////////////////////////////////////////////
            /// PROFILE
            ////////////////////////////////////////////////////

            BottomNavigationBarItem(
              icon:
              Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}