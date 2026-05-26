// manage_questions.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

class ManageQuestionsScreen
    extends StatefulWidget {

  const ManageQuestionsScreen({
    super.key,
  });

  @override
  State<ManageQuestionsScreen>
  createState() =>
      _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState
    extends State<ManageQuestionsScreen> {

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String getApi =
      "https://new-disciples.com/api/get_questions.php";

  final String createApi =
      "https://new-disciples.com/api/create_question.php";

  final String updateApi =
      "https://new-disciples.com/api/update_question.php";

  final String deleteApi =
      "https://new-disciples.com/api/delete_question.php";

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final questionController =
  TextEditingController();

  final roundController =
  TextEditingController();

  final startController =
  TextEditingController();

  final endController =
  TextEditingController();

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = true;

  bool isSubmitting = false;

  List questions = [];

  ////////////////////////////////////////////////////////////
  /// GET QUESTIONS
  ////////////////////////////////////////////////////////////

  Future<void>
  getQuestions()
  async {

    try {

      final response =
      await http.get(
        Uri.parse(getApi),
      );

      final data =
      jsonDecode(
          response.body);

      if(data['status']
          == true){

        setState(() {

          questions =
          data['questions'];

          isLoading = false;
        });

      }else{

        setState(() {
          isLoading = false;
        });
      }

    }catch(e){

      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// CREATE QUESTION
  ////////////////////////////////////////////////////////////

  Future<void>
  createQuestion()
  async {

    if(

    questionController.text
        .trim()
        .isEmpty ||

        roundController.text
            .trim()
            .isEmpty ||

        startController.text
            .trim()
            .isEmpty ||

        endController.text
            .trim()
            .isEmpty

    ){

      showMessage(
          "All fields required");

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {

      final response =
      await http.post(

        Uri.parse(createApi),

        body: {

          "question":
          questionController.text,

          "round_name":
          roundController.text,

          "start_time":
          startController.text,

          "end_time":
          endController.text,
        },
      );

      final data =
      jsonDecode(
          response.body);

      setState(() {
        isSubmitting = false;
      });

      showMessage(
          data['message']);

      if(data['status']
          == true){

        Navigator.pop(context);

        clearControllers();

        getQuestions();
      }

    }catch(e){

      print(e);

      setState(() {
        isSubmitting = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// UPDATE QUESTION
  ////////////////////////////////////////////////////////////

  Future<void>
  updateQuestion(
      String id)
  async {

    setState(() {
      isSubmitting = true;
    });

    try {

      final response =
      await http.post(

        Uri.parse(updateApi),

        body: {

          "question_id": id,

          "question":
          questionController.text,

          "round_name":
          roundController.text,

          "start_time":
          startController.text,

          "end_time":
          endController.text,
        },
      );

      final data =
      jsonDecode(
          response.body);

      setState(() {
        isSubmitting = false;
      });

      showMessage(
          data['message']);

      Navigator.pop(context);

      getQuestions();

    }catch(e){

      print(e);

      setState(() {
        isSubmitting = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// DELETE QUESTION
  ////////////////////////////////////////////////////////////

  Future<void>
  deleteQuestion(
      String id)
  async {

    try {

      final response =
      await http.post(

        Uri.parse(deleteApi),

        body: {

          "question_id":
          id,
        },
      );

      final data =
      jsonDecode(
          response.body);

      showMessage(
          data['message']);

      getQuestions();

    }catch(e){

      print(e);
    }
  }

  ////////////////////////////////////////////////////////////
  /// CLEAR
  ////////////////////////////////////////////////////////////

  void clearControllers(){

    questionController.clear();

    roundController.clear();

    startController.clear();

    endController.clear();
  }

  ////////////////////////////////////////////////////////////
  /// MESSAGE
  ////////////////////////////////////////////////////////////

  void showMessage(
      String message){

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        backgroundColor:
        const Color(0xFFFFC107),

        content:
        Text(

          message,

          style:
          const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    getQuestions();
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

      floatingActionButton:

      FloatingActionButton.extended(

        backgroundColor:
        const Color(
            0xFFFFC107),

        onPressed:
        showCreateDialog,

        icon: const Icon(
          Icons.add,
          color: Colors.black,
        ),

        label: const Text(

          "New Question",

          style:
          TextStyle(
            color:
            Colors.black,

            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

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
          getQuestions,

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

                const Text(
                  "Manage Questions",

                  style:
                  TextStyle(

                    color:
                    Colors.white,

                    fontSize:
                    32,

                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                    height:
                    10),

                const Text(
                  "Control live reality show rounds and contestant questions.",

                  style:
                  TextStyle(

                    color:
                    Colors.white54,

                    height:
                    1.7,
                  ),
                ),

                const SizedBox(
                    height:
                    35),

                //////////////////////////////////////////////////
                /// LIVE SUMMARY
                //////////////////////////////////////////////////

                Container(

                  width:
                  double.infinity,

                  padding:
                  const EdgeInsets.all(
                      26),

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
                        32),
                  ),

                  child: Row(
                    children: [

                      Container(

                        padding:
                        const EdgeInsets
                            .all(18),

                        decoration:
                        BoxDecoration(

                          color:
                          Colors.black
                              .withOpacity(
                              0.1),

                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),

                        child:
                        const Icon(
                          Icons.quiz,

                          color:
                          Colors.black,

                          size: 34,
                        ),
                      ),

                      const SizedBox(
                          width:
                          20),

                      Expanded(
                        child: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            Text(

                              questions.length
                                  .toString(),

                              style:
                              const TextStyle(

                                color:
                                Colors.black,

                                fontSize:
                                34,

                                fontWeight:
                                FontWeight
                                    .w900,
                              ),
                            ),

                            const SizedBox(
                                height:
                                6),

                            const Text(
                              "Total Questions",

                              style:
                              TextStyle(
                                color:
                                Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height:
                    35),

                //////////////////////////////////////////////////
                /// QUESTIONS
                //////////////////////////////////////////////////

                ListView.builder(

                  itemCount:
                  questions.length,

                  shrinkWrap:
                  true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  itemBuilder:
                      (context,index){

                    final question =
                    questions[index];

                    return buildQuestionCard(
                        question);
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
  /// QUESTION CARD
  ////////////////////////////////////////////////////////////

  Widget buildQuestionCard(
      Map question){

    final status =
    question['status']
        .toString();

    return Container(

      margin:
      const EdgeInsets.only(
          bottom: 24),

      padding:
      const EdgeInsets.all(
          24),

      decoration:
      BoxDecoration(

        color:
        const Color(
            0xFF161B22),

        borderRadius:
        BorderRadius.circular(
            30),

        border: Border.all(
          color:
          Colors.white
              .withOpacity(
              0.05),
        ),
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          //////////////////////////////////////////////////////
          /// TOP BAR
          //////////////////////////////////////////////////////

          Row(
            children: [

              Container(

                height: 14,
                width: 14,

                decoration:
                BoxDecoration(

                  color:

                  status == "live"

                      ? Colors.green

                      : status == "pending"

                      ? Colors.orange

                      : Colors.red,

                  shape:
                  BoxShape.circle,
                ),
              ),

              const SizedBox(
                  width:
                  10),

              Text(

                status.toUpperCase(),

                style:
                TextStyle(

                  color:

                  status == "live"

                      ? Colors.green

                      : status == "pending"

                      ? Colors.orange

                      : Colors.red,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const Spacer(),

              Container(

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),

                decoration:
                BoxDecoration(

                  color:
                  const Color(
                      0xFFFFC107)
                      .withOpacity(
                      0.12),

                  borderRadius:
                  BorderRadius.circular(
                      16),
                ),

                child: Text(

                  question['round_name']
                      .toString(),

                  style:
                  const TextStyle(

                    color:
                    Color(
                        0xFFFFC107),

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
              height:
              22),

          //////////////////////////////////////////////////////
          /// QUESTION
          //////////////////////////////////////////////////////

          Text(

            question['question']
                .toString(),

            style:
            const TextStyle(

              color:
              Colors.white,

              fontSize:
              20,

              fontWeight:
              FontWeight.w800,

              height:
              1.6,
            ),
          ),

          const SizedBox(
              height:
              24),

          //////////////////////////////////////////////////////
          /// TIMES
          //////////////////////////////////////////////////////

          buildTimeRow(
            icon:
            Icons.play_circle,

            title:
            "Start Time",

            value:
            question['start_time']
                .toString(),
          ),

          const SizedBox(
              height:
              14),

          buildTimeRow(
            icon:
            Icons.stop_circle,

            title:
            "End Time",

            value:
            question['end_time']
                .toString(),
          ),

          const SizedBox(
              height:
              28),

          //////////////////////////////////////////////////////
          /// ACTIONS
          //////////////////////////////////////////////////////

          Row(
            children: [

              Expanded(
                child:
                ElevatedButton.icon(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(
                        0xFFFFC107),

                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          18),
                    ),
                  ),

                  onPressed: () {

                    showEditDialog(
                        question);
                  },

                  icon: const Icon(
                    Icons.edit,
                    color: Colors.black,
                  ),

                  label:
                  const Text(

                    "Edit",

                    style:
                    TextStyle(
                      color:
                      Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  width:
                  14),

              Expanded(
                child:
                ElevatedButton.icon(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.red,

                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          18),
                    ),
                  ),

                  onPressed: () {

                    deleteQuestion(
                      question['id']
                          .toString(),
                    );
                  },

                  icon: const Icon(
                    Icons.delete,
                  ),

                  label:
                  const Text(
                    "Delete",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// TIME ROW
  ////////////////////////////////////////////////////////////

  Widget buildTimeRow({

    required IconData icon,

    required String title,

    required String value,
  }) {

    return Row(
      children: [

        Icon(
          icon,

          color:
          const Color(
              0xFFFFC107),
        ),

        const SizedBox(
            width:
            12),

        Expanded(
          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [

              Text(

                title,

                style:
                const TextStyle(
                  color:
                  Colors.white54,
                ),
              ),

              const SizedBox(
                  height:
                  4),

              Text(

                value,

                style:
                const TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// CREATE DIALOG
  ////////////////////////////////////////////////////////////

  void showCreateDialog(){

    clearControllers();

    showDialog(

      context: context,

      builder: (context){

        return AlertDialog(

          backgroundColor:
          const Color(
              0xFF161B22),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
                30),
          ),

          title: const Text(
            "Create Question",

            style:
            TextStyle(
              color:
              Colors.white,
            ),
          ),

          content:
          SingleChildScrollView(

            child: Column(

              mainAxisSize:
              MainAxisSize.min,

              children: [

                buildField(
                  controller:
                  roundController,

                  hint:
                  "Round Name",
                ),

                const SizedBox(
                    height:
                    18),

                buildField(
                  controller:
                  questionController,

                  hint:
                  "Enter question",

                  maxLines: 5,
                ),

                const SizedBox(
                    height:
                    18),

                buildField(
                  controller:
                  startController,

                  hint:
                  "2026-05-20 08:00:00",
                ),

                const SizedBox(
                    height:
                    18),

                buildField(
                  controller:
                  endController,

                  hint:
                  "2026-05-20 08:10:00",
                ),
              ],
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
              ),
            ),

            ElevatedButton(

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                const Color(
                    0xFFFFC107),
              ),

              onPressed:

              isSubmitting

                  ? null

                  : createQuestion,

              child:

              isSubmitting

                  ? const SizedBox(

                height: 20,
                width: 20,

                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )

                  : const Text(

                "CREATE",

                style:
                TextStyle(
                  color:
                  Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// EDIT DIALOG
  ////////////////////////////////////////////////////////////

  void showEditDialog(
      Map question){

    questionController.text =
    question['question'];

    roundController.text =
    question['round_name'];

    startController.text =
    question['start_time'];

    endController.text =
    question['end_time'];

    showDialog(

      context: context,

      builder: (context){

        return AlertDialog(

          backgroundColor:
          const Color(
              0xFF161B22),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
                30),
          ),

          title: const Text(
            "Edit Question",

            style:
            TextStyle(
              color:
              Colors.white,
            ),
          ),

          content:
          SingleChildScrollView(

            child: Column(

              mainAxisSize:
              MainAxisSize.min,

              children: [

                buildField(
                  controller:
                  roundController,

                  hint:
                  "Round Name",
                ),

                const SizedBox(
                    height:
                    18),

                buildField(
                  controller:
                  questionController,

                  hint:
                  "Question",

                  maxLines: 5,
                ),

                const SizedBox(
                    height:
                    18),

                buildField(
                  controller:
                  startController,

                  hint:
                  "Start Time",
                ),

                const SizedBox(
                    height:
                    18),

                buildField(
                  controller:
                  endController,

                  hint:
                  "End Time",
                ),
              ],
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
              ),
            ),

            ElevatedButton(

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                const Color(
                    0xFFFFC107),
              ),

              onPressed: () {

                updateQuestion(
                  question['id']
                      .toString(),
                );
              },

              child: const Text(

                "UPDATE",

                style:
                TextStyle(
                  color:
                  Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// FIELD
  ////////////////////////////////////////////////////////////

  Widget buildField({

    required TextEditingController
    controller,

    required String hint,

    int maxLines = 1,
  }) {

    return TextField(

      controller:
      controller,

      maxLines:
      maxLines,

      style:
      const TextStyle(
        color:
        Colors.white,
      ),

      decoration:
      InputDecoration(

        hintText:
        hint,

        hintStyle:
        const TextStyle(
          color:
          Colors.white38,
        ),

        filled:
        true,

        fillColor:
        const Color(
            0xFF070B14),

        border:
        OutlineInputBorder(

          borderRadius:
          BorderRadius.circular(
              20),

          borderSide:
          BorderSide.none,
        ),
      ),
    );
  }
}