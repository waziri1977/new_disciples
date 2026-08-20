import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/login.dart';
import 'src/registration.dart';
import 'services/app_update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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
      title: 'New Disciples',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF070B14),
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC107),
          brightness: Brightness.dark,
        ),
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

  bool _startupRunning = false;

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
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 15.0,
      end: 35.0,
    ).animate(_glowController);

    _logoController.forward();
    _textController.forward();

    //////////////////////////////////////////////////////////
    /// START APPLICATION
    //////////////////////////////////////////////////////////

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startApplication();
    });
  }

  ////////////////////////////////////////////////////////////
  /// CHECK UPDATE AND CONTINUE
  ////////////////////////////////////////////////////////////

  Future<void> _startApplication() async {
    if (_startupRunning) return;

    _startupRunning = true;

    try {
      ////////////////////////////////////////////////////////
      /// CHECK GOOGLE PLAY UPDATE
      ////////////////////////////////////////////////////////

      if (mounted && !kIsWeb) {
        await AppUpdateService.checkForUpdate(context);
      }

      ////////////////////////////////////////////////////////
      /// KEEP SPLASH VISIBLE
      ////////////////////////////////////////////////////////

      await Future.delayed(
        const Duration(seconds: 4),
      );

      if (!mounted) return;

      ////////////////////////////////////////////////////////
      /// OPEN WELCOME SCREEN
      ////////////////////////////////////////////////////////

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (
              context,
              animation,
              secondaryAnimation,
              ) {
            return const WelcomeScreen();
          },
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      debugPrint(
        'Application startup error: $e',
      );

      ////////////////////////////////////////////////////////
      /// NEVER BLOCK APP BECAUSE UPDATE CHECK FAILED
      ////////////////////////////////////////////////////////

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    }
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
            height: double.infinity,
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
                /// TOP BACKGROUND CIRCLE
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

                ////////////////////////////////////////////////////////
                /// BOTTOM BACKGROUND CIRCLE
                ////////////////////////////////////////////////////////

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
                /// SPLASH CONTENT
                ////////////////////////////////////////////////////////

                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //////////////////////////////////////////////////
                        /// LOGO
                        //////////////////////////////////////////////////

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
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Image.asset(
                                'assets/icon/icon.png',
                                fit: BoxFit.contain,
                                errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                    ) {
                                  return const Center(
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 70,
                                      color: Color(0xFFFFC107),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 45),

                        //////////////////////////////////////////////////
                        /// APP NAME
                        //////////////////////////////////////////////////

                        FadeTransition(
                          opacity: _textOpacity,
                          child: const Column(
                            children: [
                              Text(
                                'NEW DISCIPLES',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),

                              SizedBox(height: 18),

                              Text(
                                'Show your talent.\nInspire the world.',
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
                ),

                ////////////////////////////////////////////////////////
                /// LOADING INDICATOR
                ////////////////////////////////////////////////////////

                const Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
          /// TOP BACKGROUND GLOW
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

          ////////////////////////////////////////////////////////////
          /// BOTTOM BACKGROUND GLOW
          ////////////////////////////////////////////////////////////

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
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
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
                          color:
                          const Color(0xFFFFC107).withOpacity(0.35),
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
                          'assets/icon/icon.png',
                          width: 105,
                          height: 105,
                          fit: BoxFit.contain,
                          errorBuilder: (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return const Icon(
                              Icons.auto_awesome,
                              size: 65,
                              color: Color(0xFFFFC107),
                            );
                          },
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
                      'NEW DISCIPLES',
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

                  //////////////////////////////////////////////////////
                  /// DESCRIPTION
                  //////////////////////////////////////////////////////

                  const Text(
                    'A live reality competition platform\n'
                        'where talents rise and champions emerge.',
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
                    title: 'LOGIN',
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
                    title: 'CREATE ACCOUNT',
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
          backgroundColor: isPrimary
              ? const Color(0xFFFFC107)
              : const Color(0xFF161B22),
          foregroundColor:
          isPrimary ? Colors.black : Colors.white,
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
            color:
            isPrimary ? Colors.black : Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}