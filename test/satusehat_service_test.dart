import 'package:flutter_test/flutter_test.dart';
import 'package:giat/constants/api_constants.dart';
import 'package:giat/models/user_model.dart';
import 'package:giat/services/satusehat_service.dart';

void main() {
  group('SatuSehat Configuration & Model Integration Tests', () {
    test('ApiConstants memiliki kredensial Sandbox SATUSEHAT yang valid', () {
      expect(
        ApiConstants.satusehatOrganizationId,
        equals('8130f30d-7d7e-48c0-abb3-ba551d939e29'),
      );
      expect(
        ApiConstants.satusehatClientId,
        equals('japGnEs9ff25iuos0QEPI1EqLyqs6z5c3nQ6CEQrYuAkHwIZ'),
      );
      expect(ApiConstants.satusehatClientSecret, isNotEmpty);
      expect(ApiConstants.satusehatEnvironment, equals('sandbox'));
      expect(ApiConstants.satusehatIsProduction, isFalse);
      expect(
        ApiConstants.satusehatFhirBaseUrl,
        equals('https://api-satusehat-stg.dto.kemkes.go.id/fhir-r4/v1'),
      );
    });

    test('UserModel mendukung serialisasi satusehat_ihs_number dan data demografi lengkap', () {
      final raw = {
        'id_pasien': 'pas-001',
        'nama': 'Budi Santoso',
        'email': 'budi@gmail.com',
        'no_hp': '081234567890',
        'alamat': 'Jl. Kalimantan No. 37, Sumbersari, Kabupaten Jember',
        'jenis_kelamin': 'L',
        'nik': '3509211505950001',
        'tanggal_lahir': '1995-05-15',
        'golongan_darah': 'O+',
        'satusehat_ihs_number': 'P20396484085',
      };

      final user = UserModel.fromJson(raw);
      expect(user.nama, equals('Budi Santoso'));
      expect(user.alamat, contains('Jember'));
      expect(user.nik, equals('3509211505950001'));
      expect(user.satusehatIhsNumber, equals('P20396484085'));

      final encoded = user.toJsonString();
      final restored = UserModel.fromJsonString(encoded);
      expect(restored.satusehatIhsNumber, equals('P20396484085'));
      expect(restored.nama, equals('Budi Santoso'));
      expect(restored.alamat, equals(user.alamat));
    });

    test('SatuSehatService aman diisolasi saat FLUTTER_TEST aktif secara default', () async {
      SatuSehatService.enableLiveInTest = false;
      final token = await SatuSehatService.instance.getAccessToken();
      expect(token, isNull);
    });
  });
}
