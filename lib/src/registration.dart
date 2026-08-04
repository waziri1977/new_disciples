// registration.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
as http;

class RegistrationScreen
    extends StatefulWidget {

  const RegistrationScreen({
    super.key,
  });

  @override
  State<RegistrationScreen>
  createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final fullNameController =
  TextEditingController();

  final emailController =
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

  bool obscurePassword =
  true;

  bool isLoading = false;

  ////////////////////////////////////////////////////////////
  /// API URL
  ////////////////////////////////////////////////////////////

  final String apiUrl =
      "https://new-disciples.com/api/register.php";

  ////////////////////////////////////////////////////////////
  /// REGISTER USER
  ////////////////////////////////////////////////////////////

  Future<void>
  registerUser() async {

    //////////////////////////////////////////////////////////
    /// VALIDATION
    //////////////////////////////////////////////////////////

    if (

    fullNameController.text
        .trim()
        .isEmpty ||

        emailController.text
            .trim()
            .isEmpty ||

        passwordController.text
            .trim()
            .isEmpty ||

        confirmPasswordController
            .text
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

    String phone = phoneController.text.trim();

    if (phone.isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        showMessage("Phone must contain numbers only");
        return;
      }

      if (phone.length < 11 || phone.length > 15) {
        showMessage("Please enter a valid phone number");
        return;
      }
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

          "full_name":

          fullNameController
              .text
              .trim(),

          "email":

          emailController
              .text
              .trim(),

          "phone":

          phoneController
              .text
              .trim(),

          "password":

          passwordController
              .text
              .trim(),
        },
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

      if (data['status']
          == true) {

        showMessage(
          "Registration successful",
          isError: false,
        );

        //////////////////////////////////////////////////////
        /// GO TO SUCCESS PAGE
        //////////////////////////////////////////////////////

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(
            builder: (_) =>
                SuccessScreen(

                  userName:
                  fullNameController
                      .text,
                ),
          ),
        );

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
          vertical: 12,
        ),

        content: Container(

          padding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),

          decoration: BoxDecoration(

            gradient:
            LinearGradient(

              colors:

              isError

                  ? [

                const Color(
                    0xFFD50000),

                const Color(
                    0xFFFF1744),
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
                20),

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

                blurRadius: 20,

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

              ////////////////////////////////////////////////
              /// ICON
              ////////////////////////////////////////////////

              Container(

                height: 48,
                width: 48,

                decoration:
                BoxDecoration(

                  color:
                  Colors.white
                      .withOpacity(
                      0.18),

                  shape:
                  BoxShape.circle,
                ),

                child: Icon(

                  isError

                      ? Icons.error_outline

                      : Icons.check_circle,

                  color:
                  Colors.white,

                  size: 28,
                ),
              ),

              const SizedBox(
                  width: 16),

              ////////////////////////////////////////////////
              /// MESSAGE
              ////////////////////////////////////////////////

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

        duration:
        const Duration(
            seconds: 3),
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

          padding:
          const EdgeInsets.all(
              28),

          child: Column(

            children: [

              //////////////////////////////////////////////////
              /// HEADER
              //////////////////////////////////////////////////

              Container(

                width:
                double.infinity,

                padding:
                const EdgeInsets
                    .symmetric(

                  horizontal:
                  30,

                  vertical:
                  45,
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

                    begin:
                    Alignment.topLeft,

                    end:
                    Alignment.bottomRight,
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
                      const Center(

                        child: Image(

                          image:
                          AssetImage(
                            "assets/icon/icon.png",
                          ),

                          width: 75,
                          height: 75,

                          fit:
                          BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 28),

                    const Text(

                      "Create Account",

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

                      "Join the New Disciples reality competition platform",

                      textAlign:
                      TextAlign.center,

                      style:
                      TextStyle(

                        color:
                        Colors.black87,

                        fontSize: 15,

                        height: 1.6,

                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 35),

              //////////////////////////////////////////////////
              /// FULL NAME
              //////////////////////////////////////////////////

              buildInputField(

                title:
                "Full Name",

                hint:
                "Enter your full name",

                icon:
                Icons.person_outline,

                controller:
                fullNameController,
              ),

              const SizedBox(
                  height: 22),

              //////////////////////////////////////////////////
              /// EMAIL
              //////////////////////////////////////////////////

              buildInputField(

                title:
                "Email Address",

                hint:
                "Enter your email",

                icon:
                Icons.email_outlined,

                controller:
                emailController,
              ),

              const SizedBox(
                  height: 22),

              //////////////////////////////////////////////////
              /// PHONE
              //////////////////////////////////////////////////

              buildPhoneField(),

              const SizedBox(
                  height: 22),

              //////////////////////////////////////////////////
              /// PASSWORD
              //////////////////////////////////////////////////

              buildPasswordField(),

              const SizedBox(
                  height: 22),

              //////////////////////////////////////////////////
              /// CONFIRM PASSWORD
              //////////////////////////////////////////////////

              buildConfirmPasswordField(),

              const SizedBox(
                  height: 35),

              //////////////////////////////////////////////////
              /// REGISTER BUTTON
              //////////////////////////////////////////////////

              SizedBox(

                width:
                double.infinity,

                height: 62,

                child:
                ElevatedButton(

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(
                        0xFFFFC107),

                    elevation: 0,

                    shape:
                    RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(
                          22),
                    ),
                  ),

                  onPressed:

                  isLoading

                      ? null

                      : registerUser,

                  child:

                  isLoading

                      ? const SizedBox(

                    height: 26,
                    width: 26,

                    child:
                    CircularProgressIndicator(

                      color:
                      Colors.black,

                      strokeWidth: 3,
                    ),
                  )

                      : const Text(

                    "CREATE ACCOUNT",

                    style:
                    TextStyle(

                      color:
                      Colors.black,

                      fontSize: 17,

                      fontWeight:
                      FontWeight.w900,

                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 35),

              //////////////////////////////////////////////////
              /// LOGIN
              //////////////////////////////////////////////////

              Row(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  const Text(

                    "Already have an account?",

                    style:
                    TextStyle(

                      color:
                      Colors.white70,

                      fontSize: 15,
                    ),
                  ),

                  TextButton(

                    onPressed:
                        () {

                      Navigator.pop(
                          context);
                    },

                    child:
                    const Text(

                      "Login",

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
  /// PHONE FIELD
  ////////////////////////////////////////////////////////////

  Widget buildPhoneField() {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(

          "Phone Number (Optional)",

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
          phoneController,

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
            "Enter your phone number",

            hintStyle:
            const TextStyle(
              color:
              Colors.white38,
            ),

            prefixIcon:
            const Icon(

              Icons.phone_android,

              color:
              Color(
                  0xFFFFC107),
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
  /// PASSWORD FIELD
  ////////////////////////////////////////////////////////////

  Widget buildPasswordField() {

    return buildPasswordWidget(

      title:
      "Password",

      hint:
      "Create password",

      controller:
      passwordController,
    );
  }

  ////////////////////////////////////////////////////////////
  /// CONFIRM PASSWORD FIELD
  ////////////////////////////////////////////////////////////

  Widget buildConfirmPasswordField() {

    return buildPasswordWidget(

      title:
      "Confirm Password",

      hint:
      "Confirm password",

      controller:
      confirmPasswordController,
    );
  }

  ////////////////////////////////////////////////////////////
  /// PASSWORD WIDGET
  ////////////////////////////////////////////////////////////

  Widget buildPasswordWidget({

    required String title,

    required String hint,

    required TextEditingController
    controller,

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
            hint,

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
}

////////////////////////////////////////////////////////////
/// SUCCESS SCREEN
////////////////////////////////////////////////////////////

class SuccessScreen
    extends StatelessWidget {

  final String userName;

  const SuccessScreen({

    super.key,

    required this.userName,
  });

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(
          0xFF070B14),

      body: Center(

        child: Padding(

          padding:
          const EdgeInsets.all(
              28),

          child: Column(

            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              Container(

                height: 140,
                width: 140,

                decoration:
                const BoxDecoration(

                  shape:
                  BoxShape.circle,

                  gradient:
                  LinearGradient(

                    colors: [

                      Color(
                          0xFFFFC107),

                      Color(
                          0xFFFFB300),
                    ],
                  ),
                ),

                child:
                const Icon(

                  Icons.check,

                  color:
                  Colors.black,

                  size: 80,
                ),
              ),

              const SizedBox(
                  height: 45),

              const Text(

                "Registration Successful",

                textAlign:
                TextAlign.center,

                style:
                TextStyle(

                  color:
                  Colors.white,

                  fontSize: 32,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                  height: 18),

              Text(

                "Welcome $userName!\nYour account has been created successfully.",

                textAlign:
                TextAlign.center,

                style:
                const TextStyle(

                  color:
                  Colors.white70,

                  fontSize: 16,

                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}