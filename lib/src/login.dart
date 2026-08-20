// login.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'registration.dart';
import 'contestant_dashboard.dart';
import 'jury_dashboard.dart';
import 'admin_dashboard.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  ////////////////////////////////////////////////////////////
  /// STATES
  ////////////////////////////////////////////////////////////

  bool obscurePassword = true;

  bool isLoading = false;

  ////////////////////////////////////////////////////////////
  /// API URL
  ////////////////////////////////////////////////////////////

  static const String apiUrl =
      "https://new-disciples.com/api/login.php";

  ////////////////////////////////////////////////////////////
  /// PLATFORM NAME
  ////////////////////////////////////////////////////////////

  String get platformName {
    if (kIsWeb) {
      return "web";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "android";

      case TargetPlatform.iOS:
        return "ios";

      case TargetPlatform.windows:
        return "windows";

      case TargetPlatform.macOS:
        return "macos";

      case TargetPlatform.linux:
        return "linux";

      default:
        return "unknown";
    }
  }

  ////////////////////////////////////////////////////////////
  /// DISPOSE
  ////////////////////////////////////////////////////////////

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  ////////////////////////////////////////////////////////////
  /// LOGIN FUNCTION
  ////////////////////////////////////////////////////////////

  Future<void> loginUser() async {
    final String identifier =
        phoneController.text.trim();

    final String password =
        passwordController.text.trim();

    //////////////////////////////////////////////////////////
    /// VALIDATION
    //////////////////////////////////////////////////////////

    if (identifier.isEmpty ||
        password.isEmpty) {
      showMessage(
        "Please enter your email/phone number and password.",
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      ////////////////////////////////////////////////////////
      /// API REQUEST
      ////////////////////////////////////////////////////////

      final Uri uri =
          Uri.parse(apiUrl);

      debugPrint(
        "LOGIN URL: $uri",
      );

      final http.Response response =
          await http
              .post(
                uri,
                headers: {
                  "Content-Type":
                      "application/json",
                  "Accept":
                      "application/json",
                },
                body: jsonEncode({
                  "phone":
                      identifier,

                  "identifier":
                      identifier,

                  "password":
                      password,

                  "platform":
                      platformName,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 20,
                ),
              );

      ////////////////////////////////////////////////////////
      /// DEBUG
      ////////////////////////////////////////////////////////

      debugPrint(
        "LOGIN HTTP STATUS: ${response.statusCode}",
      );

      debugPrint(
        "LOGIN RESPONSE: ${response.body}",
      );

      ////////////////////////////////////////////////////////
      /// JSON DECODE
      ////////////////////////////////////////////////////////

      Map<String, dynamic> data;

      try {
        final dynamic decoded =
            jsonDecode(
          response.body,
        );

        if (decoded is! Map) {
          throw const FormatException(
            "Server response is not a JSON object.",
          );
        }

        data =
            Map<String, dynamic>.from(
          decoded,
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
        });

        debugPrint(
          "LOGIN JSON ERROR: $e",
        );

        showMessage(
          "The server returned invalid data. "
          "HTTP ${response.statusCode}.",
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ////////////////////////////////////////////////////////
      /// HTTP ERROR
      ////////////////////////////////////////////////////////

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        showMessage(
          data['message']?.toString() ??
              "Login failed. Server returned HTTP ${response.statusCode}.",
        );

        return;
      }

      ////////////////////////////////////////////////////////
      /// SUCCESS
      ////////////////////////////////////////////////////////

      if (data['status'] == true) {
        final dynamic userRaw =
            data['user'];

        if (userRaw is! Map) {
          showMessage(
            "Login succeeded but the user profile was not returned correctly.",
          );

          return;
        }

        final Map<String, dynamic> userData =
            Map<String, dynamic>.from(
          userRaw,
        );

        //////////////////////////////////////////////////////
        /// SESSION TOKEN
        ///
        /// login.php may return the token inside user and/or
        /// in the top-level session object.
        ///
        /// Preserve it in userData so every downstream screen
        /// can access:
        ///
        /// userData['session_token']
        /// userData['user_session_id']
        //////////////////////////////////////////////////////

        final dynamic sessionRaw =
            data['session'];

        if (sessionRaw is Map) {
          final Map<String, dynamic> sessionData =
              Map<String, dynamic>.from(
            sessionRaw,
          );

          final String sessionToken =
              sessionData['session_token']
                      ?.toString() ??
                  "";

          if (sessionToken.isNotEmpty &&
              (userData['session_token']
                          ?.toString() ??
                      "")
                  .isEmpty) {
            userData['session_token'] =
                sessionToken;
          }

          if (sessionData[
                  'user_session_id'] !=
              null) {
            userData[
                    'user_session_id'] =
                sessionData[
                    'user_session_id'];
          }
        }

        //////////////////////////////////////////////////////
        /// ROLE
        //////////////////////////////////////////////////////

        final String role =
            userData['role']
                ?.toString()
                .toLowerCase()
                .trim() ??
            "";

        //////////////////////////////////////////////////////
        /// SUCCESS MESSAGE
        //////////////////////////////////////////////////////

        showMessage(
          "Login successful",
          isError: false,
        );

        //////////////////////////////////////////////////////
        /// ADMIN
        //////////////////////////////////////////////////////

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminDashboard(
                adminData: userData,
              ),
            ),
          );

          return;
        }

        //////////////////////////////////////////////////////
        /// JURY
        //////////////////////////////////////////////////////

        if (role == "jury") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  JuryDashboard(
                juryData: userData,
              ),
            ),
          );

          return;
        }

        //////////////////////////////////////////////////////
        /// CONTESTANT
        //////////////////////////////////////////////////////

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ContestantDashboard(
              userData: userData,
            ),
          ),
        );

        return;
      }

      ////////////////////////////////////////////////////////
      /// API REJECTED LOGIN
      ////////////////////////////////////////////////////////

      showMessage(
        data['message']?.toString() ??
            "Invalid login credentials.",
      );
    }

    //////////////////////////////////////////////////////////
    /// TIMEOUT
    //////////////////////////////////////////////////////////

    on TimeoutException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      debugPrint(
        "LOGIN TIMEOUT: $e",
      );

      showMessage(
        "The server took too long to respond. Please try again.",
      );
    }

    //////////////////////////////////////////////////////////
    /// FORMAT / CLIENT / CORS / NETWORK / SERVER ERROR
    //////////////////////////////////////////////////////////

    catch (e, stackTrace) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      debugPrint(
        "LOGIN ERROR: $e",
      );

      debugPrint(
        "LOGIN STACK TRACE: $stackTrace",
      );

      ////////////////////////////////////////////////////////
      /// DEVELOPMENT-FRIENDLY MESSAGE
      ///
      /// This is intentionally more descriptive than the old
      /// "No internet connection" message because Flutter Web
      /// errors can be CORS, HTTP, JSON, TLS, DNS or timeout.
      ////////////////////////////////////////////////////////

      if (kIsWeb) {
        showMessage(
          "Unable to communicate with the login API. "
          "Please check browser console/CORS. Error: $e",
        );
      } else {
        showMessage(
          "Unable to connect to the login server. Please try again.",
        );
      }
    }
  }

  ////////////////////////////////////////////////////////////
  /// PREMIUM MESSAGE
  ////////////////////////////////////////////////////////////

  void showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) {
      return;
    }

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

        elevation:
            0,

        margin:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),

        duration:
            const Duration(
          seconds: 4,
        ),

        content:
            Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),

          decoration:
              BoxDecoration(
            gradient:
                LinearGradient(
              colors: isError
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
              24,
            ),

            border:
                Border.all(
              color:
                  Colors.white
                      .withOpacity(
                0.15,
              ),

              width:
                  1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: isError
                    ? Colors.red
                        .withOpacity(
                        0.35,
                      )
                    : Colors.green
                        .withOpacity(
                        0.35,
                      ),

                blurRadius:
                    24,

                spreadRadius:
                    1,

                offset:
                    const Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),

          child:
              Row(
            children: [
              //////////////////////////////////////////////////
              /// ICON
              //////////////////////////////////////////////////

              Container(
                height:
                    52,

                width:
                    52,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withOpacity(
                    0.15,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    Icon(
                  isError
                      ? Icons
                          .warning_amber_rounded
                      : Icons
                          .check_circle,

                  color:
                      Colors.white,

                  size:
                      30,
                ),
              ),

              const SizedBox(
                width:
                    16,
              ),

              //////////////////////////////////////////////////
              /// MESSAGE
              //////////////////////////////////////////////////

              Expanded(
                child:
                    Text(
                  message,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        15,

                    fontWeight:
                        FontWeight.w700,

                    height:
                        1.5,

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
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFF070B14,
      ),

      body:
          SafeArea(
        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  760,
            ),

            child:
                SingleChildScrollView(
              child:
                  Column(
                children: [
                  //////////////////////////////////////////////////
                  /// TOP SECTION
                  //////////////////////////////////////////////////

                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          30,
                      vertical:
                          50,
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
                          45,
                        ),

                        bottomRight:
                            Radius.circular(
                          45,
                        ),
                      ),
                    ),

                    child:
                        Column(
                      children: [
                        //////////////////////////////////////////////
                        /// LOGO
                        //////////////////////////////////////////////

                        Container(
                          height:
                              110,

                          width:
                              110,

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.black,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              30,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black
                                        .withOpacity(
                                  0.25,
                                ),

                                blurRadius:
                                    25,

                                offset:
                                    const Offset(
                                  0,
                                  15,
                                ),
                              ),
                            ],
                          ),

                          child:
                              Center(
                            child:
                                Image.asset(
                              "assets/icon/icon.png",

                              width:
                                  75,

                              height:
                                  75,

                              fit:
                                  BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:
                              30,
                        ),

                        const Text(
                          "Welcome Back",

                          style:
                              TextStyle(
                            color:
                                Colors.black,

                            fontSize:
                                34,

                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        const Text(
                          "Login to continue your reality show journey",

                          textAlign:
                              TextAlign.center,

                          style:
                              TextStyle(
                            color:
                                Colors.black87,

                            fontSize:
                                16,

                            height:
                                1.5,
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
                      28,
                    ),

                    child:
                        Column(
                      children: [
                        const SizedBox(
                          height:
                              15,
                        ),

                        //////////////////////////////////////////////////
                        /// EMAIL / PHONE FIELD
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
                          height:
                              24,
                        ),

                        //////////////////////////////////////////////////
                        /// PASSWORD
                        //////////////////////////////////////////////////

                        buildPasswordField(),

                        const SizedBox(
                          height:
                              8,
                        ),

                        Align(
                          alignment:
                              Alignment.centerRight,

                          child:
                              TextButton.icon(
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },

                            icon:
                                const Icon(
                              Icons.lock_reset_rounded,

                              color:
                                  Color(
                                0xFFFFC107,
                              ),
                            ),

                            label:
                                const Text(
                              "Forgot Password?",

                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFFFFC107,
                                ),

                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:
                              22,
                        ),

                        //////////////////////////////////////////////////
                        /// LOGIN BUTTON
                        //////////////////////////////////////////////////

                        SizedBox(
                          width:
                              double.infinity,

                          height:
                              60,

                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFFFFC107,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                            ),

                            onPressed:
                                isLoading
                                    ? null
                                    : loginUser,

                            child:
                                isLoading
                                    ? const SizedBox(
                                        width: 26,
                                        height: 26,
                                        child:
                                            CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        "LOGIN",

                                        style:
                                            TextStyle(
                                          color:
                                              Colors.black,

                                          fontSize:
                                              18,

                                          fontWeight:
                                              FontWeight.w900,
                                        ),
                                      ),
                          ),
                        ),

                        const SizedBox(
                          height:
                              35,
                        ),

                        //////////////////////////////////////////////////
                        /// REGISTER LINK
                        //////////////////////////////////////////////////

                        Wrap(
                          alignment:
                              WrapAlignment.center,

                          crossAxisAlignment:
                              WrapCrossAlignment.center,

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
                                  isLoading
                                      ? null
                                      : () {
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
                                    0xFFFFC107,
                                  ),

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    required TextEditingController controller,
    required TextInputType keyboardType,
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
          height:
              12,
        ),

        TextField(
          controller:
              controller,

          keyboardType:
              keyboardType,

          textInputAction:
              TextInputAction.next,

          autofillHints:
              const [
            AutofillHints.username,
            AutofillHints.email,
            AutofillHints.telephoneNumber,
          ],

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
                0xFFFFC107,
              ),
            ),

            filled:
                true,

            fillColor:
                const Color(
              0xFF161B22,
            ),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),

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
          height:
              12,
        ),

        TextField(
          controller:
              passwordController,

          obscureText:
              obscurePassword,

          textInputAction:
              TextInputAction.done,

          autofillHints:
              const [
            AutofillHints.password,
          ],

          onSubmitted:
              (_) {
            if (!isLoading) {
              loginUser();
            }
          },

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
                0xFFFFC107,
              ),
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
              0xFF161B22,
            ),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              borderSide:
                  BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
