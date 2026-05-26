import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

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

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final scoreController =
  TextEditingController();

  final commentController =
  TextEditingController();

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = false;

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://aktcpro.com.ng/api/submit_jury_score.php";

  ////////////////////////////////////////////////////////////
  /// SUBMIT SCORE
  ////////////////////////////////////////////////////////////

  Future<void>
  submitReview()
  async {

    if(

    scoreController.text
        .trim()
        .isEmpty

    ){

      showMessage(
        "Enter jury score",
      );

      return;
    }

    setState(() {

      isLoading = true;
    });

    try {

      final response =
      await http.post(

        Uri.parse(apiUrl),

        body: {

          "contestant_id":

          widget.contestant['id']
              .toString(),

          "jury_id":

          widget.juryData['id']
              .toString(),

          "score":

          scoreController.text
              .trim(),

          "comment":

          commentController.text
              .trim(),
        },
      );

      final data =
      jsonDecode(
          response.body);

      setState(() {

        isLoading = false;
      });

      if(

      data['status']
          == true

      ){

        showMessage(

          "Review submitted",

          isError: false,
        );

        Navigator.pop(
            context);

      }else{

        showMessage(
          data['message'],
        );
      }

    } catch (e) {

      setState(() {

        isLoading = false;
      });

      showMessage(
        "Something went wrong",
      );
    }
  }

  ////////////////////////////////////////////////////////////
  /// MESSAGE
  ////////////////////////////////////////////////////////////

  void showMessage(
      String message, {

        bool isError = true,

      }) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        backgroundColor:

        isError

            ? Colors.red

            : Colors.green,

        content:
        Text(message),
      ),
    );
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

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title: const Text(
          "Jury Review",
        ),
      ),

      body:
      SingleChildScrollView(

        padding:
        const EdgeInsets.all(
            24),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [

            ////////////////////////////////////////////////////
            /// CONTESTANT
            ////////////////////////////////////////////////////

            Text(

              widget.contestant[
              'full_name']
                  .toString(),

              style:
              const TextStyle(

                color:
                Colors.white,

                fontSize: 26,

                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(
                height: 10),

            Text(

              widget.contestant[
              'answer']
                  .toString(),

              style:
              const TextStyle(

                color:
                Colors.white70,

                height: 1.8,
              ),
            ),

            const SizedBox(
                height: 35),

            ////////////////////////////////////////////////////
            /// SCORE
            ////////////////////////////////////////////////////

            const Text(

              "Score",

              style:
              TextStyle(
                color:
                Colors.white,
              ),
            ),

            const SizedBox(
                height: 12),

            TextField(

              controller:
              scoreController,

              keyboardType:
              TextInputType.number,

              style:
              const TextStyle(
                color:
                Colors.white,
              ),

              decoration:
              InputDecoration(

                hintText:
                "Enter score",

                filled:
                true,

                fillColor:
                const Color(
                    0xFF161B22),

                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(
                      18),

                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
                height: 24),

            ////////////////////////////////////////////////////
            /// COMMENT
            ////////////////////////////////////////////////////

            const Text(

              "Comment",

              style:
              TextStyle(
                color:
                Colors.white,
              ),
            ),

            const SizedBox(
                height: 12),

            TextField(

              controller:
              commentController,

              maxLines: 5,

              style:
              const TextStyle(
                color:
                Colors.white,
              ),

              decoration:
              InputDecoration(

                hintText:
                "Enter comment",

                filled:
                true,

                fillColor:
                const Color(
                    0xFF161B22),

                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(
                      18),

                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
                height: 35),

            ////////////////////////////////////////////////////
            /// SUBMIT
            ////////////////////////////////////////////////////

            SizedBox(

              width:
              double.infinity,

              height: 58,

              child:
              ElevatedButton(

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(
                      0xFFFFC107),
                ),

                onPressed:

                isLoading

                    ? null

                    : submitReview,

                child:

                isLoading

                    ? const CircularProgressIndicator(
                  color:
                  Colors.black,
                )

                    : const Text(

                  "SUBMIT REVIEW",

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