import 'package:flutter/foundation.dart';

import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../services/ai_service.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService;

  AIProvider({AIService? aiService}) : _aiService = aiService ?? AIService();

  final int userId = 1;

  List<ChatSession> _sessions = [];
  List<ChatMessage> _messages = [];

  int? _currentSessionId;

  bool _isLoading = false;
  bool _isSending = false;

  String? _error;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get messages => _messages;

  int? get currentSessionId => _currentSessionId;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  String? get error => _error;

  // Load previous chat sessions
  Future<void> loadChatSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _aiService.getChatSessions(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new chat session
  Future<void> createNewChat() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final session = await _aiService.createChatSession(userId);

      _sessions.insert(0, session);
      _currentSessionId = session.id;
      _messages = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Open an existing chat session
  Future<void> openChatSession(int sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSessionId = sessionId;

      _messages = await _aiService.getChatMessages(userId, sessionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage(String content) async {
    final sessionId = _currentSessionId;

    if (sessionId == null || content.trim().isEmpty) {
      return;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _aiService.sendMessage(
        userId,
        sessionId,
        content.trim(),
       );

      await loadChatMessages(sessionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
      
  }

  // Reload messages after sending
  Future<void> loadChatMessages(int sessionId) async {
    try {
      _messages = await _aiService.getChatMessages(userId, sessionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete a chat session
  Future<void> deleteChat(int sessionId) async {
    try {
      await _aiService.deleteChatSession(userId, sessionId);

      _sessions.removeWhere((session) => session.id == sessionId);

      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages = [];
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}
