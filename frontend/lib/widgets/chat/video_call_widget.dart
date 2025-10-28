import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../config/agora_config.dart';

class VideoCallWidget extends StatefulWidget {
  final String channelName;
  final String appId;
  final String token;
  final VoidCallback onCallEnd;

  const VideoCallWidget({
    super.key,
    required this.channelName,
    required this.appId,
    required this.token,
    required this.onCallEnd,
  });

  @override
  State<VideoCallWidget> createState() => _VideoCallWidgetState();
}

class _VideoCallWidgetState extends State<VideoCallWidget> {
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  int? _remoteUid;
  bool _isSpeakerOn = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Video calls are not supported on web platform yet. Please use the mobile app.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onCallEnd();
        }
        return;
      }

      // Request permissions (only on mobile)
      await [Permission.camera, Permission.microphone].request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(appId: AgoraConfig.appId),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            // Channel joined successfully
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            setState(() {
              _remoteUid = null;
            });
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();
      await _engine!.joinChannel(
        token: AgoraConfig.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize video call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onCallEnd();
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(!_isMuted);
      setState(() {
        _isMuted = !_isMuted;
      });
    }
  }

  Future<void> _toggleVideo() async {
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      setState(() {
        _isVideoEnabled = !_isVideoEnabled;
      });
    }
  }

  Future<void> _toggleSpeaker() async {
    if (_engine != null) {
      await _engine!.setDefaultAudioRouteToSpeakerphone(!_isSpeakerOn);
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    }
  }

  Future<void> _endCall() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
    widget.onCallEnd();
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show web not supported message
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.orange, size: 64),
              SizedBox(height: 20),
              Text(
                'Video calls are not supported on web',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Please use the mobile app for video calling',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading screen while initializing
    if (!_isInitialized || _engine == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Initializing video call...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video
            if (_remoteUid != null)
              AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                ),
              )
            else
              Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Text(
                    'Waiting for other user...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

            // Local video (picture-in-picture)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      _isVideoEnabled
                          ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                          : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                ),
              ),
            ),

            // Call controls
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : Colors.white,
                    onPressed: _toggleMute,
                  ),

                  // Video toggle button
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    color: _isVideoEnabled ? Colors.white : Colors.red,
                    onPressed: _toggleVideo,
                  ),

                  // Speaker button
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                    onPressed: _toggleSpeaker,
                  ),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onPressed: _endCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
