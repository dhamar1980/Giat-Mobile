import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

/// Layanan Video Call Jitsi Meet SDK (100% Gratis, In-App Native Call)
class JitsiVideoService {
  static final JitsiVideoService _instance = JitsiVideoService._internal();
  factory JitsiVideoService() => _instance;
  JitsiVideoService._internal();

  final JitsiMeet _jitsiMeet = JitsiMeet();

  /// Minta izin akses kamera dan mikrofon
  Future<bool> requestPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      return (statuses[Permission.camera]?.isGranted ?? false) &&
          (statuses[Permission.microphone]?.isGranted ?? false);
    } catch (e) {
      debugPrint('⚠️ Error requesting permissions: $e');
      return true;
    }
  }

  /// Bergabung ke ruang video call Jitsi
  Future<void> joinRoom({
    required String roomId,
    required String userName,
    String? userEmail,
    String? userAvatar,
    Function()? onTerminated,
    Function(Map<dynamic, dynamic>)? onConferenceJoined,
  }) async {
    try {
      await requestPermissions();
      final options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: roomId,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Konsultasi Telemedisin GIAT",
        },
        featureFlags: {
          "welcomepage.enabled": false,
          "prejoinpage.enabled": false,
          "invite.enabled": false,
          "pip.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userName,
          email: userEmail ?? 'user@giat.id',
          avatar: userAvatar,
        ),
      );

      final listener = JitsiMeetEventListener(
        conferenceTerminated: (url, error) {
          debugPrint('📹 Video call terminated: $url, err: $error');
          if (onTerminated != null) {
            onTerminated();
          }
        },
        conferenceJoined: (url) {
          debugPrint('📹 Video call joined: $url');
          if (onConferenceJoined != null) {
            onConferenceJoined({'url': url});
          }
        },
      );

      await _jitsiMeet.join(options, listener);
    } catch (e) {
      debugPrint('⚠️ Error launching Jitsi video call: $e');
      rethrow;
    }
  }

  /// Tutup sesi panggilan aktif
  void hangUp() {
    try {
      _jitsiMeet.hangUp();
    } catch (e) {
      debugPrint('⚠️ Error hanging up Jitsi call: $e');
    }
  }
}
