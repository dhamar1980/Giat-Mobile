import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/call_signal_model.dart';

/// Layanan Firebase Realtime Database untuk Sinkronisasi Chat & Video Call Signaling (<100ms)
/// Mendukung Dual-Layer: Native Firebase SDK + Direct RTDB REST API (sesuai backend Giat-Web)
class FirebaseRealtimeService {
  static final FirebaseRealtimeService _instance = FirebaseRealtimeService._internal();
  factory FirebaseRealtimeService() => _instance;
  FirebaseRealtimeService._internal();

  static const String rtdbUrl =
      'https://giat-3ac67-default-rtdb.asia-southeast1.firebasedatabase.app';

  bool get _isTestEnv => Platform.environment.containsKey('FLUTTER_TEST');

  late final Dio _rtdbDio = Dio(
    BaseOptions(
      baseUrl: rtdbUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  FirebaseDatabase? _database;

  bool get _isNativeSupported {
    if (_isTestEnv) return false;
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  FirebaseDatabase? get _db {
    if (!_isNativeSupported) return null;
    if (_database != null) return _database;
    try {
      if (Firebase.apps.isNotEmpty) {
        _database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: rtdbUrl,
        );
        debugPrint('🔥 FirebaseRealtimeService connected to: $rtdbUrl');
      } else {
        _database = FirebaseDatabase.instance;
      }
    } catch (e) {
      debugPrint('⚠️ FirebaseDatabase instance error: $e');
      _database = null;
    }
    return _database;
  }

  // =========================================================================
  // 1. DIRECT RTDB REST METHODS (Kompatibel 100% dengan FirebaseService.php di backend)
  // =========================================================================

  Future<bool> writeRest(String path, dynamic data, {String method = 'PUT'}) async {
    if (_isTestEnv) return true;
    try {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final url = '/$cleanPath.json';
      Response res;
      if (method.toUpperCase() == 'POST') {
        res = await _rtdbDio.post(url, data: data);
      } else if (method.toUpperCase() == 'PATCH') {
        res = await _rtdbDio.patch(url, data: data);
      } else if (method.toUpperCase() == 'DELETE') {
        res = await _rtdbDio.delete(url);
      } else {
        res = await _rtdbDio.put(url, data: data);
      }
      return (res.statusCode ?? 400) >= 200 && (res.statusCode ?? 400) < 300;
    } catch (e) {
      debugPrint('⚠️ Firebase RTDB REST write error ($path): $e');
      return false;
    }
  }

  Future<dynamic> getRest(String path) async {
    if (_isTestEnv) return null;
    try {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final url = '/$cleanPath.json';
      final res = await _rtdbDio.get(url);
      return res.data;
    } catch (e) {
      debugPrint('⚠️ Firebase RTDB REST read error ($path): $e');
      return null;
    }
  }

  /// Ambil riwayat seluruh pesan langsung dari node konsultasi/{id}/messages di Firebase
  Future<List<ChatMessage>> fetchMessagesDirectly(dynamic consultationId) async {
    if (_isTestEnv) return [];
    final cId = consultationId.toString();
    final List<ChatMessage> list = [];
    try {
      final data = await getRest('konsultasi/$cId/messages');
      if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            final map = Map<String, dynamic>.from(val);
            if (!map.containsKey('id') || map['id'] == null || map['id'].toString().isEmpty) {
              map['id'] = key.toString();
            }
            list.add(ChatMessage.fromMap(map));
          }
        });
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    } catch (e) {
      debugPrint('⚠️ fetchMessagesDirectly error: $e');
    }
    return list;
  }

  // =========================================================================
  // 2. REALTIME LISTENERS (Native WebSocket + REST Polling Fallback)
  // =========================================================================

  /// 1. Mendengarkan pesan baru secara realtime (< 100ms)
  Stream<ChatMessage> listenMessages(dynamic consultationId) {
    final cId = consultationId.toString();
    final controller = StreamController<ChatMessage>.broadcast();
    final Set<String> emittedIds = {};

    StreamSubscription? nativeSub;
    Timer? pollTimer;

    // A. Native onChildAdded listener
    final db = _db;
    if (db != null) {
      try {
        final ref = db.ref('konsultasi/$cId/messages');
        nativeSub = ref.onChildAdded.listen((event) {
          final raw = event.snapshot.value;
          if (raw is Map) {
            final map = Map<dynamic, dynamic>.from(raw);
            final id = (map['id'] ?? event.snapshot.key ?? '').toString();
            map['id'] = id;
            if (id.isNotEmpty && !emittedIds.contains(id)) {
              emittedIds.add(id);
              controller.add(ChatMessage.fromMap(map));
            }
          }
        }, onError: (err) {
          debugPrint('⚠️ Native onChildAdded error: $err');
        });
      } catch (e) {
        debugPrint('⚠️ Setup native listenMessages error: $e');
      }
    }

    // B. REST sync interval (setiap 2 detik agar liveness terjamin di seluruh platform)
    if (!_isTestEnv) {
      pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (controller.isClosed) return;
        try {
          final data = await getRest('konsultasi/$cId/messages');
          if (data is Map) {
            data.forEach((key, val) {
              if (val is Map) {
                final map = Map<String, dynamic>.from(val);
                final id = (map['id'] ?? key ?? '').toString();
                map['id'] = id;
                if (id.isNotEmpty && !emittedIds.contains(id)) {
                  emittedIds.add(id);
                  controller.add(ChatMessage.fromMap(map));
                }
              }
            });
          }
        } catch (_) {}
      });
    }

    controller.onCancel = () {
      nativeSub?.cancel();
      pollTimer?.cancel();
    };

    return controller.stream;
  }

  /// 2. Mendengarkan status lawan bicara sedang mengetik
  Stream<bool> listenTyping(dynamic consultationId, String partnerRole) {
    final cId = consultationId.toString();
    final role = partnerRole.toLowerCase();
    final controller = StreamController<bool>.broadcast();
    bool lastVal = false;

    StreamSubscription? nativeSub;
    Timer? pollTimer;

    final db = _db;
    if (db != null) {
      try {
        final ref = db.ref('konsultasi/$cId/typing/$role');
        nativeSub = ref.onValue.listen((event) {
          final val = event.snapshot.value;
          bool current = false;
          if (val is bool) current = val;
          if (val is num) current = val == 1;
          if (val is String) current = val.toLowerCase() == 'true';
          if (current != lastVal) {
            lastVal = current;
            controller.add(current);
          }
        }, onError: (_) {});
      } catch (_) {}
    }

    if (!_isTestEnv) {
      pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (controller.isClosed) return;
        try {
          final val = await getRest('konsultasi/$cId/typing/$role');
          bool current = false;
          if (val is bool) current = val;
          if (val is num) current = val == 1;
          if (val is String) current = val.toLowerCase() == 'true';
          if (current != lastVal) {
            lastVal = current;
            controller.add(current);
          }
        } catch (_) {}
      });
    }

    controller.onCancel = () {
      nativeSub?.cancel();
      pollTimer?.cancel();
    };

    return controller.stream;
  }

  /// 3. Mendengarkan sinyal panggilan video masuk
  Stream<CallSignalModel?> listenCallSignaling(dynamic consultationId) {
    final cId = consultationId.toString();
    final controller = StreamController<CallSignalModel?>.broadcast();
    String lastStatus = '';

    StreamSubscription? nativeSub;
    Timer? pollTimer;

    final db = _db;
    if (db != null) {
      try {
        final ref = db.ref('konsultasi/$cId/call_signaling');
        nativeSub = ref.onValue.listen((event) {
          final val = event.snapshot.value;
          if (val is Map) {
            final model = CallSignalModel.fromMap(Map<dynamic, dynamic>.from(val));
            if (model.status != lastStatus) {
              lastStatus = model.status;
              controller.add(model);
            }
          }
        }, onError: (_) {});
      } catch (_) {}
    }

    if (!_isTestEnv) {
      pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (controller.isClosed) return;
        try {
          final val = await getRest('konsultasi/$cId/call_signaling');
          if (val is Map) {
            final model = CallSignalModel.fromMap(Map<dynamic, dynamic>.from(val));
            if (model.status != lastStatus) {
              lastStatus = model.status;
              controller.add(model);
            }
          }
        } catch (_) {}
      });
    }

    controller.onCancel = () {
      nativeSub?.cancel();
      pollTimer?.cancel();
    };

    return controller.stream;
  }

  // =========================================================================
  // 3. MUTATION METHODS (Dual Push: REST PUT + Native SDK)
  // =========================================================================

  /// Update status mengetik langsung ke Firebase RTDB
  Future<void> updateTypingStatus(dynamic consultationId, String myRole, bool isTyping) async {
    final cId = consultationId.toString();
    final role = myRole.toLowerCase();
    await writeRest('konsultasi/$cId/typing/$role', isTyping, method: 'PUT');
    try {
      final db = _db;
      if (db != null) {
        await db.ref('konsultasi/$cId/typing/$role').set(isTyping);
      }
    } catch (e) {
      debugPrint('⚠️ updateTypingStatus native notice: $e');
    }
  }

  /// Update sinyal panggilan video langsung ke Firebase RTDB
  Future<void> updateCallSignal(dynamic consultationId, CallSignalModel signal) async {
    final cId = consultationId.toString();
    await writeRest('konsultasi/$cId/call_signaling', signal.toMap(), method: 'PUT');
    try {
      final db = _db;
      if (db != null) {
        await db.ref('konsultasi/$cId/call_signaling').set(signal.toMap());
      }
    } catch (e) {
      debugPrint('⚠️ updateCallSignal native notice: $e');
    }
  }

  /// Akhiri atau reset sinyal panggilan di Firebase RTDB
  Future<void> clearCallSignal(dynamic consultationId) async {
    final cId = consultationId.toString();
    final payload = {
      'status': 'ended',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await writeRest('konsultasi/$cId/call_signaling', payload, method: 'PATCH');
    try {
      final db = _db;
      if (db != null) {
        await db.ref('konsultasi/$cId/call_signaling').update(payload);
      }
    } catch (e) {
      debugPrint('⚠️ clearCallSignal native notice: $e');
    }
  }

  /// Push pesan chat langsung ke Firebase RTDB (Sesuai skema FirebaseService.php di backend)
  Future<String?> pushMessage(dynamic consultationId, ChatMessage message) async {
    final cId = consultationId.toString();
    final messageId = message.id.isNotEmpty
        ? message.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final payload = {
      'id': messageId,
      'id_sender': message.idSender,
      'sender_name': message.senderName,
      'sender_role': message.senderRole,
      'pesan': message.pesan,
      'tipe': message.tipe,
      'attachment_url': message.attachmentUrl,
      'created_at': message.createdAt.isNotEmpty
          ? message.createdAt
          : DateTime.now().toIso8601String(),
    };

    // 1. Tulis via Firebase REST API
    final ok = await writeRest('konsultasi/$cId/messages/$messageId', payload, method: 'PUT');
    if (ok) {
      debugPrint('🔥 Pesan berhasil dipush ke Firebase RTDB via REST: $messageId');
    }

    // 2. Update session_info
    await writeRest('konsultasi/$cId/session_info', {
      'status_konsultasi': 'berlangsung',
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, method: 'PATCH');

    // 3. Tulis via Native SDK jika tersedia
    try {
      final db = _db;
      if (db != null) {
        await db.ref('konsultasi/$cId/messages/$messageId').set(payload);
      }
    } catch (e) {
      debugPrint('⚠️ pushMessage native notice: $e');
    }

    return messageId;
  }
}

