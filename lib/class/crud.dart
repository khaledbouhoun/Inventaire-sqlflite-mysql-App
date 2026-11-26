import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Crud {
  // TODO: replace with the real key (same value as X-API-KEY in the Laravel .env)
  static const String _apiKey = 'PASTE_THE_SAME_KEY_YOU_PUT_IN_LARAVEL_ENV_HERE';

  Future<Response> post(String linkurl, Map<String, dynamic> data) async {
    if (await checkInternet()) {
      try {
        var response = await http.post(
          Uri.parse(linkurl),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-API-KEY': _apiKey},
          body: jsonEncode(data),
        );
        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        print("Request URL: $linkurl");
        if (response.statusCode == 401) {
          debugPrint('❌ API Key rejected or unauthorized. Check X-API-KEY header.');
        }

        return Response(statusCode: response.statusCode, body: jsonDecode(response.body));
      } catch (e) {
        print("Error in POST request: $e");
        throw Exception('Server exception: $e');
      }
    } else {
      print("No internet connection");
      throw Exception('No internet connection');
    }
  }

  Future<Response> get(String linkurl) async {
    if (await checkInternet()) {
      try {
        var response = await http.get(Uri.parse(linkurl), headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-API-KEY': _apiKey});
        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        print("Request URL: $linkurl");
        if (response.statusCode == 401) {
          debugPrint('❌ API Key rejected or unauthorized. Check X-API-KEY header.');
        }

        return Response(statusCode: response.statusCode, body: jsonDecode(response.body));
      } catch (e) {
        print("Error in GET request: $e");
        throw Exception('Server exception: $e');
      }
    } else {
      print("No internet connection");
      throw Exception('No internet connection');
    }
  }

  Future<bool> checkInternet() async {
    try {
      var result = await InternetAddress.lookup("google.com");
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      print("Error in checkInternet: ");
      return false;
    }
    return false;
  }
}
