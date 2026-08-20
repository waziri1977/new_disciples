import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ChangePictureScreen extends StatefulWidget {
  final String contestantId;

  const ChangePictureScreen({
    super.key,
    required this.contestantId,
  });

  @override
  State<ChangePictureScreen> createState() => _ChangePictureScreenState();
}

class _ChangePictureScreenState extends State<ChangePictureScreen> {
  final ImagePicker picker = ImagePicker();

  static const String apiUrl =
      "https://new-disciples.com/api/upload_picture.php";

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  bool isLoading = false;
  bool isPicking = false;

  Future<void> pickImage() async {
    if (isPicking || isLoading) return;

    setState(() {
      isPicking = true;
    });

    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception("Selected image is empty.");
      }

      const int maxBytes = 8 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        throw Exception("Picture is too large. Maximum size is 8 MB.");
      }

      if (!mounted) return;

      setState(() {
        selectedImage = picked;
        selectedImageBytes = bytes;
      });

      _showMessage("Picture selected successfully.");
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        "Unable to select picture: $e",
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isPicking = false;
        });
      }
    }
  }

  Future<void> uploadImage() async {
    if (isLoading) return;

    final XFile? image = selectedImage;
    final Uint8List? bytes = selectedImageBytes;

    if (image == null || bytes == null || bytes.isEmpty) {
      _showMessage(
        "Please select a picture first.",
        error: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(apiUrl),
      );

      request.headers["Accept"] = "application/json";
      request.fields["contestant_id"] = widget.contestantId.trim();

      String filename = image.name.trim();
      if (filename.isEmpty) {
        filename =
            "contestant_${widget.contestantId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          "picture",
          bytes,
          filename: filename,
        ),
      );

      debugPrint("PICTURE UPLOAD contestant_id: ${widget.contestantId}");
      debugPrint("PICTURE UPLOAD filename: $filename");
      debugPrint("PICTURE UPLOAD bytes: ${bytes.length}");

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );

      final responseBody =
          await streamedResponse.stream.bytesToString();

      debugPrint("PICTURE UPLOAD HTTP: ${streamedResponse.statusCode}");
      debugPrint("PICTURE UPLOAD RESPONSE: $responseBody");

      Map<String, dynamic> data = {};

      if (responseBody.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(responseBody);
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      }

      if (!mounted) return;

      final bool success =
          streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300 &&
          (data["status"] == true || data["success"] == true);

      if (!success) {
        throw Exception(
          data["message"]?.toString() ??
              "Upload failed. HTTP ${streamedResponse.statusCode}",
        );
      }

      _showMessage(
        data["message"]?.toString() ?? "Picture uploaded successfully.",
      );

      Navigator.pop(context, data);
    } on FormatException {
      if (!mounted) return;
      _showMessage(
        "The server returned invalid JSON. Check upload_picture.php.",
        error: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        "Unable to upload picture: $e",
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              error ? Colors.red : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        selectedImageBytes != null && selectedImageBytes!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Change Picture",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Text(
                    "Profile Picture",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb
                        ? "Select a picture from this computer."
                        : "Select a picture from your gallery.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: isLoading ? null : pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF161B22),
                            border: Border.all(
                              color: const Color(0xFFFFC107),
                              width: 4,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? Image.memory(
                                  selectedImageBytes!,
                                  width: 190,
                                  height: 190,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white24,
                                    size: 90,
                                  ),
                                ),
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFC107),
                          ),
                          child: isPicking
                              ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (selectedImage != null)
                    Text(
                      selectedImage!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed:
                          isLoading || isPicking ? null : pickImage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFFC107),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: Color(0xFFFFC107),
                      ),
                      label: Text(
                        hasImage
                            ? "CHOOSE ANOTHER PICTURE"
                            : "SELECT PICTURE",
                        style: const TextStyle(
                          color: Color(0xFFFFC107),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        disabledBackgroundColor: const Color(0xFF665408),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed:
                          isLoading || isPicking || !hasImage
                              ? null
                              : uploadImage,
                      icon: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.black,
                            ),
                      label: Text(
                        isLoading ? "UPLOADING..." : "UPLOAD PICTURE",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
}
