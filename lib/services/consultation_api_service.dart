import 'konsultasi_api_service.dart';

/// Alias class ConsultationApiService to match Clean Architecture spec in implementation plan
/// Delegates directly to the centralized KonsultasiApiService with Dio & ApiClient
class ConsultationApiService {
  final KonsultasiApiService _service = KonsultasiApiService();

  Future<bool> sendMessage(dynamic consultationId, String text, {String tipe = 'text'}) async {
    final res = await _service.sendMessage(consultationId, pesan: text, tipe: tipe);
    return res.success;
  }

  Future<void> sendTypingStatus(dynamic consultationId, bool isTyping) async {
    await _service.sendTypingStatus(consultationId, isTyping);
  }

  Future<Map<String, dynamic>?> startVideoCall(dynamic consultationId, {bool notifyChat = true}) async {
    final res = await _service.startVideoCall(consultationId, notifyChat: notifyChat);
    return res.data;
  }

  Future<void> respondCallSignal(dynamic consultationId, String signal) async {
    await _service.respondCallSignal(consultationId, signal);
  }

  Future<void> endVideoCall(dynamic consultationId, int durationMinutes) async {
    await _service.endVideoCall(consultationId, durasiMenit: durationMinutes);
  }
}
