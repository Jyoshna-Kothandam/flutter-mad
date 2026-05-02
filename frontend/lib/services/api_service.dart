import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Use localhost for Web, 10.0.2.2 for Android emulator
    static const String baseUrl = 'http://10.174.38.175:8000/api'; // Replace with YOUR actual IPv4 address


  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('username', data['username']);
        return data;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return null;
  }

  Future<bool> register(String username, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('username');
  }

  Future<List<dynamic>> getItems({String? category, String? location}) async {
    String url = '$baseUrl/items/';
    List<String> queryParams = [];
    if (category != null && category.isNotEmpty) queryParams.add('category=$category');
    if (location != null && location.isNotEmpty) queryParams.add('location=$location');
    if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> uploadItem(String name, String category, String description, String location, String reportingStation, String dateFound, XFile image, Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/items/'));
    request.headers['Authorization'] = 'Token $token';
    request.fields['name'] = name;
    request.fields['category'] = category;
    request.fields['description'] = description;
    request.fields['location'] = location;
    request.fields['reporting_station'] = reportingStation;
    request.fields['date_found'] = dateFound;
    request.fields['details'] = jsonEncode(details);
    
    final bytes = await image.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    
    var response = await request.send();
    return response.statusCode == 201;
  }

  Future<bool> updateItemStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/items/$id/update_status/'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/items/$id/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  Future<Map<String, dynamic>?> getPoliceStats() async {
    final response = await http.get(Uri.parse('$baseUrl/stats/'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<dynamic>> getRequests() async {
    final response = await http.get(Uri.parse('$baseUrl/requests/'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> sendRequest(int itemId, String message, XFile proofImage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/requests/'));
      request.headers['Authorization'] = 'Token $token';
      request.fields['item'] = itemId.toString();
      request.fields['message'] = message;

      final bytes = await proofImage.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('proof_image', bytes, filename: proofImage.name));

      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Send Request error: $e');
      return false;
    }
  }

  Future<bool> updateRequestStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/requests/$id/update_status/'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }
}
