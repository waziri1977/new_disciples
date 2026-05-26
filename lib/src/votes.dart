import 'package:flutter/material.dart';

class VotesScreen extends StatelessWidget {

  final Map userData;

  const VotesScreen({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding:
        const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "Audience Votes",

              style: TextStyle(
                color: Colors.white,

                fontSize: 28,

                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(height: 30),

            buildVoteCard(
              title: "Total Votes",
              value: "#",
            ),

            const SizedBox(height: 20),

            buildVoteCard(
              title: "Current Ranking",
              value: "#",
            ),

            const SizedBox(height: 20),

            buildVoteCard(
              title: "Weekly Votes",
              value: "#",
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVoteCard({
    required String title,
    required String value,
  }) {

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: const Color(0xFF161B22),

        borderRadius:
        BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            title,

            style: const TextStyle(
              color: Colors.white54,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,

            style: const TextStyle(
              color: Color(0xFFFFC107),

              fontSize: 34,

              fontWeight:
              FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}