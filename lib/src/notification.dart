import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationScreen
    extends StatefulWidget {

  final String contestantId;

  const NotificationScreen({
    super.key,
    required this.contestantId,
  });

  @override
  State<NotificationScreen>
  createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  List notifications = [];

  bool isLoading = true;

  final String apiUrl =
      "http://new-disciples.com/api/get_notifications.php";

  ////////////////////////////////////////////////////////////
  /// GET NOTIFICATIONS
  ////////////////////////////////////////////////////////////

  Future<void> getNotifications() async {

    final response = await http.post(
      Uri.parse(apiUrl),

      body: {
        "contestant_id":
        widget.contestantId,
      },
    );

    final data =
    jsonDecode(response.body);

    setState(() {

      notifications =
      data['notifications'];

      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    getNotifications();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF070B14),

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title:
        const Text("Notifications"),
      ),

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xFFFFC107),
        ),
      )

          : ListView.builder(
        itemCount:
        notifications.length,

        itemBuilder:
            (context, index) {

          final item =
          notifications[index];

          return Container(
            margin:
            const EdgeInsets
                .all(16),

            padding:
            const EdgeInsets
                .all(20),

            decoration:
            BoxDecoration(
              color: const Color(
                  0xFF161B22),

              borderRadius:
              BorderRadius
                  .circular(
                  22),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(
                  item['title'],

                  style:
                  const TextStyle(
                    color:
                    Colors.white,

                    fontSize: 17,

                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),

                const SizedBox(
                    height: 10),

                Text(
                  item['message'],

                  style:
                  const TextStyle(
                    color:
                    Colors.white54,

                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}