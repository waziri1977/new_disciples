import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
class ChangePictureScreen
    extends StatefulWidget {

  final String contestantId;

  const ChangePictureScreen({
    super.key,
    required this.contestantId,
  });

  @override
  State<ChangePictureScreen>
  createState() =>
      _ChangePictureScreenState();
}

class _ChangePictureScreenState
    extends State<ChangePictureScreen> {

  File? image;

  bool isLoading = false;

  final picker = ImagePicker();

  final String apiUrl =
      "https://new-disciples.com/api/upload_picture.php";

  ////////////////////////////////////////////////////////////
  /// PICK IMAGE
  ////////////////////////////////////////////////////////////

  Future<void> pickImage() async {

    final picked =
    await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {

      setState(() {
        image = File(picked.path);
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// UPLOAD IMAGE
  ////////////////////////////////////////////////////////////

  Future<void> uploadImage() async {

    if (image == null) return;

    setState(() {
      isLoading = true;
    });

    var request =
    http.MultipartRequest(
      "POST",
      Uri.parse(apiUrl),
    );

    request.fields['contestant_id'] =
        widget.contestantId;

    request.files.add(
      await http.MultipartFile
          .fromPath(
        "picture",
        image!.path,
      ),
    );

    var response =
    await request.send();

    var res =
    await response.stream.bytesToString();

    var data = jsonDecode(res);

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(data['message']),
      ),
    );
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
        const Text("Change Picture"),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(24),

        child: Column(
          children: [

            GestureDetector(
              onTap: pickImage,

              child: CircleAvatar(
                radius: 80,

                backgroundColor:
                const Color(
                    0xFF161B22),

                backgroundImage:
                image != null
                    ? FileImage(image!)
                    : null,

                child: image == null

                    ? const Icon(
                  Icons.camera_alt,

                  color:
                  Colors.white,

                  size: 40,
                )

                    : null,
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  const Color(
                      0xFFFFC107),
                ),

                onPressed:
                isLoading
                    ? null
                    : uploadImage,

                child: isLoading

                    ? const CircularProgressIndicator(
                  color:
                  Colors.black,
                )

                    : const Text(
                  "UPLOAD PICTURE",

                  style:
                  TextStyle(
                    color:
                    Colors.black,

                    fontWeight:
                    FontWeight
                        .w900,
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