import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'edit_profile.dart';
import 'change_picture.dart';
import 'notification.dart';
import 'login.dart';
class ProfileScreen extends StatefulWidget {

  final Map userData;

  const ProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  bool isLoading = true;

  Map profile = {};

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////

  final String profileApi =
      "https://new-disciples.com/api/get_profile.php";

  ////////////////////////////////////////////////////////////
  /// GET PROFILE
  ////////////////////////////////////////////////////////////

  Future<void> getProfile() async {

    try {

      final response = await http.post(
        Uri.parse(profileApi),

        body: {
          "contestant_id":
          widget.userData['id']
              .toString(),
        },
      );

      final data =
      jsonDecode(response.body);

      if (data['status'] == true) {

        setState(() {

          profile = data['user'];

          isLoading = false;
        });
      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    getProfile();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF070B14),

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xFFFFC107),
        ),
      )

          : SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(
              24),

          child: Column(
            children: [

              //////////////////////////////////////////////////
              /// PROFILE IMAGE
              //////////////////////////////////////////////////

              Stack(
                children: [

                  CircleAvatar(
                    radius: 65,

                    backgroundColor:
                    const Color(
                        0xFFFFC107),

                    backgroundImage:
                    profile[
                    'picture'] !=
                        null

                        ? NetworkImage(
                      profile[
                      'picture'],
                    )

                        : null,

                    child: profile[
                    'picture'] ==
                        null

                        ? const Icon(
                      Icons.person,

                      size: 70,

                      color:
                      Colors.black,
                    )

                        : null,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,

                    child: GestureDetector(
                      onTap: () {

                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                                ChangePictureScreen(
                                  contestantId:
                                  profile[
                                  'id']
                                      .toString(),
                                ),
                          ),
                        );
                      },

                      child: Container(
                        padding:
                        const EdgeInsets
                            .all(10),

                        decoration:
                        const BoxDecoration(
                          color: Color(
                              0xFFFFC107),

                          shape:
                          BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.camera_alt,

                          color:
                          Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              //////////////////////////////////////////////////
              /// NAME
              //////////////////////////////////////////////////

              Text(
                profile['full_name']
                    ?.toString() ??
                    "",

                style:
                const TextStyle(
                  color: Colors.white,

                  fontSize: 30,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                profile['phone']
                    ?.toString() ??
                    "",

                style:
                const TextStyle(
                  color:
                  Colors.white54,
                ),
              ),

              const SizedBox(height: 40),

              buildMenu(
                icon:
                Icons.edit_outlined,

                title:
                "Edit Profile",

                onTap: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(
                            userData:
                            profile,
                          ),
                    ),
                  );
                },
              ),

              buildMenu(
                icon: Icons.image,

                title:
                "Change Picture",

                onTap: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          ChangePictureScreen(
                            contestantId:
                            profile['id']
                                .toString(),
                          ),
                    ),
                  );
                },
              ),

              buildMenu(
                icon:
                Icons.notifications,

                title:
                "Notifications",

                onTap: () {

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationScreen(
                            contestantId:
                            profile['id']
                                .toString(),
                          ),
                    ),
                  );
                },
              ),

              buildMenu(
                icon: Icons.logout,

                title: "Logout",

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// MENU
  ////////////////////////////////////////////////////////////

  Widget buildMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin:
        const EdgeInsets.only(
            bottom: 18),

        padding:
        const EdgeInsets.all(22),

        decoration: BoxDecoration(
          color:
          const Color(0xFF161B22),

          borderRadius:
          BorderRadius.circular(
              24),
        ),

        child: Row(
          children: [

            Container(
              padding:
              const EdgeInsets.all(
                  12),

              decoration:
              BoxDecoration(
                color: const Color(
                    0xFFFFC107)
                    .withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(
                    16),
              ),

              child: Icon(
                icon,
                color:
                const Color(
                    0xFFFFC107),
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Text(
                title,

                style:
                const TextStyle(
                  color: Colors.white,

                  fontSize: 16,

                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,

              color:
              Colors.white38,

              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}