import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      "http://YOUR_SERVER/new_disciples/api/";

  ////////////////////////////////////////////////////////////
  /// REGISTER
  ////////////////////////////////////////////////////////////

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse("${baseUrl}register.php"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  ////////////////////////////////////////////////////////////
  /// LOGIN
  ////////////////////////////////////////////////////////////

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse("${baseUrl}login.php"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }
}