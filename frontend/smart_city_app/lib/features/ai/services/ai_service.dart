import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

class AIService {
  final http.Client _client;

  AIService({http.Client? client}) : _client = client ?? http.Client();

  // Get all chat sessions for a user
  Future<List<ChatSession>> getChatSessions(int userId) async {
    final uri = Uri.parse(
      '${AppConfig.aiChatUrl}/sessions',
    ).replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) => ChatSession.fromJson(item)).toList();
    }

    throw Exception('Failed to load chat sessions');
  }

  // Create a new chat session
  Future<ChatSession> createChatSession(int userId, {String? title}) async {
    final uri = Uri.parse(
      '${AppConfig.aiChatUrl}/sessions',
    ).replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChatSession.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to create chat session');
  }

  // Get messages from a selected chat session
  Future<List<ChatMessage>> getChatMessages(int userId, int sessionId) async {
    final uri = Uri.parse(
      '${AppConfig.aiChatUrl}/sessions/$sessionId/messages',
    ).replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final List<dynamic> messages = data['messages'];

      return messages.map((item) => ChatMessage.fromJson(item)).toList();
    }

    throw Exception('Failed to load chat messages');
  }

  // Send a message and receive AI response
  Future<ChatMessage> sendMessage(
    int userId,
    int sessionId,
    String content,
  ) async {
    final uri = Uri.parse(
      '${AppConfig.aiChatUrl}/sessions/$sessionId/messages',
    ).replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      return ChatMessage.fromJson(data['assistant_message']);
    }

    throw Exception('Failed to send message');
  }

  // Delete a chat session
  Future<void> deleteChatSession(int userId, int sessionId) async {
    final uri = Uri.parse(
      '${AppConfig.aiChatUrl}/sessions/$sessionId',
    ).replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete chat session');
    }
  }

  void dispose() {
    _client.close();
  }
}
