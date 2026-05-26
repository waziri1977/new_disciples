import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

class EditProfileScreen
    extends StatefulWidget {

  final Map userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen>
  createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final fullNameController =
  TextEditingController();

  final phoneController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool isLoading = false;

  bool obscurePassword = true;

  bool obscureConfirmPassword =
  true;

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/update_profile.php";

  @override
  void initState() {

    super.initState();

    //////////////////////////////////////////////////////////
    /// PREFILL DATA
    //////////////////////////////////////////////////////////

    fullNameController.text =
    widget.userData['full_name'];

    phoneController.text =
    widget.userData['phone'];
  }

  ////////////////////////////////////////////////////////////
  /// UPDATE PROFILE
  ////////////////////////////////////////////////////////////

  Future<void> updateProfile() async {

    //////////////////////////////////////////////////////////
    /// VALIDATION
    //////////////////////////////////////////////////////////

    if(

    passwordController.text
        .trim()
        .isEmpty ||

        confirmPasswordController
            .text
            .trim()
            .isEmpty

    ){

      showMessage(
        "Please fill all fields",
      );

      return;
    }

    //////////////////////////////////////////////////////////
    /// PASSWORD MATCH
    //////////////////////////////////////////////////////////

    if(

    passwordController.text
        .trim()

        !=

        confirmPasswordController
            .text
            .trim()

    ){

      showMessage(
        "Passwords do not match",
      );

      return;
    }

    //////////////////////////////////////////////////////////
    /// PASSWORD LENGTH
    //////////////////////////////////////////////////////////

    if(

    passwordController.text
        .trim()
        .length < 6

    ){

      showMessage(
        "Password must be at least 6 characters",
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      ////////////////////////////////////////////////////////
      /// API REQUEST
      ////////////////////////////////////////////////////////

      final response =
      await http.post(

        Uri.parse(apiUrl),

        body: {

          "contestant_id":

          widget.userData['id']
              .toString(),

          "password":

          passwordController.text
              .trim(),
        },
      );

      ////////////////////////////////////////////////////////
      /// JSON
      ////////////////////////////////////////////////////////

      final data =
      jsonDecode(
          response.body);

      setState(() {
        isLoading = false;
      });

      ////////////////////////////////////////////////////////
      /// MESSAGE
      ////////////////////////////////////////////////////////

      showMessage(

        data['message'],

        isError:
        data['status']
            != true,
      );

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
  /// PREMIUM MESSAGE
  ////////////////////////////////////////////////////////////

  void showMessage(
      String message, {

        bool isError = true,

      }) {

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        behavior:
        SnackBarBehavior.floating,

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        margin:
        const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),

        duration:
        const Duration(
            seconds: 3),

        content: Container(

          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),

          decoration: BoxDecoration(

            gradient:
            LinearGradient(

              colors:

              isError

                  ? [

                const Color(
                    0xFFFF1744),

                const Color(
                    0xFFD50000),
              ]

                  : [

                const Color(
                    0xFF00C853),

                const Color(
                    0xFF64DD17),
              ],
            ),

            borderRadius:
            BorderRadius.circular(
                24),

            boxShadow: [

              BoxShadow(

                color:

                isError

                    ? Colors.red
                    .withOpacity(
                    0.35)

                    : Colors.green
                    .withOpacity(
                    0.35),

                blurRadius: 24,

                offset:
                const Offset(
                    0,
                    10),
              ),
            ],
          ),

          child: Row(

            children: [

              //////////////////////////////////////////////////
              /// ICON
              //////////////////////////////////////////////////

              Container(

                height: 52,
                width: 52,

                decoration:
                BoxDecoration(

                  color:
                  Colors.white
                      .withOpacity(
                      0.15),

                  shape:
                  BoxShape.circle,
                ),

                child: Icon(

                  isError

                      ? Icons.warning_amber_rounded

                      : Icons.check_circle,

                  color:
                  Colors.white,

                  size: 30,
                ),
              ),

              const SizedBox(
                  width: 16),

              //////////////////////////////////////////////////
              /// MESSAGE
              //////////////////////////////////////////////////

              Expanded(

                child: Text(

                  message,

                  style:
                  const TextStyle(

                    color:
                    Colors.white,

                    fontSize: 15,

                    fontWeight:
                    FontWeight.w700,

                    height: 1.5,
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
          "Edit Profile",
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(
            24),

        child: Column(

          children: [

            ////////////////////////////////////////////////////
            /// PROFILE ICON
            ////////////////////////////////////////////////////

            Container(

              height: 110,
              width: 110,

              decoration:
              BoxDecoration(

                color:
                Colors.black,

                borderRadius:
                BorderRadius.circular(
                    30),

                boxShadow: [

                  BoxShadow(

                    color:
                    Colors.black
                        .withOpacity(
                        0.25),

                    blurRadius: 25,

                    offset:
                    const Offset(
                        0,
                        15),
                  ),
                ],
              ),

              child: Center(

                child: Image.asset(

                  "assets/icon/icon.png",

                  width: 75,
                  height: 75,

                  fit:
                  BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(
                height: 35),

            ////////////////////////////////////////////////////
            /// FULL NAME (DISABLED)
            ////////////////////////////////////////////////////

            buildDisabledField(

              title:
              "Full Name",

              controller:
              fullNameController,

              icon:
              Icons.person_outline,
            ),

            const SizedBox(
                height: 22),

            ////////////////////////////////////////////////////
            /// PHONE (DISABLED)
            ////////////////////////////////////////////////////

            buildDisabledField(

              title:
              "Phone Number",

              controller:
              phoneController,

              icon:
              Icons.phone_android,
            ),

            const SizedBox(
                height: 22),

            ////////////////////////////////////////////////////
            /// PASSWORD
            ////////////////////////////////////////////////////

            buildPasswordField(),

            const SizedBox(
                height: 22),

            ////////////////////////////////////////////////////
            /// CONFIRM PASSWORD
            ////////////////////////////////////////////////////

            buildConfirmPasswordField(),

            const SizedBox(
                height: 35),

            ////////////////////////////////////////////////////
            /// UPDATE BUTTON
            ////////////////////////////////////////////////////

            SizedBox(

              width:
              double.infinity,

              height: 60,

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

                isLoading

                    ? null

                    : updateProfile,

                child:

                isLoading

                    ? const CircularProgressIndicator(
                  color:
                  Colors.black,
                )

                    : const Text(

                  "UPDATE PASSWORD",

                  style:
                  TextStyle(

                    color:
                    Colors.black,

                    fontSize: 17,

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

  ////////////////////////////////////////////////////////////
  /// DISABLED FIELD
  ////////////////////////////////////////////////////////////

  Widget buildDisabledField({

    required String title,

    required TextEditingController
    controller,

    required IconData icon,

  }) {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Text(

          title,

          style:
          const TextStyle(

            color:
            Colors.white,

            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(
            height: 12),

        TextField(

          controller:
          controller,

          enabled: false,

          style:
          const TextStyle(
            color:
            Colors.white70,
          ),

          decoration:
          InputDecoration(

            prefixIcon:
            Icon(

              icon,

              color:
              const Color(
                  0xFFFFC107),
            ),

            filled: true,

            fillColor:
            const Color(
                0xFF161B22),

            disabledBorder:
            OutlineInputBorder(

              borderRadius:
              BorderRadius.circular(
                  18),

              borderSide:
              BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// PASSWORD FIELD
  ////////////////////////////////////////////////////////////

  Widget buildPasswordField() {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(

          "New Password",

          style:
          TextStyle(

            color:
            Colors.white,

            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(
            height: 12),

        TextField(

          controller:
          passwordController,

          obscureText:
          obscurePassword,

          style:
          const TextStyle(
            color:
            Colors.white,
          ),

          decoration:
          InputDecoration(

            hintText:
            "Enter new password",

            hintStyle:
            const TextStyle(
              color:
              Colors.white38,
            ),

            prefixIcon:
            const Icon(

              Icons.lock_outline,

              color:
              Color(
                  0xFFFFC107),
            ),

            suffixIcon:
            IconButton(

              icon:
              Icon(

                obscurePassword

                    ? Icons.visibility_off

                    : Icons.visibility,

                color:
                Colors.white70,
              ),

              onPressed:
                  () {

                setState(() {

                  obscurePassword =
                  !obscurePassword;
                });
              },
            ),

            filled: true,

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
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// CONFIRM PASSWORD
  ////////////////////////////////////////////////////////////

  Widget buildConfirmPasswordField() {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(

          "Confirm Password",

          style:
          TextStyle(

            color:
            Colors.white,

            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(
            height: 12),

        TextField(

          controller:
          confirmPasswordController,

          obscureText:
          obscureConfirmPassword,

          style:
          const TextStyle(
            color:
            Colors.white,
          ),

          decoration:
          InputDecoration(

            hintText:
            "Confirm password",

            hintStyle:
            const TextStyle(
              color:
              Colors.white38,
            ),

            prefixIcon:
            const Icon(

              Icons.lock_outline,

              color:
              Color(
                  0xFFFFC107),
            ),

            suffixIcon:
            IconButton(

              icon:
              Icon(

                obscureConfirmPassword

                    ? Icons.visibility_off

                    : Icons.visibility,

                color:
                Colors.white70,
              ),

              onPressed:
                  () {

                setState(() {

                  obscureConfirmPassword =
                  !obscureConfirmPassword;
                });
              },
            ),

            filled: true,

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
      ],
    );
  }
}