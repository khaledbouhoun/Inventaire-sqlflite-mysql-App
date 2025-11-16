import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Crud {
  Future<Response> post(String linkurl, Map<String, dynamic> data) async {
    if (await checkInternet()) {
      try {
        var response = await http.post(
          Uri.parse(linkurl),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(data),
        );
        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        print("Request URL: $linkurl");

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
        var response = await http.get(Uri.parse(linkurl), headers: {'Content-Type': 'application/json', 'Accept': 'application/json'});
        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        print("Request URL: $linkurl");

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
