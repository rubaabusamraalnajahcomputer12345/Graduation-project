// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/utils/auth_utils.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/colors.dart';

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/providers/UserProvider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ImmersiveAIChat());
  }
}

class ChatMessage {
  final String type;
  final String content;

  ChatMessage({required this.type, required this.content});
}

class ParsedAIMessage {
  final String cleanMessage;
  final List<String> suggestions;

  ParsedAIMessage({required this.cleanMessage, required this.suggestions});
}

ParsedAIMessage extractSuggestions(String aiMessage) {
  final suggestions = <String>[];

  // Normalize different suggestion markers
  final suggestionsPattern = RegExp(
    r'\*{0,2}Suggestions:\*{0,2}',
    caseSensitive: false,
  );
  final match = suggestionsPattern.firstMatch(aiMessage);

  if (match == null) {
    return ParsedAIMessage(cleanMessage: aiMessage.trim(), suggestions: []);
  }

  final suggestionsStart = match.start;

  final messageWithoutSuggestions =
      aiMessage.substring(0, suggestionsStart).trim();
  final suggestionsText = aiMessage.substring(match.end).trim();

  final lines = suggestionsText.split('\n');

  for (var line in lines) {
    final trimmed = line.trim().replaceFirst(RegExp(r'^[-•*]\s*'), '');
    if (trimmed.isNotEmpty) {
      suggestions.add(trimmed);
    }
  }

  return ParsedAIMessage(
    cleanMessage: messageWithoutSuggestions,
    suggestions: suggestions,
  );
}

class ImmersiveAIChat extends StatefulWidget {
  final VoidCallback? onClose;

  const ImmersiveAIChat({super.key, this.onClose});

  @override
  State<ImmersiveAIChat> createState() => _ImmersiveAIChatState();
}

