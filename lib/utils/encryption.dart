import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionUtil {
  static const String _keyStorageKey = 'diary_encryption_key';
  static const String _ivStorageKey = 'diary_encryption_iv';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // AES-256 암호화 키 생성 또는 가져오기
  static Future<encrypt_pkg.Key> _getOrCreateKey() async {
    String? storedKey = await _secureStorage.read(key: _keyStorageKey);
    
    if (storedKey != null) {
      return encrypt_pkg.Key.fromBase64(storedKey);
    }
    
    // 새로운 256비트 키 생성
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
    
    // 안전하게 저장
    await _secureStorage.write(
      key: _keyStorageKey,
      value: key.base64,
    );
    
    return key;
  }

  // IV (Initialization Vector) 생성
  static Future<encrypt_pkg.IV> _generateIV() async {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return encrypt_pkg.IV(Uint8List.fromList(ivBytes));
  }

  // 텍스트 암호화
  static Future<String> encryptText(String plainText) async {
    try {
      final key = await _getOrCreateKey();
      final iv = await _generateIV();
      
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'),
      );
      
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // IV와 암호문을 함께 저장 (IV:암호문 형식)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('암호화 실패: $e');
    }
  }

  // 텍스트 복호화
  static Future<String> decryptText(String encryptedText) async {
    try {
      final key = await _getOrCreateKey();
      
      // IV와 암호문 분리
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('잘못된 암호문 형식');
      }
      
      final iv = encrypt_pkg.IV.fromBase64(parts[0]);
      final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);
      
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'),
      );
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('복호화 실패: $e');
    }
  }

  // 데이터 무결성 검증을 위한 해시 생성
  static String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 암호화 키 삭제 (로그아웃 시)
  static Future<void> deleteEncryptionKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
  }

  // 키 존재 여부 확인
  static Future<bool> hasEncryptionKey() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    return key != null;
  }
}
