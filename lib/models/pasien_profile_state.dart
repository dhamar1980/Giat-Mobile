import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/pasien_api_service.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE PROFIL PASIEN (Reaktif untuk Foto Profil & Informasi Pasien GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class PasienProfileState extends ChangeNotifier {
  static final PasienProfileState instance = PasienProfileState._internal();
  factory PasienProfileState() => instance;
  PasienProfileState._internal();

  String _nama = '';
  String _avatarPath = '';
  String _avatarType = 'default'; // 'default', 'network', 'file', 'asset'

  String get nama => _nama;
  String get avatarPath => _avatarPath;
  String get avatarType => _avatarType;

  void updateAvatar(String pathOrUrl, {String? type}) {
    final trimmed = pathOrUrl.trim();
    if (trimmed.isEmpty) {
      _avatarPath = '';
      _avatarType = 'default';
    } else {
      final resolved = ApiConfig.resolveImageUrl(trimmed);
      _avatarPath = resolved;
      if (type != null) {
        _avatarType = type;
      } else if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
        _avatarType = 'network';
      } else if (resolved.startsWith('assets/')) {
        _avatarType = 'asset';
      } else {
        _avatarType = 'file';
      }
    }
    notifyListeners();
  }

  void syncFromUser({String? name, String? avatar}) {
    bool changed = false;
    if (name != null && name.trim().isNotEmpty && _nama != name.trim()) {
      _nama = name.trim();
      changed = true;
    }
    if (avatar != null && avatar.trim().isNotEmpty) {
      final resolved = ApiConfig.resolveImageUrl(avatar.trim());
      if (_avatarPath != resolved) {
        _avatarPath = resolved;
        if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
          _avatarType = 'network';
        } else if (resolved.startsWith('assets/')) {
          _avatarType = 'asset';
        } else {
          _avatarType = 'file';
        }
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> loadProfile({String? fallbackName}) async {
    try {
      final user = await StorageService().getUser();
      if (user != null) {
        syncFromUser(
          name: user.nama,
          avatar: user.fotoProfile,
        );
      } else if (fallbackName != null && fallbackName.isNotEmpty) {
        syncFromUser(name: fallbackName);
      }
    } catch (_) {}

    try {
      final res = await PasienApiService().getProfile();
      if (res.success && res.data != null) {
        final d = res.data!;
        final fetchedName = d['nama'] ?? d['name'] ?? fallbackName;
        final fetchedFoto = d['foto_profile'] ?? d['foto_profil'] ?? d['foto'];
        syncFromUser(
          name: fetchedName?.toString(),
          avatar: fetchedFoto?.toString(),
        );
      }
    } catch (_) {}
  }
}
