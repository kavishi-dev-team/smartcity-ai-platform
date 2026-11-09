import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message_model.dart';
import '../providers/ai_provider.dart';

class AIAssistantChatScreen extends StatefulWidget {
  const AIAssistantChatScreen({super.key});

  @override
  State<AIAssistantChatScreen> createState() =>
      _AIAssistantChatScreenState();
}

class _AIAssistantChatScreenState extends State<AIAssistantChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, dynamic>> _quickPrompts = [
    {
      'label': 'My Active Reports',
      'prompt': 'Show my active citizen reports and their current status',
      'icon': Icons.assignment_turned_in_rounded,
      'color': AppColors.primary,
    },
    {
      'label': 'Live Sri Lanka AQI',
      'prompt': 'What is the live air quality (AQI) across Sri Lanka right now?',
      'icon': Icons.air_rounded,
      'color': AppColors.cyan,
    },
    {
      'label': 'Kandy & Colombo AQI',
      'prompt': 'What is the live AQI and PM2.5 in Colombo and Kandy?',
      'icon': Icons.location_city_rounded,
      'color': AppColors.navy,
    },
    {
      'label': 'Waste Schedule & Bins',
      'prompt': 'What are the municipal waste collection schedules and separation rules?',
      'icon': Icons.recycling_rounded,
      'color': AppColors.success,
    },
    {
      'label': 'Power & Water Leaks',
      'prompt': 'How do I report a water pipe leak or power outage in my area?',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warning,
    },
    {
      'label': 'Safety & Hotlines',
      'prompt': 'Show active public safety alerts and emergency department contacts',
      'icon': Icons.shield_rounded,
      'color': AppColors.error,
    },
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uid = context.read<AuthProvider>().user?.id;
        final ai = context.read<AIProvider>();
        if (uid != null) {
          ai.setUserId(uid);
        }
        ai.loadChatSessions();
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

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _messageController.text).trim();

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

    if (presetText == null) {
      _messageController.clear();
    }

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer<AIProvider>(
          builder: (context, ai, child) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Smart City Chat History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _startNewChat();
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New'),
                          ),
                        ],
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
                                  child: Text(
                                    'No previous Smart City conversations found.',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: ai.sessions.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1, indent: 68),
                                  itemBuilder: (context, index) {
                                    final session = ai.sessions[index];
                                    final isCurrent =
                                        session.id == ai.currentSessionId;

                                    return ListTile(
                                      selected: isCurrent,
                                      selectedTileColor: AppColors.background,
                                      leading: CircleAvatar(
                                        backgroundColor: isCurrent
                                            ? AppColors.primary
                                            : AppColors.lightBlue,
                                        child: Icon(
                                          Icons.smart_toy_rounded,
                                          size: 20,
                                          color: isCurrent
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                      title: Text(
                                        session.title ??
                                            'Smart City Conversation',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      subtitle: Text(
                                        session.createdAt
                                            .toLocal()
                                            .toString()
                                            .split('.')
                                            .first,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () async {
                                          final navigator =
                                              Navigator.of(sheetContext);

                                          await ai.deleteChat(session.id);

                                          if (!mounted) return;

                                          if (ai.sessions.isEmpty &&
                                              navigator.canPop()) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.skyBlue.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.skyBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart City AI Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Strict Smart City Intelligence • Live Data',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.lightBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat History',
            onPressed: _openHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'New Conversation',
            onPressed: _startNewChat,
            icon: const Icon(Icons.add_comment_rounded),
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
              // Guardrail banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: AppColors.navy,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dedicated to Smart City services: Live Sri Lanka AQI, Your Reports, Waste, Energy, Water, Traffic & Safety.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ai.messages.isEmpty
                    ? _buildWelcomeMessage()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: ai.messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(
                            ai.messages[index],
                          );
                        },
                      ),
              ),
              if (ai.messages.isNotEmpty) _buildQuickChipsBar(ai),
              if (ai.isSending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Analyzing live Smart City telemetry...',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy.withValues(alpha: 0.8),
                        ),
                      ),
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

  Widget _buildQuickChipsBar(AIProvider ai) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _quickPrompts[index];
          return ActionChip(
            avatar: Icon(
              item['icon'] as IconData,
              size: 15,
              color: item['color'] as Color,
            ),
            label: Text(
              item['label'] as String,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            onPressed: ai.isSending
                ? null
                : () => _sendMessage(item['prompt'] as String),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Smart City AI Assistant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connected to live Sri Lanka Air Quality (44 cities), your personal citizen reports, waste schedules, utility alerts, and municipal departments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.lightBlue,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ASK ABOUT SMART CITY SERVICES',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickPrompts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              final item = _quickPrompts[index];
              final color = item['color'] as Color;
              return InkWell(
                onTap: () => _sendMessage(item['prompt'] as String),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: color,
                        ),
                      ),
                      Text(
                        item['label'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.smart_toy_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Smart City AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.content.replaceAll('**', ''),
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.text,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${message.createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
              '${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(AIProvider ai) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
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
                hintText: 'Ask about AQI, your reports, waste, water, traffic...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor:
                ai.isSending ? AppColors.muted : AppColors.primary,
            child: IconButton(
              onPressed: ai.isSending ? null : () => _sendMessage(),
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
