import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../providers/UserProvider.dart';
import '../../services/stream_chat_service.dart';
import '../../config/agora_config.dart';
import 'video_call_widget.dart';

class ChatListScreen extends StatefulWidget {
  final StreamChatClient client;
  final StreamChatService? streamService;
  const ChatListScreen({Key? key, required this.client, this.streamService})
    : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  StreamChannelListController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final connectedUserId = widget.client.state.currentUser?.id;
    if (connectedUserId != null) {
      _controller = StreamChannelListController(
        client: widget.client,
        filter: Filter.in_('members', [connectedUserId]),
        channelStateSort: const [SortOption('last_message_at')],
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fallbackUserId =
          StreamChat.of(context).currentUser?.id ??
          context.read<UserProvider>().userId;
      _controller = StreamChannelListController(
        client: widget.client,
        filter: Filter.in_('members', [fallbackUserId]),
        channelStateSort: const [SortOption('last_message_at')],
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),

      body: RefreshIndicator(
        onRefresh: _controller!.refresh,
        child: StreamChannelListView(
          controller: _controller!,
          onChannelTap: (channel) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => StreamChat(
                      client: widget.client,
                      child: StreamChannel(
                        channel: channel,
                        child: const ChannelPage(),
                      ),
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChannelPage extends StatefulWidget {
  const ChannelPage({Key? key}) : super(key: key);

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  bool _isVideoCallActive = false;

  void _startVideoCall() {
    setState(() {
      _isVideoCallActive = true;
    });
  }

  void _endVideoCall() {
    setState(() {
      _isVideoCallActive = false;
    });
  }

  String _getOtherUserId() {
    final channel = StreamChannel.of(context).channel;
    final currentUserId = StreamChat.of(context).currentUser?.id;
    final members = channel.state?.members ?? [];

    // Find the other user (not the current user)
    for (final member in members) {
      if (member.userId != currentUserId) {
        return member.userId ?? 'unknown';
      }
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    // Show video call widget when call is active
    if (_isVideoCallActive) {
      final currentUserId = StreamChat.of(context).currentUser?.id ?? 'unknown';
      final otherUserId = _getOtherUserId();

      return VideoCallWidget(
        channelName:
            '${AgoraConfig.channelPrefix}${currentUserId}_${otherUserId}',
        appId: AgoraConfig.appId,
        token: AgoraConfig.token,
        onCallEnd: _endVideoCall,
      );
    }

    return RestorationScope(
      restorationId: 'channel_page',
      child: Scaffold(
        appBar: StreamChannelHeader(
          actions: [
            // Only show video call button on mobile platforms
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: _startVideoCall,
                tooltip: 'Start Video Call',
              ),
          ],
        ),
        body: const StreamMessageListView(),
        bottomNavigationBar: SafeArea(
          child: StreamMessageInput(
            // Disable restoration to prevent the assertion error
            restorationId: null,
          ),
        ),
      ),
    );
  }
}
