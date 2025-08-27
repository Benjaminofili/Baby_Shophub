// File: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual Spring Boot server URL
  static const String baseUrl = 'http://10.0.2.2:8080'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8080'; // For iOS simulator

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // Store credentials in memory for now (for testing)
  static String? _storedCredentials;

  // Register user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? address,
    String? phoneNumber,
  }) async {
    try {
      print('Attempting to register user: $email'); // Debug log

      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
        if (address?.isNotEmpty == true) 'address': address,
        if (phoneNumber?.isNotEmpty == true) 'phoneNumber': phoneNumber,
      };

      print('Request body: ${jsonEncode(requestBody)}'); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 201) {
        return {'success': true, 'message': response.body};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Registration failed',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Registration failed: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Registration error: $e'); // Debug log
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Login user (using Basic Auth)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to login user: $email'); // Debug log

      // Create Basic Auth credentials
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$email:$password'))}';

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {...headers, 'Authorization': basicAuth},
      );

      print('Login response status: ${response.statusCode}'); // Debug log
      print('Login response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        // Store credentials in memory
        _storedCredentials = basicAuth;

        return {'success': true, 'user': userData, 'credentials': basicAuth};
      } else {
        return {'success': false, 'message': 'Invalid email or password'};
      }
    } catch (e) {
      print('Login error: $e'); // Debug log
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      if (_storedCredentials == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {...headers, 'Authorization': _storedCredentials!},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return {'success': true, 'user': userData};
      } else {
        return {'success': false, 'message': 'Failed to get user data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? address,
    String? phoneNumber,
  }) async {
    try {
      if (_storedCredentials == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {...headers, 'Authorization': _storedCredentials!},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (address != null) 'address': address,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return {'success': true, 'user': userData};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Update failed',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Update failed: ${response.body}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    _storedCredentials = null;
  }

  // Check if logged in
  static bool isLoggedIn() {
    return _storedCredentials != null;
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: headers,
      );
      print('Test connection response: ${response.statusCode}');
      return true;
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }
}
