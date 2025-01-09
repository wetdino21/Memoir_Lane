import 'dart:convert';
import 'dart:typed_data';

import 'package:memoir_lane/network.dart';
import 'package:http/http.dart' as http;

String baseURL = ipAdress();

Future<String> createAcc(String email, String pass, String phone, Uint8List picture) async {
  try {
    var result = await http.post(Uri.parse('$baseURL/create_acc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass, 'phone_number': phone, 'picture': picture}));

    if (result.statusCode == 200) {
      print('inserted user');
      return 'success';
    } else {
      print('Failed to insert user');
      return 'failed';
    }
  } catch (e) {
    print('API error: $e');
    return e.toString();
  }
}

Future<String> checkEmail(String email) async {
  try {
    var result = await http.post(Uri.parse('$baseURL/check_existing_email'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}));

    if (result.statusCode == 200) {
      print('Availabe email');
      return 'success';
    } else if (result.statusCode == 400) {
      print('Existing email');
      return 'Email already Exist';
    } else {
      print('failed check email');
      return 'Failed check email';
    }
  } catch (e) {
    print('API error: $e');
    return e.toString();
  }
}

Future<String> checkPhone(String phone) async {
  try {
    var result = await http.post(Uri.parse('$baseURL/check_existing_phone'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone_number': phone}));

    if (result.statusCode == 200) {
      print('Availabe phone number');
      return 'success';
    } else if (result.statusCode == 400) {
      print('Existing phone number');
      return 'Phone number already Exist';
    } else {
      print('failed check phone number');
      return 'failed check phone number';
    }
  } catch (e) {
    print('API error: $e');
    return e.toString();
  }
}

Future<Map<String, dynamic>> compareFaces(String imageBase64) async {
  final url = Uri.parse('$baseURL/compare_faces');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image1': imageBase64}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Return match result
    } else {
      return {
        'match': false,
        'message': 'Failed to compare faces. Status code: ${response.statusCode}',
      };
    }
  } catch (e) {
    print('Error comparing faces: $e');
    return {
      'match': false,
      'message': 'Failed to compare faces. $e',
    };
  }
}

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  try {
    var response = await http.post(
      Uri.parse('$baseURL/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Login successful
      return {
        'status': 'success',
        'id': response.body, // ID returned by the server
      };
    } else if (response.statusCode == 400) {
      // Invalid email or password
      return {
        'status': 'error',
        'message': 'Invalid email or password',
      };
    } else {
      // Other errors
      return {
        'status': 'error',
        'message': 'Failed to login. Please try again later.',
      };
    }
  } catch (e) {
    // API or network error
    return {
      'status': 'error',
      'message': 'API error: $e',
    };
  }
}

// Fetch User Details
Future<Map<String, dynamic>?> fetchUserDetails(int userId) async {
  try {
    final response = await http.post(
      Uri.parse('$baseURL/fetch_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      print('Success fetch user details');
      return json.decode(response.body);
    } else {
      print('Failed to fetch user details');
      return null;
    }
  } catch (e) {
    print('Error fetching user details: $e');
    return null;
  }
}

// Fetch Diaries
Future<List<Map<String, dynamic>>> fetchDiaries(int id) async {
  try {
    final response = await http.post(
      Uri.parse('$baseURL/fetch_diary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': id}),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      print('Failed to fetch diaries');
      return [];
    }
  } catch (e) {
    print('Error fetching diaries: $e');
    return [];
  }
}

// Delete Diary
Future<bool> deleteDiary(int id) async {
  try {
    final response = await http.delete(Uri.parse('$baseURL/delete_diary/$id'));

    if (response.statusCode != 200) {
      print('Failed to delete diary');
      return false;
    }
    return true;
  } catch (e) {
    print('Error deleting diary: $e');
    return false;
  }
}

// Save or Update Diary
Future<bool> saveOrUpdateDiary(Map<String, dynamic> diaryData, [int? id]) async {
  try {
    if (id == null) {
      var response = await http.post(
        Uri.parse('$baseURL/create_diary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(diaryData),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to fetch diaries');
        return false;
      }
    } else {
      var response = await http.put(
        Uri.parse('$baseURL/update_diary/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(diaryData),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to fetch diaries');
        return false;
      }
    }
  } catch (e) {
    print('Error saving or updating diary: $e');
    return false;
  }
}
