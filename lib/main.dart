// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/login.dart';
import 'src/registration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const NewDisciplesApp());
}

////////////////////////////////////////////////////////////
/// ROOT APP
////////////////////////////////////////////////////////////

class NewDisciplesApp extends StatelessWidget {
  const NewDisciplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "New Disciples",
      theme: ThemeData(
        fontFamily: "Poppins",
        scaffoldBackgroundColor: const Color(0xFF070B14),
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(),
    );
  }
}

////////////////////////////////////////////////////////////
/// SPLASH SCREEN
////////////////////////////////////////////////////////////

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    //////////////////////////////////////////////////////////
    /// LOGO ANIMATION
    //////////////////////////////////////////////////////////

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 15,
      end: 35,
    ).animate(_glowController);

    _logoController.forward();
    _textController.forward();

    //////////////////////////////////////////////////////////
    /// NAVIGATION
    //////////////////////////////////////////////////////////

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFC107),
                  Color(0xFFFFB300),
                  Color(0xFFFFD54F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                ////////////////////////////////////////////////////////
                /// BACKGROUND CIRCLES
                ////////////////////////////////////////////////////////

                Positioned(
                  top: -100,
                  right: -50,
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  bottom: -120,
                  left: -50,
                  child: Container(
                    height: 320,
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                ////////////////////////////////////////////////////////
                /// CONTENT
                ////////////////////////////////////////////////////////

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ////////////////////////////////////////////////////
                      /// LOGO
                      ////////////////////////////////////////////////////

                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          height: 165,
                          width: 165,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(45),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: 2,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/icon/icon.png",
                              errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                  ) {
                                return Text(
                                  error.toString(),
                                );
                              },
                            )
                          ),
                        ),
                      ),

                      const SizedBox(height: 45),

                      ////////////////////////////////////////////////////
                      /// TEXT
                      ////////////////////////////////////////////////////

                      FadeTransition(
                        opacity: _textOpacity,
                        child: const Column(
                          children: [
                            Text(
                              "NEW DISCIPLES",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),

                            SizedBox(height: 18),

                            Text(
                              "Show your talent.\nInspire the world.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 17,
                                height: 1.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                ////////////////////////////////////////////////////////
                /// LOADER
                ////////////////////////////////////////////////////////

                const Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    ),
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

////////////////////////////////////////////////////////////
/// WELCOME SCREEN
////////////////////////////////////////////////////////////

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          ////////////////////////////////////////////////////////////
          /// BACKGROUND GLOW
          ////////////////////////////////////////////////////////////

          Positioned(
            top: -120,
            right: -80,
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          ////////////////////////////////////////////////////////////
          /// CONTENT
          ////////////////////////////////////////////////////////////

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(),

                  //////////////////////////////////////////////////////
                  /// LOGO
                  //////////////////////////////////////////////////////

                  Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFC107),
                          Color(0xFFFFB300),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(42),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC107).withOpacity(0.35),
                          blurRadius: 35,
                          spreadRadius: 3,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0F1A),
                        borderRadius: BorderRadius.circular(38),
                      ),
                      child: Center(
                        child: Image.asset(
                          "assets/icon/icon.png",
                          width: 105,
                          height: 105,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  //////////////////////////////////////////////////////
                  /// TITLE
                  //////////////////////////////////////////////////////

                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFFFF3B0),
                          Color(0xFFFFC107),
                        ],
                      ).createShader(bounds);
                    },
                    child: const Text(
                      "NEW DISCIPLES",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "A live reality competition platform\nwhere talents rise and champions emerge.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  //////////////////////////////////////////////////////
                  /// LOGIN BUTTON
                  //////////////////////////////////////////////////////

                  buildPremiumButton(
                    title: "LOGIN",
                    isPrimary: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  //////////////////////////////////////////////////////
                  /// REGISTER BUTTON
                  //////////////////////////////////////////////////////

                  buildPremiumButton(
                    title: "CREATE ACCOUNT",
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistrationScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// PREMIUM BUTTON
  ////////////////////////////////////////////////////////////

  Widget buildPremiumButton({
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isPrimary ? const Color(0xFFFFC107) : const Color(0xFF161B22),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}