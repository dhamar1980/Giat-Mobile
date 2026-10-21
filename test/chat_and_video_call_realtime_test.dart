import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/models/chat_message_model.dart';
import 'package:giat/models/call_signal_model.dart';
import 'package:giat/widgets/incoming_call_dialog.dart';
import 'package:giat/widgets/typing_indicator_widget.dart';
import 'package:giat/services/consultation_api_service.dart';
import 'package:giat/services/konsultasi_api_service.dart';

void main() {
  group('Chat Realtime & Video Call Models', () {
    test('ChatMessage model correctly parses from and converts to Map', () {
      final map = {
        'id': 'msg_001',
        'id_sender': 'user_42',
        'sender_name': 'Dr. Budi',
        'sender_role': 'dokter',
        'pesan': 'Halo, bagaimana kondisi Anda hari ini?',
        'tipe': 'text',
        'created_at': '2026-10-21T10:00:00Z',
      };

      final msg = ChatMessage.fromMap(map);
      expect(msg.id, 'msg_001');
      expect(msg.idSender, 'user_42');
      expect(msg.senderName, 'Dr. Budi');
      expect(msg.senderRole, 'dokter');
      expect(msg.pesan, 'Halo, bagaimana kondisi Anda hari ini?');
      expect(msg.tipe, 'text');
      expect(msg.createdAt, '2026-10-21T10:00:00Z');

      final toMap = msg.toMap();
      expect(toMap['id'], 'msg_001');
      expect(toMap['pesan'], 'Halo, bagaimana kondisi Anda hari ini?');
      expect(toMap['sender_role'], 'dokter');
    });

    test('CallSignalModel correctly parses from and converts to Map', () {
      final map = {
        'status': 'ringing',
        'caller_id': 'doc_007',
        'caller_name': 'Dr. Siti Rahma',
        'caller_role': 'dokter',
        'room_id': 'giat-room-101',
        'video_call_url': 'https://meet.jit.si/giat-room-101',
        'timestamp': 1761000000000,
      };

      final signal = CallSignalModel.fromMap(map);
      expect(signal.status, 'ringing');
      expect(signal.callerId, 'doc_007');
      expect(signal.callerName, 'Dr. Siti Rahma');
      expect(signal.callerRole, 'dokter');
      expect(signal.roomId, 'giat-room-101');
      expect(signal.videoCallUrl, 'https://meet.jit.si/giat-room-101');
      expect(signal.timestamp, 1761000000000);

      final toMap = signal.toMap();
      expect(toMap['status'], 'ringing');
      expect(toMap['room_id'], 'giat-room-101');
      expect(toMap['caller_name'], 'Dr. Siti Rahma');
    });
  });

  group('IncomingCallDialog Widget', () {
    testWidgets('renders caller info, pulse avatar, and action buttons', (tester) async {
      bool accepted = false;
      bool rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingCallDialog(
              callerName: 'Dr. Budi Santoso, Sp.PD',
              callerRole: 'Spesialis Ginjal & Hipertensi',
              onAccept: () {
                accepted = true;
              },
              onReject: () {
                rejected = true;
              },
            ),
          ),
        ),
      );

      // Verify UI elements
      expect(find.text('Panggilan Video Masuk'), findsOneWidget);
      expect(find.text('Dr. Budi Santoso, Sp.PD'), findsOneWidget);
      expect(find.text('Spesialis Ginjal & Hipertensi'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
      expect(find.text('Terima'), findsOneWidget);

      // Tap Tolak
      await tester.tap(find.text('Tolak'));
      await tester.pump();
      expect(rejected, isTrue);

      // Tap Terima
      await tester.tap(find.text('Terima'));
      await tester.pump();
      expect(accepted, isTrue);
    });
  });

  group('TypingIndicatorWidget', () {
    testWidgets('renders partner typing label and animated dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicatorWidget(
              partnerName: 'Dr. Budi Santoso',
            ),
          ),
        ),
      );

      expect(find.text('Dr. Budi Santoso sedang mengetik'), findsOneWidget);
    });
  });

  group('KonsultasiApiService & ConsultationApiService', () {
    test('Service classes expose all required chat and video call signaling methods', () {
      final service = KonsultasiApiService();
      expect(service.sendTypingStatus, isNotNull);
      expect(service.startVideoCall, isNotNull);
      expect(service.respondCallSignal, isNotNull);
      expect(service.endVideoCall, isNotNull);
      expect(service.sendMessage, isNotNull);

      final aliasService = ConsultationApiService();
      expect(aliasService.sendMessage, isNotNull);
      expect(aliasService.sendTypingStatus, isNotNull);
      expect(aliasService.startVideoCall, isNotNull);
      expect(aliasService.respondCallSignal, isNotNull);
      expect(aliasService.endVideoCall, isNotNull);
    });
  });
}
