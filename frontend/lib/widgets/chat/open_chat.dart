import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../providers/UserProvider.dart';
import '../../services/stream_chat_service.dart';
import '../../config/agora_config.dart';
import 'video_call_widget.dart';

class OpenChatScreen extends StatefulWidget {
  final StreamChatClient client;
  final String otherUserId;
  final StreamChatService? streamService;
  const OpenChatScreen({
    super.key,
    required this.client,
    required this.otherUserId,
    this.streamService,
  });

  @override
  State<OpenChatScreen> createState() => _OpenChatScreenState();
}

class _OpenChatScreenState extends State<OpenChatScreen> {
  Channel? _channel;
  bool _isVideoCallActive = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final userId = context.read<UserProvider>().userId;

      // Ensure the other user exists in Stream Chat before creating channel
      if (widget.streamService != null) {
        final userExists = await widget.streamService!.ensureUserExists(
          widget.otherUserId,
        );
        if (!userExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to start chat. User not found.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final channel = widget.client.channel(
        'messaging',
        id: 'chat_${userId}_${widget.otherUserId}',
        extraData: {
          'members': [userId, widget.otherUserId],
        },
      );
      await channel.watch();
      if (mounted) setState(() => _channel = channel);
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_channel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show video call widget when call is active
    if (_isVideoCallActive) {
      return VideoCallWidget(
        channelName:
            '${AgoraConfig.channelPrefix}${context.read<UserProvider>().userId}_${widget.otherUserId}',
        appId: AgoraConfig.appId,
        token: AgoraConfig.token,
        onCallEnd: _endVideoCall,
      );
    }

    return StreamChat(
      client: widget.client,
      child: StreamChannel(
        channel: _channel!,
        child: RestorationScope(
          restorationId: 'open_chat',
          child: Scaffold(
            appBar: StreamChannelHeader(
              actions: [
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
        ),
      ),
    );
  }
}
