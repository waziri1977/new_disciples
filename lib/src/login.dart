// login.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

import 'registration.dart';
import 'contestant_dashboard.dart';
import 'jury_dashboard.dart';
import 'admin_dashboard.dart';

class LoginScreen
    extends StatefulWidget {

  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen>
  createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final phoneController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool obscurePassword =
  true;

  bool isLoading = false;

  ////////////////////////////////////////////////////////////
  /// API URL
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/login.php";

  ////////////////////////////////////////////////////////////
  /// LOGIN FUNCTION
  ////////////////////////////////////////////////////////////

  Future<void>
  loginUser() async {

    //////////////////////////////////////////////////////////
    /// VALIDATION
    //////////////////////////////////////////////////////////

    if (

    phoneController.text
        .trim()
        .isEmpty ||

        passwordController.text
            .trim()
            .isEmpty

    ) {

      showMessage(
        "Please fill all fields",
      );

      return;
    }

    //////////////////////////////////////////////////////////
    /// PHONE VALIDATION
    //////////////////////////////////////////////////////////



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

        headers: {
          "Content-Type":
          "application/json",
        },

        body: jsonEncode({

          "phone":

          phoneController.text
              .trim(),

          "password":

          passwordController.text
              .trim(),
        }),
      );

      ////////////////////////////////////////////////////////
      /// DEBUG
      ////////////////////////////////////////////////////////

      print(response.body);

      ////////////////////////////////////////////////////////
      /// JSON DECODE
      ////////////////////////////////////////////////////////

      final data =
      jsonDecode(
          response.body);

      setState(() {
        isLoading = false;
      });

      ////////////////////////////////////////////////////////
      /// SUCCESS
      ////////////////////////////////////////////////////////

      if (

      data['status']
          == true

      ) {

        //////////////////////////////////////////////////////
        /// SUCCESS MESSAGE
        //////////////////////////////////////////////////////

        showMessage(

          "Login successful",

          isError: false,
        );

        //////////////////////////////////////////////////////
        /// ROLE
        //////////////////////////////////////////////////////

        String role =

        data['user']['role']
            .toString();

        //////////////////////////////////////////////////////
        /// ADMIN
        //////////////////////////////////////////////////////

        if (

        role == "admin"

        ) {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>

                  AdminDashboard(

                    adminData:
                    data['user'],
                  ),
            ),
          );
        }

        //////////////////////////////////////////////////////
        /// JURY
        //////////////////////////////////////////////////////

        else if (

        role == "jury"

        ) {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>

                  JuryDashboard(

                    juryData:
                    data['user'],
                  ),
            ),
          );
        }

        //////////////////////////////////////////////////////
        /// CONTESTANT
        //////////////////////////////////////////////////////

        else {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>

                  ContestantDashboard(

                    userData:
                    data['user'],
                  ),
            ),
          );
        }

      } else {

        showMessage(
          data['message'],
        );
      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      print(e);

      showMessage(
        "Oops! No internet connection. Please try again",
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

    //////////////////////////////////////////////////////////
    /// REMOVE OLD
    //////////////////////////////////////////////////////////

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    //////////////////////////////////////////////////////////
    /// SHOW PREMIUM SNACKBAR
    //////////////////////////////////////////////////////////

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

              begin:
              Alignment.topLeft,

              end:
              Alignment.bottomRight,
            ),

            borderRadius:
            BorderRadius.circular(
                24),

            border: Border.all(

              color:
              Colors.white
                  .withOpacity(
                  0.15),

              width: 1.2,
            ),

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

                spreadRadius: 1,

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

                    letterSpacing:
                    0.3,
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

      body: SafeArea(

        child:
        SingleChildScrollView(

          child: Column(

            children: [

              //////////////////////////////////////////////////
              /// TOP SECTION
              //////////////////////////////////////////////////

              Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 50,
                ),

                decoration:
                const BoxDecoration(

                  gradient:
                  LinearGradient(

                    colors: [

                      Color(
                          0xFFFFC107),

                      Color(
                          0xFFFFB300),
                    ],
                  ),

                  borderRadius:
                  BorderRadius.only(

                    bottomLeft:
                    Radius.circular(
                        45),

                    bottomRight:
                    Radius.circular(
                        45),
                  ),
                ),

                child: Column(

                  children: [

                    //////////////////////////////////////////////
                    /// LOGO
                    //////////////////////////////////////////////

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

                            blurRadius:
                            25,

                            offset:
                            const Offset(
                                0,
                                15),
                          ),
                        ],
                      ),

                      child:
                      Center(

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
                        height: 30),

                    const Text(

                      "Welcome Back",

                      style:
                      TextStyle(

                        color:
                        Colors.black,

                        fontSize: 34,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                        height: 12),

                    const Text(

                      "Login to continue your reality show journey",

                      textAlign:
                      TextAlign.center,

                      style:
                      TextStyle(

                        color:
                        Colors.black87,

                        fontSize: 16,

                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              //////////////////////////////////////////////////
              /// FORM
              //////////////////////////////////////////////////

              Padding(

                padding:
                const EdgeInsets.all(
                    28),

                child: Column(

                  children: [

                    const SizedBox(
                        height: 15),

                    //////////////////////////////////////////////////
                    /// PHONE FIELD
                    //////////////////////////////////////////////////

                    buildInputField(

                      title:
                      "Email or Phone Number",

                      hint:
                      "Enter your email or phone no.",

                      icon:
                      Icons.phone_android_outlined,

                      controller:
                      phoneController,

                      keyboardType:
                      TextInputType.text,
                    ),

                    const SizedBox(
                        height: 24),

                    //////////////////////////////////////////////////
                    /// PASSWORD
                    //////////////////////////////////////////////////

                    buildPasswordField(),

                    const SizedBox(
                        height: 35),

                    //////////////////////////////////////////////////
                    /// LOGIN BUTTON
                    //////////////////////////////////////////////////

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

                            : loginUser,

                        child:

                        isLoading

                            ? const CircularProgressIndicator(
                          color:
                          Colors.black,
                        )

                            : const Text(

                          "LOGIN",

                          style:
                          TextStyle(

                            color:
                            Colors.black,

                            fontSize: 18,

                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 35),

                    //////////////////////////////////////////////////
                    /// REGISTER LINK
                    //////////////////////////////////////////////////

                    Row(

                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        const Text(

                          "Don’t have an account?",

                          style:
                          TextStyle(
                            color:
                            Colors.white70,
                          ),
                        ),

                        TextButton(

                          onPressed:
                              () {

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>

                                const RegistrationScreen(),
                              ),
                            );
                          },

                          child:
                          const Text(

                            "Register",

                            style:
                            TextStyle(

                              color:
                              Color(
                                  0xFFFFC107),

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// INPUT FIELD
  ////////////////////////////////////////////////////////////

  Widget buildInputField({

    required String title,

    required String hint,

    required IconData icon,

    required TextEditingController
    controller,

    required TextInputType
    keyboardType,

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

          keyboardType:
          keyboardType,

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

            prefixIcon:
            Icon(

              icon,

              color:
              const Color(
                  0xFFFFC107),
            ),

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

          "Password",

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
            "Enter your password",

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
      ],
    );
  }
}