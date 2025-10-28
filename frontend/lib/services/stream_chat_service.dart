import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../config.dart';
import '../utils/auth_utils.dart';
import '../providers/UserProvider.dart';
import 'package:provider/provider.dart';

class StreamChatService {
  final StreamChatClient client;

  StreamChatService(String apiKey)
    : client = StreamChatClient(apiKey, logLevel: Level.INFO);

  static Future<StreamChatService?> initialize(BuildContext context) async {
    try {
      final token = await AuthUtils.getValidToken(context);
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(streamTokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final apiKey = data['apiKey'] as String;
      final userId = data['userId'] as String;
      final userName = (data['name'] as String?) ?? userId;
      final userToken = data['token'] as String;

      final service = StreamChatService(apiKey);

      await service.client.connectUser(
        User(id: userId, name: userName),
        userToken,
      );

      return service;
    } catch (_) {
      return null;
    }
  }

  // Ensure a user exists in Stream Chat before creating a channel
  Future<bool> ensureUserExists(String userId) async {
    try {
      final token = await AuthUtils.getValidTokenFromPrefs();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ensureUser),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        print('User $userId ensured in Stream Chat');
        return true;
      } else {
        print('Failed to ensure user $userId: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error ensuring user $userId: $e');
      return false;
    }
  }
}
