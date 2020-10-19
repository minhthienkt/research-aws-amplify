import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' show Client, Response;
import '../models/todo.dart';
import 'provider.dart';

class todoApi{

  Client client = Client();
  final _apiKey = Settings.apiKey;
  final _baseUrl = Settings.baseUrl;

  Future<Todo> fetchTodoList() async {
    Response response;
    if (_apiKey!= '') {
      response = await client.get("$_baseUrl/popular?api_key=$_apiKey");
    } else {
      throw Exception('Please add your API key');
    }
    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      return Todo.fromJson(json.decode(response.body));
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load post');
    }
  }


}