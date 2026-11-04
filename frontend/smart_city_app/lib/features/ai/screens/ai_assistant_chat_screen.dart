import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message_model.dart';
import '../providers/ai_provider.dart';

class AIAssistantChatScreen extends StatefulWidget {
  const AIAssistantChatScreen({super.key});

  @override
  State<AIAssistantChatScreen> createState() =>
      _AIAssistantChatScreenState();
}

class _AIAssistantChatScreenState
    extends State<AIAssistantChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AIProvider>().loadChatSessions();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    final provider = context.read<AIProvider>();

    if (provider.currentSessionId == null) {
      await provider.createNewChat();
    }

    if (!mounted) return;

    if (provider.currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Unable to create a chat session.',
          ),
        ),
      );
      return;
    }

    _messageController.clear();

    await provider.sendMessage(text);

    if (!mounted) return;

    _scrollToBottom();

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _startNewChat() async {
    await context.read<AIProvider>().createNewChat();

    if (!mounted) return;

    _scrollToBottom();
  }

  Future<void> _openHistory() async {
    final provider = context.read<AIProvider>();

    await provider.loadChatSessions();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer<AIProvider>(
          builder: (context, ai, child) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ai.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : ai.sessions.isEmpty
                              ? const Center(
                                  child: Text('No previous chats found.'),
                                )
                              : ListView.builder(
                                  itemCount: ai.sessions.length,
                                  itemBuilder: (context, index) {
                                    final session = ai.sessions[index];

                                    return ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.chat),
                                      ),
                                      title: Text(
                                        session.title ??
                                            'Smart City Conversation',
                                      ),
                                      subtitle: Text(
                                        session.createdAt
                                            .toLocal()
                                            .toString()
                                            .split('.')
                                            .first,
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final navigator =
                                              Navigator.of(sheetContext);

                                          await ai.deleteChat(session.id);

                                          if (!mounted) return;

                                          if (navigator.canPop()) {
                                            navigator.pop();
                                          }
                                        },
                                      ),
                                      onTap: () async {
                                        await ai.openChatSession(
                                          session.id,
                                        );

                                        if (!mounted) return;

                                        Navigator.of(sheetContext).pop();

                                        _scrollToBottom();
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF126B9E),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart City AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Your Smart City Assistant',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat History',
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'New Chat',
            onPressed: _startNewChat,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<AIProvider>(
        builder: (context, ai, child) {
          if (ai.isLoading && ai.currentSessionId == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ai.messages.isEmpty
                    ? _buildWelcomeMessage()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: ai.messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(
                            ai.messages[index],
                          );
                        },
                      ),
              ),
              if (ai.isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('AI is thinking...'),
                    ],
                  ),
                ),
              _buildMessageInput(ai),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFDCEFFA),
              child: Icon(
                Icons.smart_toy,
                size: 42,
                color: Color(0xFF126B9E),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hello! How can I help you?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ask me about traffic, road damage, waste management, '
              'water supply and other city services.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            _buildSuggestion('How can I report road damage?'),
            _buildSuggestion('How do I report waste problems?'),
            _buildSuggestion('How can I report water issues?'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          _messageController.text = text;
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF126B9E).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF126B9E),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF126B9E)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${message.createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
              '${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(AIProvider ai) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask Smart City AI...',
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF126B9E),
            child: IconButton(
              onPressed: ai.isSending ? null : _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
