import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginResponse {
  final bool isLoggedInSuccessfully;
  final String? authToken;
  final String? refreshToken;
  final String? errorMessage;

  LoginResponse({
    required this.isLoggedInSuccessfully,
    this.authToken,
    this.refreshToken,
    this.errorMessage,
  });
}

class LoginService {
  Future<LoginResponse> login(String username, String password) async {
    var loginUri = Uri.https('dummyjson.com', 'auth/login');
    var response = await http.post(
      loginUri,
      headers: {'Content-Type': 'application/json', 'credentials': 'include'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return LoginResponse(
        isLoggedInSuccessfully: true,
        authToken: json.decode(response.body)['accessToken'] as String,
        refreshToken: json.decode(response.body)['refreshToken'] as String,
      );
    } else {
      return LoginResponse(
        isLoggedInSuccessfully: false,
        errorMessage: 'Failed to login successfully',
      );
    }
  }
}
