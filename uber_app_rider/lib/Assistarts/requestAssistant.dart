import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(Uri.parse(url));

    try {
      if (response.statusCode == 200) {
        String jSondata = response.body;
        var decodeData = jsonDecode(jSondata);
        return decodeData;
      } else {
        return "Failed";
      }
    } catch (_) {
      return "Failed";
    }
  }
}