class _ImmersiveAIChatState extends State<ImmersiveAIChat>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isResponding = false;
  bool _isTyping = false;
  String _typingText = "";
  bool _isDarkMode = false;
  bool _isMuted = true;
  bool _showSettings = false;

  // Animation properties
  late AnimationController _waveController;
  late AnimationController _pulseController;
  double _waveAmplitude = 0.3;
  double _waveFrequency = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    //here to stop chat when not needed
    _initializeChatSession();
    _inputController.addListener(() {
      setState(() {}); // Rebuilds the widget when the input changes
    });
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatSession() async {
    print("=== INITIALIZE CHAT SESSION DEBUG ===");
    print("initializing chat session");
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!mounted) {
      print("chat not mounted so I returned");
      print("=== END INITIALIZE CHAT SESSION DEBUG ===");
      return;
    }
    try {
      final token = await AuthUtils.getValidToken(context);
      if (!mounted) return;

      final response = await http.post(
        Uri.parse(startChat),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userProvider.userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("=== FRONTEND CHAT START DEBUG ===");
        print("Response data: $data");
        print("Session ID: ${data['sessionId']}");
        print("AI Session ID: ${data['ai_session_id']}");
        print("Is New Session: ${data['isNewSession']}");
        print("Greeting: ${data['greeting']}");

        userProvider.setAiSessionId(data['ai_session_id']);
        // If this is a new session, set the permanent ai_session_id
        if (data['ai_session_id'] != null) {
          userProvider.setAiSessionId(data['ai_session_id']);
          print("Set AI Session ID: ${data['ai_session_id']}");
        }

        _scrollToBottom();

        // Only show greeting for new sessions
        if (data['greeting'] != null) {
          print("Showing greeting for new session");
          final dynamic greetingData = data['greeting'];
          String greetingText;
          if (greetingData is List) {
            greetingText = "No response";
          } else {
            greetingText =
                greetingData?.toString() ??
                'Welcome! How can I assist you with Islam today?';
          }
          await _typeAIResponse(greetingText);
          _scrollToBottom();
        } else {
          print("No greeting - resuming existing session");
        }

        print("=== END FRONTEND CHAT START DEBUG ===");
      } else {
        // handle failure, display error from response if available
        final errorMsg = data['error'] ?? 'Failed to start session';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("error start chat: $errorMsg")));
        _scrollToBottom();
        await _typeAIResponse("Chat is sleeping now zzz");
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    print("Chat initialization completed");
    print("=== END INITIALIZE CHAT SESSION DEBUG ===");
  }

  Future<void> _sendMessage([String? message]) async {
    print("=== FRONTEND SEND MESSAGE DEBUG ===");
    print("sending message $message");
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final aiSessionId = userProvider.aiSessionId;

    print("UserProvider aiSessionId: $aiSessionId");
    print("UserProvider userId: ${userProvider.userId}");

    if ((message == null && _inputController.text.trim().isEmpty)) {
      print("returned from send - sessionId: $aiSessionId");
      print("=== END FRONTEND SEND MESSAGE DEBUG ===");
      return;
    }
    final content = message ?? _inputController.text.trim();
    final userMessage = ChatMessage(type: 'user', content: content);

    if (!mounted) {
      print("HomePage not mounted can't send message");
      return;
    }
    setState(() {
      userProvider.addMessage(userMessage);
      _isResponding = true;
      _waveAmplitude = 0.8;
      _waveFrequency = 2.0;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final token = await AuthUtils.getValidToken(context);
      if (!mounted) return;

      final response = await http.post(
        Uri.parse(sendChat),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userProvider.userId,
          "ai_session_id": aiSessionId,
          "message": content,
        }),
      );
      if (!mounted) return;

      final data = jsonDecode(response.body);
      print("ai response from sending: $data");
      if (response.statusCode == 200 && data["reply"] != null) {
        print("ai response from sending: $data");
        _scrollToBottom();
        await _typeAIResponse(data["reply"]);
        _scrollToBottom();
      } else {
        print("error sending message: $data");
        // Handle error or missing reply
        await _typeAIResponse(
          "I'm sorry, I couldn't process your question at the moment. Please try again, or ask another question about Islam and I'll do my best to help you.",
        );
      }
      print("answer is : $data");
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to send message: $e');
      print('Failed to send message: $e');
      await _typeAIResponse(
        "I'm sorry, I couldn't process your question at the moment. Please try again, or ask another question about Islam and I'll do my best to help you.",
      );
      _scrollToBottom();
    } finally {
      if (!mounted) return;
      setState(() {
        _isResponding = false;
        _waveAmplitude = 0.3;
        _waveFrequency = 1.0;
      });
      print("=== END FRONTEND SEND MESSAGE DEBUG ===");
    }
  }

  Future<void> _typeAIResponse(String response) async {
    if (!mounted) return;

    // Parse the message and suggestions
    final parsed = extractSuggestions(response);
    final cleanResponse = parsed.cleanMessage;
    final suggestions = parsed.suggestions;

    setState(() {
      _isTyping = true;
      _typingText = "";
      _waveAmplitude = 0.6;
      _waveFrequency = 1.5;
    });

    for (int i = 0; i <= cleanResponse.length; i++) {
      if (mounted) {
        setState(() {
          _typingText = cleanResponse.substring(0, i);
        });
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 3));
      } else {
        return;
      }
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (mounted) {
      setState(() {
        // Add the AI message (without suggestions)
        userProvider.addMessage(
          ChatMessage(type: 'ai', content: cleanResponse),
        );

        // Add each suggestion as a button (custom message type)
        for (var suggestion in suggestions) {
          userProvider.addMessage(
            ChatMessage(type: 'suggestion', content: suggestion),
          );
        }

        _isTyping = false;
        _typingText = "";
        _waveAmplitude = 0.3;
        _waveFrequency = 1.0;
      });

      _scrollToBottom();
    }
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

  Widget _buildAnimatedWaveform() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxHeight = MediaQuery.of(context).size.height * 0.15;
        if (maxHeight < 64) maxHeight = 64;
        if (maxHeight > 128) maxHeight = 128;
        return Container(
          width: double.infinity,
          height: maxHeight,
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: WaveformPainter(
                  progress: _waveController.value,
                  amplitude: _waveAmplitude,
                  frequency: _waveFrequency,
                  isDarkMode: _isDarkMode,
                  isResponding: _isResponding,
                ),
                size: Size(constraints.maxWidth, maxHeight),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.type == 'user';
    if (message.type == 'suggestion') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isDarkMode
                      ? AppColors.islamicGreen700.withOpacity(0.9)
                      : AppColors.homeGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              _sendMessage(message.content);
            },
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width < 600
                        ? MediaQuery.of(context).size.width * 0.9
                        : MediaQuery.of(context).size.width * 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? (_isDarkMode
                            ? AppColors.islamicGreen600.withOpacity(0.8)
                            : AppColors.homeGreenDark.withOpacity(0.9))
                        : (_isDarkMode
                            ? Colors.grey.shade800.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8)),
                borderRadius: BorderRadius.circular(24).copyWith(
                  bottomRight: isUser ? const Radius.circular(8) : null,
                  bottomLeft: !isUser ? const Radius.circular(8) : null,
                ),
                border:
                    !isUser
                        ? Border.all(
                          color:
                              _isDarkMode
                                  ? AppColors.islamicGreen600.withOpacity(0.3)
                                  : AppColors.homeGreenDark.withOpacity(0.2),
                          width: 1,
                        )
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: null,
                    style: TextStyle(
                      color:
                          isUser
                              ? Colors.white
                              : (_isDarkMode
                                  ? AppColors.grey100
                                  : AppColors.homeGreenDarker),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width < 600
                        ? MediaQuery.of(context).size.width * 0.9
                        : MediaQuery.of(context).size.width * 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    _isDarkMode
                        ? AppColors.grey800.withOpacity(0.8)
                        : AppColors.islamicWhite.withOpacity(0.8),
                borderRadius: BorderRadius.circular(
                  24,
                ).copyWith(bottomLeft: const Radius.circular(8)),
                border: Border.all(
                  color:
                      _isDarkMode
                          ? AppColors.islamicGreen600.withOpacity(0.3)
                          : AppColors.homeGreenDark.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _typingText + ((_typingText.isNotEmpty) ? "|" : ""),
                softWrap: true,
                overflow: TextOverflow.visible,
                maxLines: null,
                style: TextStyle(
                  color:
                      _isDarkMode
                          ? AppColors.grey100
                          : AppColors.homeGreenDarker,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final messages = userProvider.messages;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                _isDarkMode
                    ? [
                      AppColors.homeDarkText,
                      AppColors.homeGreenDarker,
                      AppColors.homeDarkTextSecondary,
                    ]
                    : [
                      AppColors.homeLightGreen,
                      AppColors.homeLightYellow,
                      AppColors.homeLightOrange,
                    ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5.0,
                  horizontal: 16.0,
                ),

                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask About Islam',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                _isDarkMode
                                    ? AppColors.islamicWhite
                                    : AppColors.homeGreenDarker,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _isDarkMode
                                    ? AppColors.islamicGreen800
                                    : AppColors.homeGreenDark.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AI Islamic Guide',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  _isDarkMode
                                      ? AppColors.islamicGreen100
                                      : AppColors.homeGreenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    /*  IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color:
                            _isDarkMode
                                ? Colors.white
                                : const Color(0xFF059669),
                      ),
                    ),
                    
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                        });
                      },
                      icon: Icon(
                        _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color:
                            _isDarkMode
                                ? AppColors.islamicWhite
                                : AppColors.homeGreenDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showSettings = !_showSettings;
                        });
                      },
                      icon: Icon(
                        Icons.settings,
                        color:
                            _isDarkMode
                                ? AppColors.islamicWhite
                                : AppColors.homeGreenDark,
                      ),
                    ), */
                    IconButton(
                      onPressed: () async {
                        final userProvider = Provider.of<UserProvider>(
                          context,
                          listen: false,
                        );
                        userProvider.clearMessages();
                      },
                      icon: Icon(
                        Icons.add_comment,
                        color:
                            _isDarkMode
                                ? AppColors.islamicWhite
                                : AppColors.homeGreenDark,
                      ),
                      tooltip: 'New Chat',
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close,
                          color:
                              _isDarkMode
                                  ? AppColors.islamicWhite
                                  : AppColors.homeGreenDark,
                        ),
                      ),
                  ],
                ),
              ),

              // Main Content
              // Animation and status area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAnimatedWaveform(),
                    const SizedBox(height: 32),
                    if (_isResponding)
                      Text(
                        'AI is responding...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.homeGreenDark,
                        ),
                      )
                    else if (_isTyping)
                      Text(
                        'Typing response...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color:
                              _isDarkMode
                                  ? AppColors.islamicGreen300
                                  : AppColors.homeGreenDark,
                        ),
                      )
                    else if (messages.isEmpty)
                      Column(
                        children: [
                          Text(
                            'Welcome to the immersive Islamic AI experience',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color:
                                  _isDarkMode
                                      ? AppColors.islamicWhite
                                      : AppColors.homeGreenDarker,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask me anything about Islam, and I\'ll guide you with wisdom from the Quran and Sunnah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _isDarkMode
                                      ? AppColors.grey300
                                      : AppColors.homeGreenDark,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Chat Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: (_isDarkMode
                            ? AppColors.grey900
                            : AppColors.islamicWhite)
                        .withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child:
                      messages.isEmpty && !_isTyping
                          ? _buildSuggestions()
                          : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < messages.length) {
                                if (messages[index].type == 'suggestion') {
                                  // Only render the first suggestion in a group
                                  if (index == 0 ||
                                      messages[index - 1].type !=
                                          'suggestion') {
                                    // Find the end of this suggestion group
                                    int end = index;
                                    while (end < messages.length &&
                                        messages[end].type == 'suggestion') {
                                      end++;
                                    }
                                    final group =
                                        messages
                                            .sublist(index, end)
                                            .cast<ChatMessage>();
                                    return buildSuggestionsRow(group);
                                  } else {
                                    // Skip rendering this suggestion, as it's part of a group already rendered
                                    return SizedBox.shrink();
                                  }
                                }
                                // Render normal message
                                return _buildMessageBubble(
                                  messages[index],
                                  index,
                                );
                              } else {
                                return _buildTypingIndicator();
                              }
                            },
                          ),
                ),
              ),
              // Input Area
              if (_isResponding)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: AnimatedRespondingDots(isDarkMode: _isDarkMode),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_isDarkMode
                          ? AppColors.grey900
                          : AppColors.islamicWhite)
                      .withOpacity(0.3),
                  border: Border(
                    top: BorderSide(
                      color:
                          _isDarkMode
                              ? AppColors.islamicGreen600.withOpacity(0.3)
                              : AppColors.homeGreenDark.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: (_isDarkMode
                                  ? AppColors.grey800
                                  : AppColors.islamicWhite)
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                _isDarkMode
                                    ? AppColors.islamicGreen600.withOpacity(0.3)
                                    : AppColors.homeGreenDark.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: 'Ask a question about Islam...',
                            hintStyle: TextStyle(
                              color:
                                  _isDarkMode
                                      ? AppColors.grey400
                                      : AppColors.grey600,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          style: TextStyle(
                            color:
                                _isDarkMode
                                    ? AppColors.islamicWhite
                                    : AppColors.homeGreenDarker,
                            fontSize: 16,
                          ),
                          enabled: !_isResponding,
                          onSubmitted:
                              _inputController.text.trim().isEmpty ||
                                      _isResponding
                                  ? null
                                  : _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            _isDarkMode
                                ? AppColors.islamicGreen600
                                : AppColors.homeGreenDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed:
                            _inputController.text.trim().isEmpty ||
                                    _isResponding
                                ? null
                                : _sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.islamicWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      "How do I perform Wudu?",
      "Tell me about the Five Pillars",
      "When are the prayer times?",
      "What is the significance of Ramadan?",
    ];

    double maxWidth =
        MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width * 0.9
            : MediaQuery.of(context).size.width * 0.5;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                suggestions.map((suggestion) {
                  return OutlinedButton(
                    onPressed: () {
                      _sendMessage(suggestion);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            _isDarkMode
                                ? AppColors.islamicGreen600
                                : AppColors.homeGreenDark.withOpacity(0.3),
                      ),
                      foregroundColor:
                          _isDarkMode
                              ? AppColors.islamicGreen100
                              : AppColors.homeGreenDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(suggestion),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget buildSuggestionsRow(List<ChatMessage> suggestions) {
    double maxWidth =
        MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width * 0.9
            : MediaQuery.of(context).size.width * 0.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Wrap(
          spacing: 8,
          children:
              suggestions.map((message) {
                return OutlinedButton(
                  onPressed: () {
                    _sendMessage(message.content);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          _isDarkMode
                              ? AppColors.islamicGreen600
                              : AppColors.homeGreenDark.withOpacity(0.3),
                    ),
                    foregroundColor:
                        _isDarkMode
                            ? AppColors.islamicGreen100
                            : AppColors.homeGreenDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final double amplitude;
  final double frequency;
  final bool isDarkMode;
  final bool isResponding;

  WaveformPainter({
    required this.progress,
    required this.amplitude,
    required this.frequency,
    required this.isDarkMode,
    required this.isResponding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // GLOW PAINT (drawn first, underneath)
    final glowColor =
        isDarkMode ? AppColors.islamicGreen400 : AppColors.homeGreenDark;
    final glowOpacity = 0.3;
    final glowBlur = 8.0;
    final glowStroke = 10.0;
    final glowPaint =
        Paint()
          ..color = glowColor.withOpacity(glowOpacity)
          ..strokeWidth = glowStroke
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);

    final paint =
        Paint()
          ..color =
              isDarkMode ? AppColors.islamicGreen400 : AppColors.homeGreenDark
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final secondaryPaint =
        Paint()
          ..color = (isDarkMode
                  ? AppColors.islamicGreen300
                  : AppColors.homeLightGreenAccent)
              .withOpacity(0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final tertiaryPaint =
        Paint()
          ..color = (isDarkMode
                  ? AppColors.islamicGreen200
                  : AppColors.homeLightGreenAccent2)
              .withOpacity(0.4)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final path = Path();
    final secondaryPath = Path();
    final tertiaryPath = Path();

    final centerY = size.height / 2;
    final timeOffset = progress * 2 * pi * frequency;

    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = (x / size.width) * 4 * pi * frequency;

      final y =
          centerY +
          sin(normalizedX + timeOffset) * amplitude * 20 +
          sin(normalizedX * 2 + timeOffset * 1.5) * amplitude * 10 +
          sin(normalizedX * 0.5 + timeOffset * 0.8) * amplitude * 15;

      final secondaryY =
          centerY +
          sin(normalizedX + timeOffset + pi / 3) * amplitude * 0.6 * 20 +
          sin(normalizedX * 2 + timeOffset * 1.5 + pi / 3) *
              amplitude *
              0.6 *
              10;

      final tertiaryY =
          centerY +
          sin(normalizedX + timeOffset + pi / 6) * amplitude * 0.3 * 20 +
          sin(normalizedX * 2 + timeOffset * 1.5 + pi / 6) *
              amplitude *
              0.3 *
              10;

      if (x == 0) {
        path.moveTo(x, y);
        secondaryPath.moveTo(x, secondaryY);
        tertiaryPath.moveTo(x, tertiaryY);
      } else {
        path.lineTo(x, y);
        secondaryPath.lineTo(x, secondaryY);
        tertiaryPath.lineTo(x, tertiaryY);
      }
    }

    // Draw the glow path first (underneath main waveform)
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(tertiaryPath, tertiaryPaint);
    canvas.drawPath(secondaryPath, secondaryPaint);
    canvas.drawPath(path, paint);

    // Draw pulsing dots when responding
    if (isResponding) {
      final dotPaint =
          Paint()
            ..color =
                isDarkMode ? AppColors.islamicGreen400 : AppColors.homeGreenDark
            ..style = PaintingStyle.fill;

      final positions = [0.25, 0.5, 0.75];
      for (int i = 0; i < positions.length; i++) {
        final opacity = (sin(progress * 2 * pi + i * pi / 2) + 1) / 2;
        dotPaint.color = (isDarkMode
                ? AppColors.islamicGreen400
                : AppColors.homeGreenDark)
            .withOpacity(opacity * 0.8);
        canvas.drawCircle(
          Offset(size.width * positions[i], centerY),
          4,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animated responding dots indicator
class AnimatedRespondingDots extends StatefulWidget {
  final bool isDarkMode;
  const AnimatedRespondingDots({Key? key, required this.isDarkMode})
    : super(key: key);

  @override
  State<AnimatedRespondingDots> createState() => _AnimatedRespondingDotsState();
}

class _AnimatedRespondingDotsState extends State<AnimatedRespondingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dotOneAnim;
  late Animation<double> _dotTwoAnim;
  late Animation<double> _dotThreeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _dotOneAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _dotTwoAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );
    _dotThreeAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isDarkMode ? AppColors.islamicGreen300 : AppColors.homeGreenDark;
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(opacity: _dotOneAnim.value, child: _buildDot(color)),
              const SizedBox(width: 3),
              Opacity(opacity: _dotTwoAnim.value, child: _buildDot(color)),
              const SizedBox(width: 3),
              Opacity(opacity: _dotThreeAnim.value, child: _buildDot(color)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
