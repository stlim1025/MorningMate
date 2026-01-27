import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionUtil {
  static const String _keyStorageKey = 'diary_encryption_key';
  static const String _ivStorageKey = 'diary_encryption_iv';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // AES-256 암호화 키 생성 또는 가져오기 (사용자 기반)
  static Future<encrypt_pkg.Key> _getOrCreateKey(String userId) async {
    if (userId.isEmpty) {
      throw Exception('사용자 ID가 비어있습니다.');
    }

    try {
      // 사용자별 키 저장 키
      final userKeyStorageKey = '${_keyStorageKey}_$userId';
      String? storedKey = await _secureStorage.read(key: userKeyStorageKey);

      if (storedKey != null) {
        return encrypt_pkg.Key.fromBase64(storedKey);
      }

      // 사용자 UID를 기반으로 결정론적 키 생성
      final userIdBytes = utf8.encode(userId);
      final hash = sha256.convert(userIdBytes);
      final keyBytes = Uint8List.fromList(hash.bytes);
      final key = encrypt_pkg.Key(keyBytes);

      // 안전하게 저장 시도
      try {
        await _secureStorage.write(
          key: userKeyStorageKey,
          value: key.base64,
        );
      } catch (e) {
        print('보안 저장소 쓰기 실패 (무시됨): $e');
      }

      return key;
    } catch (e) {
      throw Exception('키 생성 실패: $e');
    }
  }

  // IV (Initialization Vector) 생성
  static Future<encrypt_pkg.IV> _generateIV() async {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return encrypt_pkg.IV(Uint8List.fromList(ivBytes));
  }

  // 텍스트 암호화
  static Future<String> encryptText(String plainText, String userId) async {
    try {
      final key = await _getOrCreateKey(userId);
      final iv = await _generateIV();

      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // IV와 암호문을 함께 저장 (IV:암호문 형식)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('암호화 오류: $e');
      throw Exception('암호화 실패: $e');
    }
  }

  // 텍스트 복호화
  static Future<String> decryptText(String encryptedText, String userId) async {
    try {
      if (encryptedText.isEmpty) throw Exception('암호화된 텍스트가 비어있습니다.');

      final key = await _getOrCreateKey(userId);

      // IV와 암호문 분리
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('잘못된 암호문 형식입니다. (부분 수: ${parts.length})');
      }

      final iv = encrypt_pkg.IV.fromBase64(parts[0]);
      final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'),
      );

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('복호화 오류 상세: $e');
      // 사용자가 볼 수 있는 더 구체적인 에러 메시지
      throw Exception(
          '일기 복호화에 실패했습니다. (원인: ${e.toString().split(':').last.trim()})');
    }
  }

  // 데이터 무결성 검증을 위한 해시 생성
  static String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 암호화 키 삭제 (로그아웃 시)
  static Future<void> deleteEncryptionKey(String userId) async {
    final userKeyStorageKey = '${_keyStorageKey}_$userId';
    await _secureStorage.delete(key: userKeyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
  }

  // 키 존재 여부 확인
  static Future<bool> hasEncryptionKey(String userId) async {
    final userKeyStorageKey = '${_keyStorageKey}_$userId';
    final key = await _secureStorage.read(key: userKeyStorageKey);
    return key != null;
  }
}
